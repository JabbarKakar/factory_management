import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/monthly_pl_report.dart';

class PlReportExcelExporter {
  List<int> build(MonthlyPlReport report) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.delete(defaultSheet);
    }
    final sheet = excel['P&L Report'];

    final monthLabel = DateFormat.yMMMM().format(
      DateTime(report.year, report.month),
    );

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
    setCell(row++, 0, AppStrings.monthlyPlReport, bold: true);
    setCell(row++, 0, monthLabel);
    row++;

    setCell(row++, 0, AppStrings.revenue, bold: true);
    setCell(row, 0, AppStrings.salesRevenue);
    setCell(row++, 1, Formatters.currencyPkr(report.salesRevenue));
    setCell(row, 0, AppStrings.jobWorkRevenue);
    setCell(row++, 1, Formatters.currencyPkr(report.jobWorkRevenue));
    setCell(row, 0, AppStrings.totalRevenue);
    setCell(row++, 1, Formatters.currencyPkr(report.totalRevenue), bold: true);
    row++;

    setCell(row++, 0, AppStrings.expenses, bold: true);
    for (final line in report.expenseLines) {
      setCell(row, 0, line.category.label);
      setCell(row++, 1, Formatters.currencyPkr(line.amount));
    }
    setCell(row, 0, AppStrings.totalExpenses);
    setCell(row++, 1, Formatters.currencyPkr(report.totalExpenses), bold: true);
    row++;

    final profitLabel =
        report.netProfit >= 0 ? AppStrings.netProfit : AppStrings.netLoss;
    setCell(row, 0, profitLabel);
    setCell(row++, 1, Formatters.currencyPkr(report.netProfit.abs()), bold: true);
    if (report.totalRevenue > 0) {
      setCell(row, 0, AppStrings.netProfitMargin);
      setCell(
        row++,
        1,
        '${report.netProfitMargin.toStringAsFixed(1)}%',
        bold: true,
      );
    }

    final encoded = excel.encode();
    return encoded ?? [];
  }
}
