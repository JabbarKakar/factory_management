import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/expense_summary_report.dart';

class ExpenseSummaryExcelExporter {
  List<int> build(ExpenseSummaryReport report) {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet();
    if (sheetName == null) {
      throw StateError('Excel workbook has no default sheet');
    }
    final sheet = excel[sheetName];
    final monthLabel = DateFormat.yMMMM().format(
      DateTime(report.year, report.month),
    );
    final dateFormat = DateFormat.yMMMd();

    void setCell(int row, int col, String value, {bool bold = false}) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      );
      cell.value = TextCellValue(value);
      if (bold) {
        cell.cellStyle = CellStyle(bold: true);
      }
    }

    var row = 0;
    setCell(row++, 0, AppStrings.expenseSummaryReport, bold: true);
    setCell(row++, 0, monthLabel);
    row++;

    setCell(row++, 0, AppStrings.expensesByCategory, bold: true);
    for (final entry in report.categoryTotals) {
      setCell(row, 0, entry.$1.label);
      setCell(row++, 1, Formatters.currencyForExport(entry.$2));
    }
    setCell(row, 0, AppStrings.totalExpenses);
    setCell(row++, 1, Formatters.currencyForExport(report.totalExpenses), bold: true);
    row++;

    setCell(row++, 0, AppStrings.expenseDetails, bold: true);
    setCell(row, 0, AppStrings.date, bold: true);
    setCell(row, 1, AppStrings.expenseNumber, bold: true);
    setCell(row, 2, AppStrings.expenseCategory, bold: true);
    setCell(row, 3, AppStrings.description, bold: true);
    setCell(row++, 4, AppStrings.amount, bold: true);

    for (final line in report.lines) {
      final expense = line.expense;
      setCell(row, 0, dateFormat.format(expense.expenseDate));
      setCell(row, 1, Formatters.textForExport(expense.expenseNumber));
      setCell(row, 2, line.category.label);
      setCell(row, 3, Formatters.textForExport(expense.description));
      setCell(row++, 4, Formatters.currencyForExport(line.amount));
    }

    final encoded = excel.encode();
    if (encoded == null || encoded.isEmpty) {
      throw StateError('Excel encode failed');
    }
    return encoded;
  }
}
