import 'package:equatable/equatable.dart';

/// One calendar month of factory dashboard totals (S41).
class DashboardMonthlyRollup extends Equatable {
  const DashboardMonthlyRollup({
    required this.id,
    required this.factoryId,
    required this.yearMonth,
    required this.year,
    required this.month,
    this.income = 0,
    this.incomeSales = 0,
    this.incomeJobWork = 0,
    this.expenses = 0,
    this.stockCutSmallSqFt = 0,
    this.stockCutLargeSqFt = 0,
    this.stockCutSmallAmount = 0,
    this.stockCutLargeAmount = 0,
    this.salesSmallSqFt = 0,
    this.salesLargeSqFt = 0,
    this.salesSmallAmount = 0,
    this.salesLargeAmount = 0,
  });

  final String id;
  final String factoryId;

  /// `yyyy-MM`
  final String yearMonth;
  final int year;
  final int month;
  final double income;
  final double incomeSales;
  final double incomeJobWork;
  final double expenses;
  final double stockCutSmallSqFt;
  final double stockCutLargeSqFt;
  final double stockCutSmallAmount;
  final double stockCutLargeAmount;
  final double salesSmallSqFt;
  final double salesLargeSqFt;
  final double salesSmallAmount;
  final double salesLargeAmount;

  DateTime get monthStart => DateTime(year, month, 1);

  DateTime get monthEnd => DateTime(year, month + 1, 0);

  bool overlaps(DateTime start, DateTime end) {
    return !monthEnd.isBefore(start) && !monthStart.isAfter(end);
  }

  @override
  List<Object?> get props => [
        id,
        factoryId,
        yearMonth,
        year,
        month,
        income,
        incomeSales,
        incomeJobWork,
        expenses,
        stockCutSmallSqFt,
        stockCutLargeSqFt,
        stockCutSmallAmount,
        stockCutLargeAmount,
        salesSmallSqFt,
        salesLargeSqFt,
        salesSmallAmount,
        salesLargeAmount,
      ];
}

class DashboardRollupDelta {
  const DashboardRollupDelta({
    this.income = 0,
    this.incomeSales = 0,
    this.incomeJobWork = 0,
    this.expenses = 0,
    this.stockCutSmallSqFt = 0,
    this.stockCutLargeSqFt = 0,
    this.stockCutSmallAmount = 0,
    this.stockCutLargeAmount = 0,
    this.salesSmallSqFt = 0,
    this.salesLargeSqFt = 0,
    this.salesSmallAmount = 0,
    this.salesLargeAmount = 0,
  });

  final double income;
  final double incomeSales;
  final double incomeJobWork;
  final double expenses;
  final double stockCutSmallSqFt;
  final double stockCutLargeSqFt;
  final double stockCutSmallAmount;
  final double stockCutLargeAmount;
  final double salesSmallSqFt;
  final double salesLargeSqFt;
  final double salesSmallAmount;
  final double salesLargeAmount;

  bool get isEmpty =>
      income == 0 &&
      incomeSales == 0 &&
      incomeJobWork == 0 &&
      expenses == 0 &&
      stockCutSmallSqFt == 0 &&
      stockCutLargeSqFt == 0 &&
      stockCutSmallAmount == 0 &&
      stockCutLargeAmount == 0 &&
      salesSmallSqFt == 0 &&
      salesLargeSqFt == 0 &&
      salesSmallAmount == 0 &&
      salesLargeAmount == 0;
}
