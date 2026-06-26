import '../../domain/entities/expense.dart';
import '../../domain/entities/monthly_pl_report.dart';
import '../../domain/entities/payment.dart';
import '../../domain/enums/expense_enums.dart';
import '../../domain/enums/invoice_enums.dart';

class PlReportService {
  MonthlyPlReport buildReport({
    required int year,
    required int month,
    required List<Payment> payments,
    required List<Expense> expenses,
  }) {
    bool inMonth(DateTime date) => date.year == year && date.month == month;

    final monthPayments =
        payments.where((payment) => inMonth(payment.paymentDate)).toList();

    final salesRevenue = monthPayments
        .where((payment) => payment.invoiceType == InvoiceType.sales)
        .fold<double>(0, (sum, payment) => sum + payment.amount);

    final jobWorkRevenue = monthPayments
        .where((payment) => payment.invoiceType == InvoiceType.jobWork)
        .fold<double>(0, (sum, payment) => sum + payment.amount);

    final totalRevenue = salesRevenue + jobWorkRevenue;

    final monthExpenses =
        expenses.where((expense) => inMonth(expense.expenseDate)).toList();

    final categoryTotals = <ExpenseCategory, double>{};
    for (final expense in monthExpenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    final expenseLines = categoryTotals.entries
        .map((entry) => PlCategoryLine(category: entry.key, amount: entry.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final totalExpenses =
        expenseLines.fold<double>(0, (sum, line) => sum + line.amount);

    final netProfit = totalRevenue - totalExpenses;
    final netProfitMargin = totalRevenue > 0
        ? (netProfit / totalRevenue) * 100.0
        : 0.0;

    return MonthlyPlReport(
      year: year,
      month: month,
      salesRevenue: salesRevenue,
      jobWorkRevenue: jobWorkRevenue,
      totalRevenue: totalRevenue,
      expenseLines: expenseLines,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
      netProfitMargin: netProfitMargin,
      paymentCount: monthPayments.length,
      expenseCount: monthExpenses.length,
    );
  }
}
