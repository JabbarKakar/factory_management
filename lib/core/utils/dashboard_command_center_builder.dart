import 'package:intl/intl.dart';

import '../../domain/entities/dashboard_cashflow_metrics.dart';
import '../../domain/entities/dashboard_command_center.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/enums/dashboard_finance_period.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/entities/sales_order.dart';
import 'dashboard_job_work_metrics.dart';
import 'dashboard_sales_sqft_metrics.dart';

/// Builds period-driven command-center metrics and chart series.
abstract final class DashboardCommandCenterBuilder {
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
  }) {
    final range = DashboardFinancePeriodRange.forPeriod(period, now);
    final buckets = _buckets(period, range.currentStart, range.currentEnd);

    final cashflowSeries = <DashboardCashflowPoint>[];
    final salesVsJw = <DashboardRevenueComparePoint>[];
    final incomeSpark = <double>[];
    final expenseSpark = <double>[];

    for (final bucket in buckets) {
      final income = _sumPayments(payments, bucket.start, bucket.end);
      final expense = _sumExpenses(expenses, bucket.start, bucket.end);
      var sales = 0.0;
      var jw = 0.0;
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

    final income = _sumPayments(
      payments,
      range.currentStart,
      range.currentEnd,
    );
    final expenseTotal = _sumExpenses(
      expenses,
      range.currentStart,
      range.currentEnd,
    );
    final previousIncome = _sumPayments(
      payments,
      range.previousStart,
      range.previousEnd,
    );
    final previousExpenses = _sumExpenses(
      expenses,
      range.previousStart,
      range.previousEnd,
    );

    final stock = DashboardJobWorkMetrics.factoryStockCutInRange(
      orders: jobWorkOrders,
      loads: jobWorkLoads,
      start: range.currentStart,
      end: range.currentEnd,
    );
    final waste = _wasteYieldSqFtInRange(
      orders: jobWorkOrders,
      loads: jobWorkLoads,
      start: range.currentStart,
      end: range.currentEnd,
    );

    final salesSqFt = DashboardSalesSqFtHelper.factorySalesSqFtInRange(
      orders: salesOrders,
      start: range.currentStart,
      end: range.currentEnd,
    );

    final outstanding = _outstandingReceivables(
      jobWorkInvoices: jobWorkInvoices,
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

    return DashboardCommandCenter(
      period: period,
      income: income,
      expenses: expenseTotal,
      previousIncome: previousIncome,
      previousExpenses: previousExpenses,
      outstanding: outstanding.amount,
      outstandingCount: outstanding.count,
      collectedInPeriod: income,
      incomeSparkline: incomeSpark,
      expenseSparkline: expenseSpark,
      cashflowSeries: cashflowSeries,
      salesVsJobWorkSeries: salesVsJw,
      smallStockSqFt: stock.smallSqFt,
      largeStockSqFt: stock.largeSqFt,
      wasteYieldSqFt: waste,
      salesSmallSqFt: salesSqFt.smallSqFt,
      salesLargeSqFt: salesSqFt.largeSqFt,
      activeJobWorks: activeJobWorks,
      activeDispatches: activeDispatches,
      throughputSqFt: throughput.smallSqFt + throughput.largeSqFt,
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

  static ({double amount, int count}) _outstandingReceivables({
    required List<JobWorkInvoice> jobWorkInvoices,
    required List<SalesInvoice> salesInvoices,
  }) {
    var amount = 0.0;
    var count = 0;
    for (final invoice in jobWorkInvoices) {
      if (invoice.status == InvoiceStatus.cancelled) continue;
      if (invoice.dueAmount <= 0) continue;
      amount += invoice.dueAmount;
      count++;
    }
    for (final invoice in salesInvoices) {
      if (invoice.status == InvoiceStatus.cancelled) continue;
      if (invoice.dueAmount <= 0) continue;
      amount += invoice.dueAmount;
      count++;
    }
    return (amount: amount, count: count);
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
