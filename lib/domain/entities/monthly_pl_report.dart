import 'package:equatable/equatable.dart';

import '../enums/expense_enums.dart';

class PlCategoryLine extends Equatable {
  const PlCategoryLine({
    required this.category,
    required this.amount,
  });

  final ExpenseCategory category;
  final double amount;

  String get label => category.label;

  @override
  List<Object?> get props => [category, amount];
}

class MonthlyPlReport extends Equatable {
  const MonthlyPlReport({
    required this.year,
    required this.month,
    required this.salesRevenue,
    required this.jobWorkRevenue,
    required this.totalRevenue,
    required this.expenseLines,
    required this.totalExpenses,
    required this.netProfit,
    required this.netProfitMargin,
    required this.paymentCount,
    required this.expenseCount,
  });

  final int year;
  final int month;
  final double salesRevenue;
  final double jobWorkRevenue;
  final double totalRevenue;
  final List<PlCategoryLine> expenseLines;
  final double totalExpenses;
  final double netProfit;
  final double netProfitMargin;
  final int paymentCount;
  final int expenseCount;

  DateTime get monthDate => DateTime(year, month);

  bool get isProfit => netProfit >= 0;

  bool get hasData => paymentCount > 0 || expenseCount > 0;

  static const empty = MonthlyPlReport(
    year: 0,
    month: 0,
    salesRevenue: 0,
    jobWorkRevenue: 0,
    totalRevenue: 0,
    expenseLines: [],
    totalExpenses: 0,
    netProfit: 0,
    netProfitMargin: 0,
    paymentCount: 0,
    expenseCount: 0,
  );

  @override
  List<Object?> get props => [
        year,
        month,
        salesRevenue,
        jobWorkRevenue,
        totalRevenue,
        expenseLines,
        totalExpenses,
        netProfit,
        netProfitMargin,
        paymentCount,
        expenseCount,
      ];
}
