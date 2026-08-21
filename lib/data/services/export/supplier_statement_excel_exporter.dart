import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/supplier_statement.dart';

class SupplierStatementExcelExporter {
  List<int> build(SupplierStatement statement) {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet();
    if (sheetName == null) {
      throw StateError('Excel workbook has no default sheet');
    }
    final sheet = excel[sheetName];

    final dateFormat = DateFormat.yMMMd();
    final rangeLabel =
        '${dateFormat.format(statement.fromDate)} – ${dateFormat.format(statement.toDate)}';

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
    setCell(row++, 0, 'SUPPLIER STATEMENT / INVOICE', bold: true);
    setCell(
      row++,
      0,
      'Supplier: ${Formatters.textForExport(statement.supplier.name)} (${statement.supplier.supplierNumber})',
      bold: true,
    );
    setCell(row++, 0, 'Type: ${statement.supplier.supplierType.label}');
    setCell(row++, 0, 'Period: $rangeLabel');
    row++;

    final headers = [
      AppStrings.date,
      'Item / Description',
      AppStrings.reference,
      'Category',
      'Qty',
      'Unit',
      'Unit Price',
      'Purchases (Debit)',
      'Paid (Credit)',
    ];
    for (var col = 0; col < headers.length; col++) {
      setCell(row, col, headers[col], bold: true);
    }
    row++;

    setCell(row, 0, Formatters.exportEmpty);
    setCell(row, 1, 'Opening Balance', bold: true);
    setCell(
      row,
      7,
      statement.openingBalance > 0
          ? Formatters.currencyForExport(statement.openingBalance)
          : '',
    );
    setCell(
      row,
      8,
      statement.openingBalance < 0
          ? Formatters.currencyForExport(statement.openingBalance.abs())
          : '',
    );
    row++;

    for (final line in statement.lines) {
      setCell(row, 0, dateFormat.format(line.date));
      setCell(row, 1, Formatters.textForExport(line.description));
      setCell(row, 2, Formatters.textForExport(line.reference));
      setCell(row, 3, Formatters.textForExport(line.category ?? '—'));
      setCell(
        row,
        4,
        line.quantity != null
            ? line.quantity!.toStringAsFixed(line.quantity! % 1 == 0 ? 0 : 2)
            : '',
      );
      setCell(row, 5, line.unit ?? '');
      setCell(
        row,
        6,
        line.unitPrice != null && line.unitPrice! > 0
            ? Formatters.currencyForExport(line.unitPrice!)
            : '',
      );
      if (line.debit > 0) {
        setCell(row, 7, Formatters.currencyForExport(line.debit));
      }
      if (line.credit > 0) {
        setCell(row, 8, Formatters.currencyForExport(line.credit));
      }
      row++;
    }

    row++;
    setCell(row, 1, 'Total Purchases (Invoiced)', bold: true);
    setCell(row, 7, Formatters.currencyForExport(statement.totalPurchases), bold: true);
    row++;

    setCell(row, 1, 'Total Paid (History)', bold: true);
    setCell(row, 8, Formatters.currencyForExport(statement.totalPaid), bold: true);
    row++;

    setCell(row, 1, 'Remaining Balance Due', bold: true);
    setCell(row, 7, Formatters.currencyForExport(statement.closingBalance), bold: true);

    final encoded = excel.encode();
    if (encoded == null || encoded.isEmpty) {
      throw StateError('Excel encode failed');
    }
    return encoded;
  }
}
