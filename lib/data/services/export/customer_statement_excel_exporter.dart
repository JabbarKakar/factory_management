import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/customer_statement.dart';

class CustomerStatementExcelExporter {
  List<int> build(CustomerStatement statement) {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet();
    if (sheetName == null) {
      throw StateError('Excel workbook has no default sheet');
    }
    final sheet = excel[sheetName];

    final dateFormat = DateFormat.yMMMd();
    final rangeLabel =
        '${dateFormat.format(statement.fromDate)} - ${dateFormat.format(statement.toDate)}';

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
    setCell(row++, 0, AppStrings.customerStatement, bold: true);
    setCell(row++, 0, Formatters.textForExport(statement.customer.name), bold: true);
    setCell(row++, 0, rangeLabel);
    row++;

    final headers = [
      AppStrings.date,
      AppStrings.description,
      AppStrings.reference,
      AppStrings.debit,
      AppStrings.credit,
    ];
    for (var col = 0; col < headers.length; col++) {
      setCell(row, col, headers[col], bold: true);
    }
    row++;

    setCell(row, 0, Formatters.exportEmpty);
    setCell(row, 1, AppStrings.openingBalance);
    setCell(row, 3, Formatters.currencyForExport(statement.openingBalance));
    row++;

    for (final line in statement.lines) {
      setCell(row, 0, dateFormat.format(line.date));
      setCell(row, 1, Formatters.textForExport(line.description));
      setCell(row, 2, Formatters.textForExport(line.reference));
      if (line.debit > 0) {
        setCell(row, 3, Formatters.currencyForExport(line.debit));
      }
      if (line.credit > 0) {
        setCell(row, 4, Formatters.currencyForExport(line.credit));
      }
      row++;
    }

    setCell(row, 0, Formatters.exportEmpty);
    setCell(row, 1, AppStrings.closingBalance, bold: true);
    setCell(row, 3, Formatters.currencyForExport(statement.closingBalance), bold: true);

    final encoded = excel.encode();
    if (encoded == null || encoded.isEmpty) {
      throw StateError('Excel encode failed');
    }
    return encoded;
  }
}
