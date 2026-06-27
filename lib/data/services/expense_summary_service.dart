import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_summary_report.dart';
import '../../domain/enums/expense_enums.dart';

class ExpenseSummaryService {
  ExpenseSummaryReport build({
    required int year,
    required int month,
    required List<Expense> expenses,
  }) {
    bool inMonth(DateTime date) => date.year == year && date.month == month;

    final monthExpenses = expenses
        .where((expense) => inMonth(expense.expenseDate))
        .toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    final categoryTotals = <ExpenseCategory, double>{};
    for (final expense in monthExpenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final lines = monthExpenses
        .map(
          (expense) => ExpenseSummaryLine(
            expense: expense,
            category: expense.category,
            amount: expense.amount,
          ),
        )
        .toList();

    final totalExpenses =
        monthExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);

    return ExpenseSummaryReport(
      year: year,
      month: month,
      lines: lines,
      categoryTotals: sortedCategories
          .map((entry) => (entry.key, entry.value))
          .toList(),
      totalExpenses: totalExpenses,
    );
  }
}
