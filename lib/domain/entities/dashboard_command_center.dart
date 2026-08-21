import 'package:equatable/equatable.dart';

import '../enums/dashboard_finance_period.dart';
import 'job_work_dispatch_metrics.dart';
import 'dashboard_kpis.dart';

class DashboardCashflowPoint extends Equatable {
  const DashboardCashflowPoint({
    required this.date,
    required this.income,
    required this.expenses,
    this.label,
  });

  final DateTime date;
  final double income;
  final double expenses;
  final String? label;

  double get net => income - expenses;

  @override
  List<Object?> get props => [date, income, expenses, label];
}

class DashboardRevenueComparePoint extends Equatable {
  const DashboardRevenueComparePoint({
    required this.date,
    required this.salesAmount,
    required this.jobWorkAmount,
    this.label,
  });

  final DateTime date;
  final double salesAmount;
  final double jobWorkAmount;
  final String? label;

  double get total => salesAmount + jobWorkAmount;

  @override
  List<Object?> get props => [date, salesAmount, jobWorkAmount, label];
}

/// Period-driven executive dashboard payload (KPIs + chart series).
class DashboardCommandCenter extends Equatable {
  const DashboardCommandCenter({
    required this.period,
    required this.income,
    required this.expenses,
    required this.previousIncome,
    required this.previousExpenses,
    required this.outstanding,
    required this.outstandingCount,
    this.salesOutstanding = 0,
    this.jobWorkOutstanding = 0,
    this.totalCollected = 0,
    required this.collectedInPeriod,
    required this.incomeSparkline,
    required this.expenseSparkline,
    required this.cashflowSeries,
    required this.salesVsJobWorkSeries,
    required this.smallStockSqFt,
    required this.largeStockSqFt,
    required this.wasteYieldSqFt,
    this.smallStockAmount = 0,
    this.largeStockAmount = 0,
    required this.salesSmallSqFt,
    required this.salesLargeSqFt,
    this.salesSmallAmount = 0,
    this.salesLargeAmount = 0,
    required this.activeJobWorks,
    required this.activeDispatches,
    required this.throughputSqFt,
    this.jobWorkCollectionMetrics = JobWorkDispatchCategoryMetrics.empty,
    this.saleDispatchMetrics = JobWorkDispatchCategoryMetrics.empty,
  });

  static const empty = DashboardCommandCenter(
    period: DashboardFinancePeriod.daily,
    income: 0,
    expenses: 0,
    previousIncome: 0,
    previousExpenses: 0,
    outstanding: 0,
    outstandingCount: 0,
    salesOutstanding: 0,
    jobWorkOutstanding: 0,
    totalCollected: 0,
    collectedInPeriod: 0,
    incomeSparkline: [],
    expenseSparkline: [],
    cashflowSeries: [],
    salesVsJobWorkSeries: [],
    smallStockSqFt: 0,
    largeStockSqFt: 0,
    wasteYieldSqFt: 0,
    smallStockAmount: 0,
    largeStockAmount: 0,
    salesSmallSqFt: 0,
    salesLargeSqFt: 0,
    salesSmallAmount: 0,
    salesLargeAmount: 0,
    activeJobWorks: 0,
    activeDispatches: 0,
    throughputSqFt: 0,
    jobWorkCollectionMetrics: JobWorkDispatchCategoryMetrics.empty,
    saleDispatchMetrics: JobWorkDispatchCategoryMetrics.empty,
  );

  final DashboardFinancePeriod period;
  final double income;
  final double expenses;
  final double previousIncome;
  final double previousExpenses;
  final double outstanding;
  final int outstandingCount;
  final double salesOutstanding;
  final double jobWorkOutstanding;
  final double totalCollected;
  final double collectedInPeriod;
  final List<double> incomeSparkline;
  final List<double> expenseSparkline;
  final List<DashboardCashflowPoint> cashflowSeries;
  final List<DashboardRevenueComparePoint> salesVsJobWorkSeries;
  final double smallStockSqFt;
  final double largeStockSqFt;
  final double wasteYieldSqFt;
  final double smallStockAmount;
  final double largeStockAmount;
  final double salesSmallSqFt;
  final double salesLargeSqFt;
  final double salesSmallAmount;
  final double salesLargeAmount;
  final int activeJobWorks;
  final int activeDispatches;
  final double throughputSqFt;
  final JobWorkDispatchCategoryMetrics jobWorkCollectionMetrics;
  final JobWorkDispatchCategoryMetrics saleDispatchMetrics;

  double get net => income - expenses;

  double get processedStockSqFt =>
      smallStockSqFt + largeStockSqFt + wasteYieldSqFt;

  double get stockCutTotalSqFt => smallStockSqFt + largeStockSqFt;

  double get stockCutTotalAmount => smallStockAmount + largeStockAmount;

  double get salesTotalSqFt => salesSmallSqFt + salesLargeSqFt;

  double get salesTotalAmount => salesSmallAmount + salesLargeAmount;

  double? get incomeChangePercent =>
      DashboardKpis.dayOverDayPercent(income, previousIncome);

  double? get expensesChangePercent =>
      DashboardKpis.dayOverDayPercent(expenses, previousExpenses);

  double? get expenseRatioPercent =>
      income > 0 ? (expenses / income) * 100 : null;

  /// Paid vs pending collection efficiency (0–1).
  /// Uses all-time collected vs outstanding so it matches Sales / Job Work lists.
  double get collectionRatio {
    final collected = totalCollected > 0 ? totalCollected : collectedInPeriod;
    final total = collected + outstanding;
    if (total <= 0) return 0;
    return (collected / total).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
        period,
        income,
        expenses,
        previousIncome,
        previousExpenses,
        outstanding,
        outstandingCount,
        salesOutstanding,
        jobWorkOutstanding,
        totalCollected,
        collectedInPeriod,
        incomeSparkline,
        expenseSparkline,
        cashflowSeries,
        salesVsJobWorkSeries,
        smallStockSqFt,
        largeStockSqFt,
        wasteYieldSqFt,
        smallStockAmount,
        largeStockAmount,
        salesSmallSqFt,
        salesLargeSqFt,
        salesSmallAmount,
        salesLargeAmount,
        activeJobWorks,
        activeDispatches,
        throughputSqFt,
        jobWorkCollectionMetrics,
        saleDispatchMetrics,
      ];
}
