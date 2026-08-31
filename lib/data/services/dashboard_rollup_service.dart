import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/di/injection.dart';
import '../../core/observability/tracked_firestore.dart';
import '../../core/utils/dashboard_job_work_metrics.dart';
import '../../core/utils/dashboard_query_window.dart';
import '../../core/utils/dashboard_sales_sqft_metrics.dart';
import '../../core/utils/firestore_query_constraints.dart';
import '../../domain/entities/dashboard_cashflow_metrics.dart';
import '../../domain/entities/dashboard_monthly_rollup.dart';
import '../../domain/entities/dashboard_sales_sqft_metrics.dart';
import '../../domain/entities/dashboard_stock_cut_metrics.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/dashboard_finance_period.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/sales_enums.dart';
import '../models/dashboard_monthly_rollup_model.dart';
import '../models/expense_model.dart';
import '../models/job_work_load_model.dart';
import '../models/job_work_order_model.dart';
import '../models/payment_model.dart';
import '../models/sales_order_model.dart';
import '../repositories/dashboard_rollup_repository.dart';

class DashboardRollupBackfillReport {
  const DashboardRollupBackfillReport({
    this.monthsWritten = 0,
    this.skipped = false,
    this.error,
  });

  final int monthsWritten;
  final bool skipped;
  final String? error;

  bool get isComplete => error == null;
}

class DashboardRollupDriftReport {
  const DashboardRollupDriftReport({
    required this.yearMonth,
    required this.rollup,
    required this.recomputed,
  });

  final String yearMonth;
  final DashboardMonthlyRollup rollup;
  final DashboardMonthlyRollup recomputed;

  bool get hasDrift =>
      !_same(rollup.income, recomputed.income) ||
      !_same(rollup.expenses, recomputed.expenses) ||
      !_same(rollup.stockCutSmallSqFt, recomputed.stockCutSmallSqFt) ||
      !_same(rollup.stockCutLargeSqFt, recomputed.stockCutLargeSqFt) ||
      !_same(rollup.salesSmallSqFt, recomputed.salesSmallSqFt) ||
      !_same(rollup.salesLargeSqFt, recomputed.salesLargeSqFt);

  static bool _same(double a, double b) => (a - b).abs() < 0.05;

  @override
  String toString() => hasDrift
      ? 'DRIFT $yearMonth income ${rollup.income} vs ${recomputed.income}, '
          'expenses ${rollup.expenses} vs ${recomputed.expenses}'
      : 'OK $yearMonth';
}

/// Fire-and-forget rollup write so a metrics failure cannot block a payment.
Future<void> applyDashboardRollup(
  Future<void> Function(DashboardRollupService service) action,
) async {
  try {
    if (!getIt.isRegistered<DashboardRollupService>()) return;
    await action(getIt<DashboardRollupService>());
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Dashboard rollup skipped: $error\n$stackTrace');
    }
  }
}

class DashboardRollupService {
  DashboardRollupService({
    FirebaseFirestore? firestore,
    DashboardRollupRepository? repository,
    SharedPreferences? preferences,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _repository = repository ??
            DashboardRollupRepository(firestore: firestore),
        _preferences = preferences;

  static const _prefKeyPrefix = 'dashboard_rollups_backfill_v1_';

  final FirebaseFirestore _firestore;
  final DashboardRollupRepository _repository;
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<List<DashboardMonthlyRollup>> getRange({
    required String factoryId,
    required DateTime from,
    required DateTime to,
  }) {
    return _repository.getRange(factoryId: factoryId, from: from, to: to);
  }

  Future<void> applyPayment({
    required Payment payment,
    Payment? previous,
    bool deleted = false,
  }) async {
    if (previous != null) {
      await _applyPaymentSide(previous, sign: -1);
    }
    if (!deleted) {
      await _applyPaymentSide(payment, sign: 1);
    } else if (previous == null) {
      await _applyPaymentSide(payment, sign: -1);
    }
  }

  Future<void> applyExpense({
    required Expense expense,
    Expense? previous,
    bool deleted = false,
  }) async {
    if (previous != null) {
      await _repository.increment(
        factoryId: previous.factoryId,
        date: previous.expenseDate,
        delta: DashboardRollupDelta(expenses: -previous.amount),
      );
    }
    if (!deleted) {
      await _repository.increment(
        factoryId: expense.factoryId,
        date: expense.expenseDate,
        delta: DashboardRollupDelta(expenses: expense.amount),
      );
    } else if (previous == null) {
      await _repository.increment(
        factoryId: expense.factoryId,
        date: expense.expenseDate,
        delta: DashboardRollupDelta(expenses: -expense.amount),
      );
    }
  }

  Future<void> applyStockCutForLoad({
    required JobWorkLoad current,
    JobWorkLoad? previous,
  }) async {
    if (previous != null) {
      await _applyStockCutSides(previous, sign: -1);
    }
    await _applyStockCutSides(current, sign: 1);
  }

  Future<void> applySalesOrder({
    required SalesOrder order,
    SalesOrder? previous,
    bool deleted = false,
  }) async {
    if (previous != null) {
      await _applySalesSide(previous, sign: -1);
    }
    if (!deleted) {
      await _applySalesSide(order, sign: 1);
    } else if (previous == null) {
      await _applySalesSide(order, sign: -1);
    }
  }

  Future<DashboardRollupBackfillReport> runIfNeeded(String factoryId) async {
    final prefs = await _prefs;
    final key = '$_prefKeyPrefix$factoryId';
    if (prefs.getBool(key) == true) {
      return const DashboardRollupBackfillReport(skipped: true);
    }
    final report = await backfill(factoryId);
    if (report.isComplete) {
      await prefs.setBool(key, true);
    }
    return report;
  }

  Future<DashboardRollupBackfillReport> backfill(
    String factoryId, {
    DateTime? now,
  }) async {
    try {
      final reference = now ?? DateTime.now();
      final from = DateTime(
        reference.year,
        reference.month - DashboardQueryWindow.allTimeCapMonths,
        1,
      );
      final buckets = await _computeMonths(
        factoryId: factoryId,
        from: from,
        to: reference,
      );
      for (final rollup in buckets.values) {
        await _repository.replaceMonth(rollup);
      }
      return DashboardRollupBackfillReport(monthsWritten: buckets.length);
    } catch (error) {
      return DashboardRollupBackfillReport(error: error.toString());
    }
  }

  Future<DashboardRollupDriftReport> detectDrift({
    required String factoryId,
    required DateTime month,
  }) async {
    final start = DashboardRollupIds.monthStart(month);
    final existing = await _repository.getRange(
      factoryId: factoryId,
      from: start,
      to: start,
    );
    final recomputed = await _computeMonths(
      factoryId: factoryId,
      from: start,
      to: start,
    );
    final key = DashboardRollupIds.docId(factoryId, start);
    return DashboardRollupDriftReport(
      yearMonth: DashboardRollupIds.yearMonth(start),
      rollup: existing.isEmpty
          ? DashboardMonthlyRollup(
              id: key,
              factoryId: factoryId,
              yearMonth: DashboardRollupIds.yearMonth(start),
              year: start.year,
              month: start.month,
            )
          : existing.first,
      recomputed: recomputed[key] ??
          DashboardMonthlyRollup(
            id: key,
            factoryId: factoryId,
            yearMonth: DashboardRollupIds.yearMonth(start),
            year: start.year,
            month: start.month,
          ),
    );
  }

  static DashboardCashflowMetrics cashflow({
    required DashboardFinancePeriod period,
    required DateTime now,
    required List<DashboardMonthlyRollup> rollups,
    DateTime? earliestDate,
  }) {
    final range = DashboardFinancePeriodRange.forPeriod(
      period,
      now,
      earliestDate: earliestDate,
    );
    return DashboardCashflowMetrics(
      period: period,
      income: sumIncome(rollups, range.currentStart, range.currentEnd),
      expenses: sumExpenses(rollups, range.currentStart, range.currentEnd),
      previousIncome: sumIncome(
        rollups,
        range.previousStart,
        range.previousEnd,
      ),
      previousExpenses: sumExpenses(
        rollups,
        range.previousStart,
        range.previousEnd,
      ),
    );
  }

  static DashboardStockCutMetrics stockCut({
    required DashboardFinancePeriod period,
    required DateTime now,
    required List<DashboardMonthlyRollup> rollups,
    DateTime? earliestDate,
  }) {
    final range = DashboardFinancePeriodRange.forPeriod(
      period,
      now,
      earliestDate: earliestDate,
    );
    final current = _stock(rollups, range.currentStart, range.currentEnd);
    final previous = _stock(rollups, range.previousStart, range.previousEnd);
    return DashboardStockCutMetrics(
      period: period,
      smallSqFt: current.smallSqFt,
      largeSqFt: current.largeSqFt,
      previousSmallSqFt: previous.smallSqFt,
      previousLargeSqFt: previous.largeSqFt,
      smallAmount: current.smallAmount,
      largeAmount: current.largeAmount,
      previousSmallAmount: previous.smallAmount,
      previousLargeAmount: previous.largeAmount,
    );
  }

  static DashboardSalesSqFtMetrics salesSqFt({
    required DashboardFinancePeriod period,
    required DateTime now,
    required List<DashboardMonthlyRollup> rollups,
    DateTime? earliestDate,
  }) {
    final range = DashboardFinancePeriodRange.forPeriod(
      period,
      now,
      earliestDate: earliestDate,
    );
    final current = _sales(rollups, range.currentStart, range.currentEnd);
    final previous = _sales(rollups, range.previousStart, range.previousEnd);
    return DashboardSalesSqFtMetrics(
      period: period,
      smallSqFt: current.smallSqFt,
      largeSqFt: current.largeSqFt,
      previousSmallSqFt: previous.smallSqFt,
      previousLargeSqFt: previous.largeSqFt,
      smallAmount: current.smallAmount,
      largeAmount: current.largeAmount,
      previousSmallAmount: previous.smallAmount,
      previousLargeAmount: previous.largeAmount,
    );
  }

  static double sumIncome(
    List<DashboardMonthlyRollup> rollups,
    DateTime start,
    DateTime end,
  ) =>
      _fold(rollups, start, end, (rollup) => rollup.income);

  static double sumIncomeSales(
    List<DashboardMonthlyRollup> rollups,
    DateTime start,
    DateTime end,
  ) =>
      _fold(rollups, start, end, (rollup) => rollup.incomeSales);

  static double sumIncomeJobWork(
    List<DashboardMonthlyRollup> rollups,
    DateTime start,
    DateTime end,
  ) =>
      _fold(rollups, start, end, (rollup) => rollup.incomeJobWork);

  static double sumExpenses(
    List<DashboardMonthlyRollup> rollups,
    DateTime start,
    DateTime end,
  ) =>
      _fold(rollups, start, end, (rollup) => rollup.expenses);

  static double _fold(
    List<DashboardMonthlyRollup> rollups,
    DateTime start,
    DateTime end,
    double Function(DashboardMonthlyRollup rollup) field,
  ) {
    var total = 0.0;
    for (final rollup in rollups) {
      if (rollup.overlaps(start, end)) total += field(rollup);
    }
    return total;
  }

  static DashboardStockCutTotals _stock(
    List<DashboardMonthlyRollup> rollups,
    DateTime start,
    DateTime end,
  ) {
    var small = 0.0;
    var large = 0.0;
    var smallAmt = 0.0;
    var largeAmt = 0.0;
    for (final rollup in rollups) {
      if (!rollup.overlaps(start, end)) continue;
      small += rollup.stockCutSmallSqFt;
      large += rollup.stockCutLargeSqFt;
      smallAmt += rollup.stockCutSmallAmount;
      largeAmt += rollup.stockCutLargeAmount;
    }
    return DashboardStockCutTotals(
      smallSqFt: small,
      largeSqFt: large,
      smallAmount: smallAmt,
      largeAmount: largeAmt,
    );
  }

  static ({
    double smallSqFt,
    double largeSqFt,
    double smallAmount,
    double largeAmount,
  }) _sales(
    List<DashboardMonthlyRollup> rollups,
    DateTime start,
    DateTime end,
  ) {
    var small = 0.0;
    var large = 0.0;
    var smallAmt = 0.0;
    var largeAmt = 0.0;
    for (final rollup in rollups) {
      if (!rollup.overlaps(start, end)) continue;
      small += rollup.salesSmallSqFt;
      large += rollup.salesLargeSqFt;
      smallAmt += rollup.salesSmallAmount;
      largeAmt += rollup.salesLargeAmount;
    }
    return (
      smallSqFt: small,
      largeSqFt: large,
      smallAmount: smallAmt,
      largeAmount: largeAmt,
    );
  }

  Future<void> _applyPaymentSide(Payment payment, {required int sign}) async {
    if (!_countsTowardIncome(payment)) return;
    final amount = payment.amount * sign;
    await _repository.increment(
      factoryId: payment.factoryId,
      date: payment.paymentDate,
      delta: DashboardRollupDelta(
        income: amount,
        incomeSales:
            payment.invoiceType == InvoiceType.sales ? amount : 0,
        incomeJobWork:
            payment.invoiceType == InvoiceType.jobWork ? amount : 0,
      ),
    );
  }

  Future<void> _applySalesSide(SalesOrder order, {required int sign}) async {
    if (order.status == SalesOrderStatus.cancelled) return;
    final month = DashboardRollupIds.monthStart(order.orderDate);
    final cut = DashboardSalesSqFtHelper.factorySalesSqFtInRange(
      orders: [order],
      start: month,
      end: DateTime(month.year, month.month + 1, 0),
    );
    await _repository.increment(
      factoryId: order.factoryId,
      date: order.orderDate,
      delta: DashboardRollupDelta(
        salesSmallSqFt: cut.smallSqFt * sign,
        salesLargeSqFt: cut.largeSqFt * sign,
        salesSmallAmount: cut.smallAmount * sign,
        salesLargeAmount: cut.largeAmount * sign,
      ),
    );
  }

  Future<void> _applyStockCutSides(
    JobWorkLoad load, {
    required int sign,
  }) async {
    final months = <DateTime>{};
    for (final shift in load.shiftLogs) {
      months.add(DashboardRollupIds.monthStart(shift.shiftDate));
    }
    final recordedAt = load.output?.recordedAt;
    if (recordedAt != null) {
      months.add(DashboardRollupIds.monthStart(recordedAt));
    }
    if (months.isEmpty && load.output != null) {
      months.add(DashboardRollupIds.monthStart(load.receivedDate));
    }
    for (final month in months) {
      final cut = DashboardJobWorkMetrics.stockCutInRangeForLoad(
        load,
        start: month,
        end: DateTime(month.year, month.month + 1, 0),
      );
      if (cut.totalSqFt == 0 && cut.totalAmount == 0) continue;
      await _repository.increment(
        factoryId: load.factoryId,
        date: month,
        delta: DashboardRollupDelta(
          stockCutSmallSqFt: cut.smallSqFt * sign,
          stockCutLargeSqFt: cut.largeSqFt * sign,
          stockCutSmallAmount: cut.smallAmount * sign,
          stockCutLargeAmount: cut.largeAmount * sign,
        ),
      );
    }
  }

  Future<Map<String, DashboardMonthlyRollup>> _computeMonths({
    required String factoryId,
    required DateTime from,
    required DateTime to,
  }) async {
    final payments = await _readPayments(factoryId, from);
    final expenses = await _readExpenses(factoryId, from);
    final loads = await _readLoads(factoryId);
    final orders = await _readJobWorkOrders(factoryId);
    final salesOrders = await _readSalesOrders(factoryId);

    final buckets = <String, DashboardMonthlyRollup>{};
    DashboardMonthlyRollup bucket(DateTime date) {
      final start = DashboardRollupIds.monthStart(date);
      final id = DashboardRollupIds.docId(factoryId, start);
      return buckets.putIfAbsent(
        id,
        () => DashboardMonthlyRollup(
          id: id,
          factoryId: factoryId,
          yearMonth: DashboardRollupIds.yearMonth(start),
          year: start.year,
          month: start.month,
        ),
      );
    }

    void put(DateTime date, DashboardMonthlyRollup Function(DashboardMonthlyRollup current) update) {
      if (date.isBefore(from) || date.isAfter(DateTime(to.year, to.month + 1, 0))) {
        return;
      }
      final current = bucket(date);
      buckets[current.id] = update(current);
    }

    for (final payment in payments) {
      if (!_countsTowardIncome(payment)) continue;
      put(
        payment.paymentDate,
        (current) => DashboardMonthlyRollup(
          id: current.id,
          factoryId: current.factoryId,
          yearMonth: current.yearMonth,
          year: current.year,
          month: current.month,
          income: current.income + payment.amount,
          incomeSales: current.incomeSales +
              (payment.invoiceType == InvoiceType.sales ? payment.amount : 0),
          incomeJobWork: current.incomeJobWork +
              (payment.invoiceType == InvoiceType.jobWork ? payment.amount : 0),
          expenses: current.expenses,
          stockCutSmallSqFt: current.stockCutSmallSqFt,
          stockCutLargeSqFt: current.stockCutLargeSqFt,
          stockCutSmallAmount: current.stockCutSmallAmount,
          stockCutLargeAmount: current.stockCutLargeAmount,
          salesSmallSqFt: current.salesSmallSqFt,
          salesLargeSqFt: current.salesLargeSqFt,
          salesSmallAmount: current.salesSmallAmount,
          salesLargeAmount: current.salesLargeAmount,
        ),
      );
    }

    for (final expense in expenses) {
      put(
        expense.expenseDate,
        (current) => DashboardMonthlyRollup(
          id: current.id,
          factoryId: current.factoryId,
          yearMonth: current.yearMonth,
          year: current.year,
          month: current.month,
          income: current.income,
          incomeSales: current.incomeSales,
          incomeJobWork: current.incomeJobWork,
          expenses: current.expenses + expense.amount,
          stockCutSmallSqFt: current.stockCutSmallSqFt,
          stockCutLargeSqFt: current.stockCutLargeSqFt,
          stockCutSmallAmount: current.stockCutSmallAmount,
          stockCutLargeAmount: current.stockCutLargeAmount,
          salesSmallSqFt: current.salesSmallSqFt,
          salesLargeSqFt: current.salesLargeSqFt,
          salesSmallAmount: current.salesSmallAmount,
          salesLargeAmount: current.salesLargeAmount,
        ),
      );
    }

    var cursor = DashboardRollupIds.monthStart(from);
    final last = DashboardRollupIds.monthStart(to);
    while (!cursor.isAfter(last)) {
      final monthEnd = DateTime(cursor.year, cursor.month + 1, 0);
      final cut = DashboardJobWorkMetrics.factoryStockCutInRange(
        orders: orders,
        loads: loads,
        start: cursor,
        end: monthEnd,
      );
      final sold = DashboardSalesSqFtHelper.factorySalesSqFtInRange(
        orders: salesOrders,
        start: cursor,
        end: monthEnd,
      );
      put(
        cursor,
        (current) => DashboardMonthlyRollup(
          id: current.id,
          factoryId: current.factoryId,
          yearMonth: current.yearMonth,
          year: current.year,
          month: current.month,
          income: current.income,
          incomeSales: current.incomeSales,
          incomeJobWork: current.incomeJobWork,
          expenses: current.expenses,
          stockCutSmallSqFt: current.stockCutSmallSqFt + cut.smallSqFt,
          stockCutLargeSqFt: current.stockCutLargeSqFt + cut.largeSqFt,
          stockCutSmallAmount: current.stockCutSmallAmount + cut.smallAmount,
          stockCutLargeAmount: current.stockCutLargeAmount + cut.largeAmount,
          salesSmallSqFt: current.salesSmallSqFt + sold.smallSqFt,
          salesLargeSqFt: current.salesLargeSqFt + sold.largeSqFt,
          salesSmallAmount: current.salesSmallAmount + sold.smallAmount,
          salesLargeAmount: current.salesLargeAmount + sold.largeAmount,
        ),
      );
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return buckets;
  }

  Future<List<Payment>> _readPayments(String factoryId, DateTime from) async {
    final snapshot = await constrainFactoryQuery(
      trackedCollection(_firestore, 'payments')
          .where('factoryId', isEqualTo: factoryId),
      dateField: 'date',
      from: from,
    ).get();
    return snapshot.docs
        .map((doc) => PaymentModel.fromFirestore(doc.id, doc.data()).toEntity())
        .toList();
  }

  Future<List<Expense>> _readExpenses(String factoryId, DateTime from) async {
    final snapshot = await constrainFactoryQuery(
      trackedCollection(_firestore, 'expenses')
          .where('factoryId', isEqualTo: factoryId),
      dateField: 'expenseDate',
      from: from,
    ).get();
    return snapshot.docs
        .map((doc) => ExpenseModel.fromFirestore(doc.id, doc.data()).toEntity())
        .toList();
  }

  Future<List<JobWorkLoad>> _readLoads(String factoryId) async {
    final snapshot = await trackedCollection(_firestore, 'jobWorkLoads')
        .where('factoryId', isEqualTo: factoryId)
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              JobWorkLoadModel.fromFirestore(doc.id, doc.data()).toEntity(),
        )
        .toList();
  }

  Future<List<JobWorkOrder>> _readJobWorkOrders(String factoryId) async {
    final snapshot = await trackedCollection(_firestore, 'jobWorkOrders')
        .where('factoryId', isEqualTo: factoryId)
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              JobWorkOrderModel.fromFirestore(doc.id, doc.data()).toEntity(),
        )
        .toList();
  }

  Future<List<SalesOrder>> _readSalesOrders(String factoryId) async {
    final snapshot = await trackedCollection(_firestore, 'salesOrders')
        .where('factoryId', isEqualTo: factoryId)
        .get();
    return snapshot.docs
        .map(
          (doc) => SalesOrderModel.fromFirestore(doc.id, doc.data()).toEntity(),
        )
        .toList();
  }

  bool _countsTowardIncome(Payment payment) {
    if (payment.amount.abs() < 0.005) return false;
    return payment.status == PaymentStatus.completed ||
        payment.status == PaymentStatus.partiallyApplied;
  }
}
