import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/monthly_pl_report.dart';

class PlReportExcelExporter {
  List<int> build(MonthlyPlReport report) {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet();
    if (sheetName == null) {
      throw StateError('Excel workbook has no default sheet');
    }
    final sheet = excel[sheetName];

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
    setCell(row++, 1, Formatters.currencyForExport(report.salesRevenue));
    setCell(row, 0, AppStrings.jobWorkRevenue);
    setCell(row++, 1, Formatters.currencyForExport(report.jobWorkRevenue));
    setCell(row, 0, AppStrings.totalRevenue);
    setCell(row++, 1, Formatters.currencyForExport(report.totalRevenue), bold: true);
    row++;

    setCell(row++, 0, AppStrings.expenses, bold: true);
    for (final line in report.expenseLines) {
      setCell(row, 0, line.category.label);
      setCell(row++, 1, Formatters.currencyForExport(line.amount));
    }
    setCell(row, 0, AppStrings.totalExpenses);
    setCell(row++, 1, Formatters.currencyForExport(report.totalExpenses), bold: true);
    row++;

    final profitLabel =
        report.netProfit >= 0 ? AppStrings.netProfit : AppStrings.netLoss;
    setCell(row, 0, profitLabel);
    setCell(row++, 1, Formatters.currencyForExport(report.netProfit.abs()), bold: true);
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
    if (encoded == null || encoded.isEmpty) {
      throw StateError('Excel encode failed');
    }
    return encoded;
  }
}
