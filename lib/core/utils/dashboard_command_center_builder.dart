import 'package:intl/intl.dart';

import '../../core/constants/job_work_sizes.dart';
import '../../data/services/dashboard_rollup_service.dart';
import '../../data/services/job_work_collection_quantity_helper.dart';
import '../../domain/entities/dashboard_cashflow_metrics.dart';
import '../../domain/entities/dashboard_command_center.dart';
import '../../domain/entities/dashboard_monthly_rollup.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/job_work_collection.dart';
import '../../domain/entities/job_work_dispatch_metrics.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/entities/sales_order.dart';
import '../../data/services/job_work_container_sync_helper.dart';
import '../../data/services/sales_container_sync_helper.dart';
import '../../domain/enums/dashboard_finance_period.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/sales_enums.dart';
import 'dashboard_job_work_metrics.dart';
import 'dashboard_sales_sqft_metrics.dart';

/// Builds period-driven command-center metrics and chart series.
abstract final class DashboardCommandCenterBuilder {
  static DateTime? findEarliestTransactionDate({
    DateTime? factoryCreatedAt,
    List<Payment>? payments,
    List<Expense>? expenses,
    List<JobWorkOrder>? jobWorkOrders,
    List<JobWorkLoad>? jobWorkLoads,
    List<JobWorkInvoice>? jobWorkInvoices,
    List<SalesInvoice>? salesInvoices,
    List<SalesOrder>? salesOrders,
    List<Delivery>? deliveries,
    List<JobWorkCollection>? jobWorkCollections,
  }) {
    DateTime? minDate = factoryCreatedAt;

    void check(DateTime? date) {
      if (date == null) return;
      if (minDate == null || date.isBefore(minDate!)) {
        minDate = date;
      }
    }

    if (payments != null) {
      for (final p in payments) {
        check(p.paymentDate);
      }
    }
    if (expenses != null) {
      for (final e in expenses) {
        check(e.expenseDate);
      }
    }
    if (jobWorkOrders != null) {
      for (final o in jobWorkOrders) {
        check(o.createdAt);
      }
    }
    if (jobWorkLoads != null) {
      for (final l in jobWorkLoads) {
        check(l.createdAt);
        if (l.output?.recordedAt != null) {
          check(l.output!.recordedAt);
        }
      }
    }
    if (jobWorkInvoices != null) {
      for (final i in jobWorkInvoices) {
        check(i.createdAt);
      }
    }
    if (salesInvoices != null) {
      for (final i in salesInvoices) {
        check(i.createdAt);
      }
    }
    if (salesOrders != null) {
      for (final o in salesOrders) {
        check(o.createdAt);
      }
    }
    if (deliveries != null) {
      for (final d in deliveries) {
        check(d.scheduledDate);
      }
    }
    if (jobWorkCollections != null) {
      for (final c in jobWorkCollections) {
        check(c.collectedAt);
      }
    }

    return minDate;
  }

  static bool _isSmallSize(String size) {
    final clean = size.trim();
    if (clean.isEmpty) return false;
    if (JobWorkSizes.isSmall(clean)) return true;
    if (JobWorkSizes.isLarge(clean)) return false;

    // Fallback: parse width dimension (e.g. "6x24" -> 6 is small < 12; "12x60" -> 12 is large >= 12)
    final parts = clean.split(RegExp(r'[xX*]'));
    if (parts.isNotEmpty) {
      final width = double.tryParse(parts[0].trim());
      if (width != null) {
        return width < 12;
      }
    }
    return false;
  }

  static JobWorkDispatchCategoryMetrics _jobWorkCollectionMetricsInRange({
    required List<JobWorkCollection> collections,
    required DateTime start,
    required DateTime end,
  }) {
    var largePieces = 0;
    var largeSqFt = 0.0;
    var smallPieces = 0;
    var smallSqFt = 0.0;

    for (final collection in collections) {
      if (!JobWorkCollectionQuantityHelper.counts(collection)) continue;
      final collectedDate = collection.collectedAt;
      final createdDate = collection.createdAt;
      final inRange = DashboardFinancePeriodRange.contains(collectedDate, start, end) ||
          DashboardFinancePeriodRange.contains(createdDate, start, end);
      if (!inRange) continue;

      for (final item in collection.lineItems) {
        final isSmall = item.isSmall || _isSmallSize(item.size);
        if (isSmall) {
          smallPieces += item.pieces;
          smallSqFt += item.squareFeet;
        } else {
          largePieces += item.pieces;
          largeSqFt += item.squareFeet;
        }
      }
    }

    return JobWorkDispatchCategoryMetrics(
      largePieces: largePieces,
      largeSqFt: largeSqFt,
      smallPieces: smallPieces,
      smallSqFt: smallSqFt,
    );
  }

  static JobWorkDispatchCategoryMetrics _saleDispatchMetricsInRange({
    required List<Delivery> deliveries,
    required DateTime start,
    required DateTime end,
  }) {
    var largePieces = 0;
    var largeSqFt = 0.0;
    var smallPieces = 0;
    var smallSqFt = 0.0;

    for (final delivery in deliveries) {
      final dispatchDate = delivery.actualDeliveryDate ??
          delivery.createdAt;
      final inRange = DashboardFinancePeriodRange.contains(dispatchDate, start, end) ||
          DashboardFinancePeriodRange.contains(delivery.scheduledDate, start, end) ||
          DashboardFinancePeriodRange.contains(delivery.createdAt, start, end);

      if (!inRange) continue;

      for (final item in delivery.lineItems) {
        final isSmall = _isSmallSize(item.sizeThickness);
        if (isSmall) {
          smallPieces += item.effectivePieces;
          smallSqFt += item.effectiveSquareFeet;
        } else {
          largePieces += item.effectivePieces;
          largeSqFt += item.effectiveSquareFeet;
        }
      }
    }

    return JobWorkDispatchCategoryMetrics(
      largePieces: largePieces,
      largeSqFt: largeSqFt,
      smallPieces: smallPieces,
      smallSqFt: smallSqFt,
    );
  }

  static DashboardCommandCenter build({
    required DashboardFinancePeriod period,
    required DateTime now,
    required List<Payment> payments,
    required List<Expense> expenses,
    required List<JobWorkOrder> jobWorkOrders,
    required List<JobWorkLoad> jobWorkLoads,
    required List<JobWorkInvoice> jobWorkInvoices,
    required List<SalesInvoice> salesInvoices,
    required List<SalesOrder> salesOrders,
    required List<Delivery> deliveries,
    required int activeJobWorks,
    List<JobWorkCollection> jobWorkCollections = const [],
    List<DashboardMonthlyRollup> monthlyRollups = const [],
    DateTime? factoryCreatedAt,
  }) {
    final earliest = findEarliestTransactionDate(
      factoryCreatedAt: factoryCreatedAt,
      payments: payments,
      expenses: expenses,
      jobWorkOrders: jobWorkOrders,
      jobWorkLoads: jobWorkLoads,
      jobWorkInvoices: jobWorkInvoices,
      salesInvoices: salesInvoices,
      salesOrders: salesOrders,
      deliveries: deliveries,
      jobWorkCollections: jobWorkCollections,
    );

    final range = DashboardFinancePeriodRange.forPeriod(
      period,
      now,
      earliestDate: earliest,
    );
    final useRollups =
        period.usesMonthlyRollups && monthlyRollups.isNotEmpty;
    final buckets = useRollups
        ? _monthlyBuckets(range.currentStart, range.currentEnd, DateFormat.MMM())
        : _buckets(period, range.currentStart, range.currentEnd);

    final cashflowSeries = <DashboardCashflowPoint>[];
    final salesVsJw = <DashboardRevenueComparePoint>[];
    final incomeSpark = <double>[];
    final expenseSpark = <double>[];

    for (final bucket in buckets) {
      final income = useRollups
          ? DashboardRollupService.sumIncome(
              monthlyRollups,
              bucket.start,
              bucket.end,
            )
          : _sumPayments(payments, bucket.start, bucket.end);
      final expense = useRollups
          ? DashboardRollupService.sumExpenses(
              monthlyRollups,
              bucket.start,
              bucket.end,
            )
          : _sumExpenses(expenses, bucket.start, bucket.end);
      var sales = 0.0;
      var jw = 0.0;
      if (useRollups) {
        sales = DashboardRollupService.sumIncomeSales(
          monthlyRollups,
          bucket.start,
          bucket.end,
        );
        jw = DashboardRollupService.sumIncomeJobWork(
          monthlyRollups,
          bucket.start,
          bucket.end,
        );
      } else {
        for (final payment in payments) {
          if (!DashboardFinancePeriodRange.contains(
            payment.paymentDate,
            bucket.start,
            bucket.end,
          )) {
            continue;
          }
          if (payment.invoiceType == InvoiceType.sales) {
            sales += payment.amount;
          } else {
            jw += payment.amount;
          }
        }
      }

      cashflowSeries.add(
        DashboardCashflowPoint(
          date: bucket.start,
          income: income,
          expenses: expense,
          label: bucket.label,
        ),
      );
      salesVsJw.add(
        DashboardRevenueComparePoint(
          date: bucket.start,
          salesAmount: sales,
          jobWorkAmount: jw,
          label: bucket.label,
        ),
      );
      incomeSpark.add(income);
      expenseSpark.add(expense);
    }

    final income = useRollups
        ? DashboardRollupService.sumIncome(
            monthlyRollups,
            range.currentStart,
            range.currentEnd,
          )
        : _sumPayments(
            payments,
            range.currentStart,
            range.currentEnd,
          );
    final expenseTotal = useRollups
        ? DashboardRollupService.sumExpenses(
            monthlyRollups,
            range.currentStart,
            range.currentEnd,
          )
        : _sumExpenses(
            expenses,
            range.currentStart,
            range.currentEnd,
          );
    final previousIncome = useRollups
        ? DashboardRollupService.sumIncome(
            monthlyRollups,
            range.previousStart,
            range.previousEnd,
          )
        : _sumPayments(
            payments,
            range.previousStart,
            range.previousEnd,
          );
    final previousExpenses = useRollups
        ? DashboardRollupService.sumExpenses(
            monthlyRollups,
            range.previousStart,
            range.previousEnd,
          )
        : _sumExpenses(
            expenses,
            range.previousStart,
            range.previousEnd,
          );

    final DashboardStockCutTotals stock;
    if (useRollups) {
      final rolled = DashboardRollupService.stockCut(
        period: period,
        now: now,
        rollups: monthlyRollups,
        earliestDate: earliest,
      );
      stock = DashboardStockCutTotals(
        smallSqFt: rolled.smallSqFt,
        largeSqFt: rolled.largeSqFt,
        smallAmount: rolled.smallAmount,
        largeAmount: rolled.largeAmount,
      );
    } else {
      stock = DashboardJobWorkMetrics.factoryStockCutInRange(
        orders: jobWorkOrders,
        loads: jobWorkLoads,
        start: range.currentStart,
        end: range.currentEnd,
      );
    }
    final waste = _wasteYieldSqFtInRange(
      orders: jobWorkOrders,
      loads: jobWorkLoads,
      start: range.currentStart,
      end: range.currentEnd,
    );

    final salesSqFt = useRollups
        ? () {
            final rolled = DashboardRollupService.salesSqFt(
              period: period,
              now: now,
              rollups: monthlyRollups,
              earliestDate: earliest,
            );
            return (
              smallSqFt: rolled.smallSqFt,
              largeSqFt: rolled.largeSqFt,
              smallAmount: rolled.smallAmount,
              largeAmount: rolled.largeAmount,
            );
          }()
        : DashboardSalesSqFtHelper.factorySalesSqFtInRange(
            orders: salesOrders,
            start: range.currentStart,
            end: range.currentEnd,
          );

    final outstanding = _outstandingReceivables(
      jobWorkOrders: jobWorkOrders,
      jobWorkLoads: jobWorkLoads,
      jobWorkInvoices: jobWorkInvoices,
      payments: payments,
      salesOrders: salesOrders,
      salesInvoices: salesInvoices,
    );

    final activeDispatches =
        deliveries.where((d) => d.status.isActive).length;

    final today = DashboardFinancePeriodRange.dateOnly(now);
    final throughput = DashboardJobWorkMetrics.factoryStockCutInRange(
      orders: jobWorkOrders,
      loads: jobWorkLoads,
      start: today,
      end: today,
    );

    final jwCollectionMetrics = _jobWorkCollectionMetricsInRange(
      collections: jobWorkCollections,
      start: range.currentStart,
      end: range.currentEnd,
    );

    final saleDispatchMetrics = _saleDispatchMetricsInRange(
      deliveries: deliveries,
      start: range.currentStart,
      end: range.currentEnd,
    );

    return DashboardCommandCenter(
      period: period,
      income: income,
      expenses: expenseTotal,
      previousIncome: previousIncome,
      previousExpenses: previousExpenses,
      outstanding: outstanding.amount,
      outstandingCount: outstanding.count,
      salesOutstanding: outstanding.salesDue,
      jobWorkOutstanding: outstanding.jobWorkDue,
      totalCollected: outstanding.paid,
      collectedInPeriod: income,
      incomeSparkline: incomeSpark,
      expenseSparkline: expenseSpark,
      cashflowSeries: cashflowSeries,
      salesVsJobWorkSeries: salesVsJw,
      smallStockSqFt: stock.smallSqFt,
      largeStockSqFt: stock.largeSqFt,
      wasteYieldSqFt: waste,
      smallStockAmount: stock.smallAmount,
      largeStockAmount: stock.largeAmount,
      salesSmallSqFt: salesSqFt.smallSqFt,
      salesLargeSqFt: salesSqFt.largeSqFt,
      salesSmallAmount: salesSqFt.smallAmount,
      salesLargeAmount: salesSqFt.largeAmount,
      activeJobWorks: activeJobWorks,
      activeDispatches: activeDispatches,
      throughputSqFt: throughput.smallSqFt + throughput.largeSqFt,
      jobWorkCollectionMetrics: jwCollectionMetrics,
      saleDispatchMetrics: saleDispatchMetrics,
    );
  }

  static double _sumPayments(
    List<Payment> payments,
    DateTime start,
    DateTime end,
  ) {
    return payments
        .where(
          (p) => DashboardFinancePeriodRange.contains(p.paymentDate, start, end),
        )
        .fold<double>(0, (sum, p) => sum + p.amount);
  }

  static double _sumExpenses(
    List<Expense> expenses,
    DateTime start,
    DateTime end,
  ) {
    return expenses
        .where(
          (e) => DashboardFinancePeriodRange.contains(e.expenseDate, start, end),
        )
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  static ({
    double amount,
    int count,
    double paid,
    double salesDue,
    double jobWorkDue,
  }) _outstandingReceivables({
    required List<JobWorkOrder> jobWorkOrders,
    required List<JobWorkLoad> jobWorkLoads,
    required List<JobWorkInvoice> jobWorkInvoices,
    required List<Payment> payments,
    required List<SalesOrder> salesOrders,
    required List<SalesInvoice> salesInvoices,
  }) {
    var jobWorkDue = 0.0;
    var jobWorkPaid = 0.0;
    var salesDue = 0.0;
    var salesPaid = 0.0;
    var count = 0;

    for (final order in jobWorkOrders) {
      if (order.status == JobWorkStatus.cancelled) continue;
      final finance = JobWorkContainerSyncHelper.rollupInvoiceFinance(
        order: order,
        loads: jobWorkLoads,
        invoices: jobWorkInvoices
            .where((invoice) => invoice.jobWorkId == order.id)
            .toList(),
        payments: payments,
      );
      jobWorkDue += finance.due;
      jobWorkPaid += finance.paid;
      if (finance.due > 0) count++;
    }

    final ordersByAgreement = <String, List<SalesOrder>>{};
    for (final order in salesOrders) {
      if (order.status == SalesOrderStatus.cancelled) continue;
      final agreementId = order.agreementId?.trim() ?? '';
      final key = agreementId.isEmpty ? order.id : agreementId;
      ordersByAgreement.putIfAbsent(key, () => []).add(order);
    }

    for (final entry in ordersByAgreement.entries) {
      var groupDue = 0.0;
      var groupPaid = 0.0;
      for (final order in entry.value) {
        SalesInvoice? invoice = salesInvoices
            .where(
              (item) =>
                  item.status != InvoiceStatus.cancelled &&
                  !item.isGrandInvoice &&
                  item.salesOrderId.trim() == order.id,
            )
            .firstOrNull;
        final linkedId = order.invoiceId?.trim();
        if (linkedId != null && linkedId.isNotEmpty) {
          final linked = salesInvoices
              .where((item) => item.id == linkedId)
              .firstOrNull;
          if (linked != null) invoice = linked;
        }
        final finance = SalesContainerSyncHelper.financeForOrder(
          order: order,
          invoice: invoice,
        );
        groupDue += finance.due;
        groupPaid += finance.paid;
      }
      salesDue += groupDue;
      salesPaid += groupPaid;
      if (groupDue > 0) count++;
    }

    return (
      amount: salesDue + jobWorkDue,
      count: count,
      paid: salesPaid + jobWorkPaid,
      salesDue: salesDue,
      jobWorkDue: jobWorkDue,
    );
  }

  static double _wasteYieldSqFtInRange({
    required List<JobWorkOrder> orders,
    required List<JobWorkLoad> loads,
    required DateTime start,
    required DateTime end,
  }) {
    var total = 0.0;

    for (final load in loads) {
      final output = load.output;
      if (output == null || !output.isRecorded || output.recordedAt == null) {
        continue;
      }
      if (!DashboardFinancePeriodRange.contains(
        output.recordedAt!,
        start,
        end,
      )) {
        continue;
      }
      total += output.wasteAndYieldDeductionSqFt;
    }

    for (final order in orders) {
      final output = order.output;
      if (output == null || !output.isRecorded || output.recordedAt == null) {
        continue;
      }
      // Skip legacy order-level output when loads cover this order.
      final hasLoads = loads.any((l) => l.jobWorkId == order.id);
      if (hasLoads) continue;
      if (!DashboardFinancePeriodRange.contains(
        output.recordedAt!,
        start,
        end,
      )) {
        continue;
      }
      total += output.wasteAndYieldDeductionSqFt;
    }

    return total;
  }

  static List<({DateTime start, DateTime end, String label})> _buckets(
    DashboardFinancePeriod period,
    DateTime start,
    DateTime end,
  ) {
    final dayFmt = DateFormat.E();
    final mdFmt = DateFormat.Md();
    final monFmt = DateFormat.MMM();

    switch (period) {
      case DashboardFinancePeriod.daily:
        // Context sparkline: last 7 days ending at [end].
        final seriesStart = end.subtract(const Duration(days: 6));
        return List.generate(7, (i) {
          final day = seriesStart.add(Duration(days: i));
          return (start: day, end: day, label: dayFmt.format(day));
        });
      case DashboardFinancePeriod.weekly:
        return _dailyBuckets(start, end, dayFmt);
      case DashboardFinancePeriod.monthly:
        final days = end.difference(start).inDays + 1;
        if (days <= 16) return _dailyBuckets(start, end, mdFmt);
        return _everyNDaysBuckets(start, end, 2, mdFmt);
      case DashboardFinancePeriod.sixMonths:
        return _weeklyBuckets(start, end, mdFmt);
      case DashboardFinancePeriod.yearly:
      case DashboardFinancePeriod.allTime:
        return _monthlyBuckets(start, end, monFmt);
    }
  }

  static List<({DateTime start, DateTime end, String label})> _dailyBuckets(
    DateTime start,
    DateTime end,
    DateFormat fmt,
  ) {
    final out = <({DateTime start, DateTime end, String label})>[];
    var cursor = start;
    while (!cursor.isAfter(end)) {
      out.add((start: cursor, end: cursor, label: fmt.format(cursor)));
      cursor = cursor.add(const Duration(days: 1));
    }
    return out;
  }

  static List<({DateTime start, DateTime end, String label})>
      _everyNDaysBuckets(
    DateTime start,
    DateTime end,
    int step,
    DateFormat fmt,
  ) {
    final out = <({DateTime start, DateTime end, String label})>[];
    var cursor = start;
    while (!cursor.isAfter(end)) {
      final bucketEnd = cursor.add(Duration(days: step - 1));
      final clampedEnd = bucketEnd.isAfter(end) ? end : bucketEnd;
      out.add((
        start: cursor,
        end: clampedEnd,
        label: fmt.format(cursor),
      ));
      cursor = clampedEnd.add(const Duration(days: 1));
    }
    return out;
  }

  static List<({DateTime start, DateTime end, String label})> _weeklyBuckets(
    DateTime start,
    DateTime end,
    DateFormat fmt,
  ) {
    final out = <({DateTime start, DateTime end, String label})>[];
    var cursor = start;
    while (!cursor.isAfter(end)) {
      final bucketEnd = cursor.add(const Duration(days: 6));
      final clampedEnd = bucketEnd.isAfter(end) ? end : bucketEnd;
      out.add((
        start: cursor,
        end: clampedEnd,
        label: fmt.format(cursor),
      ));
      cursor = clampedEnd.add(const Duration(days: 1));
    }
    return out;
  }

  static List<({DateTime start, DateTime end, String label})> _monthlyBuckets(
    DateTime start,
    DateTime end,
    DateFormat fmt,
  ) {
    final out = <({DateTime start, DateTime end, String label})>[];
    var cursor = DateTime(start.year, start.month, 1);
    while (!cursor.isAfter(end)) {
      final monthEnd = DateTime(cursor.year, cursor.month + 1, 0);
      final clampedStart = cursor.isBefore(start) ? start : cursor;
      final clampedEnd = monthEnd.isAfter(end) ? end : monthEnd;
      if (!clampedStart.isAfter(clampedEnd)) {
        out.add((
          start: clampedStart,
          end: clampedEnd,
          label: fmt.format(cursor),
        ));
      }
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return out;
  }
}
