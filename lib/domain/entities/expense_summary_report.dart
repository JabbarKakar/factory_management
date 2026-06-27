import 'package:equatable/equatable.dart';

import '../enums/expense_enums.dart';
import 'expense.dart';

class ExpenseSummaryLine extends Equatable {
  const ExpenseSummaryLine({
    required this.expense,
    required this.category,
    required this.amount,
  });

  final Expense expense;
  final ExpenseCategory category;
  final double amount;

  @override
  List<Object?> get props => [expense, category, amount];
}

class ExpenseSummaryReport extends Equatable {
  const ExpenseSummaryReport({
    required this.year,
    required this.month,
    required this.lines,
    required this.categoryTotals,
    required this.totalExpenses,
  });

  final int year;
  final int month;
  final List<ExpenseSummaryLine> lines;
  final List<(ExpenseCategory category, double amount)> categoryTotals;
  final double totalExpenses;

  bool get hasData => lines.isNotEmpty;

  @override
  List<Object?> get props => [
        year,
        month,
        lines,
        categoryTotals,
        totalExpenses,
      ];
}
