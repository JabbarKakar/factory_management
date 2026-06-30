import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/job_work_invoice.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/sales_invoice.dart';

class InvoiceExcelExporter {
  List<int> buildSalesInvoice({
    required SalesInvoice invoice,
    required List<Payment> payments,
    String factoryName = AppStrings.appName,
  }) {
    return _build(
      factoryName: factoryName,
      documentTitle: AppStrings.salesInvoice,
      documentNumber: invoice.invoiceNumber,
      customerName: invoice.customerName,
      referenceLabel: AppStrings.orderNumber,
      referenceValue: invoice.orderNumber,
      invoiceDate: invoice.createdAt,
      dueDate: invoice.dueDate,
      lineItems: invoice.lineItems
          .map((item) => (item.description, item.amount))
          .toList(),
      totalAmount: invoice.totalAmount,
      paidAmount: invoice.paidAmount,
      dueAmount: invoice.dueAmount,
      payments: payments,
    );
  }

  List<int> buildJobWorkInvoice({
    required JobWorkInvoice invoice,
    required List<Payment> payments,
    String factoryName = AppStrings.appName,
  }) {
    return _build(
      factoryName: factoryName,
      documentTitle: AppStrings.jobWorkInvoice,
      documentNumber: invoice.invoiceNumber,
      customerName: invoice.customerName,
      referenceLabel: AppStrings.jobWorkNumber,
      referenceValue: invoice.jobWorkNumber,
      invoiceDate: invoice.createdAt,
      dueDate: invoice.dueDate,
      lineItems: invoice.lineItems
          .map((item) => (item.description, item.amount))
          .toList(),
      totalAmount: invoice.totalAmount,
      paidAmount: invoice.paidAmount,
      dueAmount: invoice.dueAmount,
      payments: payments,
      extraDetails: [
        if (invoice.mineLocation != null)
          (AppStrings.mineLocation, invoice.mineLocation!),
        if (invoice.mineOwner != null)
          (AppStrings.mineOwner, invoice.mineOwner!),
      ],
    );
  }

  List<int> _build({
    required String factoryName,
    required String documentTitle,
    required String documentNumber,
    required String customerName,
    required String referenceLabel,
    required String referenceValue,
    required DateTime invoiceDate,
    required DateTime? dueDate,
    required List<(String description, double amount)> lineItems,
    required double totalAmount,
    required double paidAmount,
    required double dueAmount,
    required List<Payment> payments,
    List<(String label, String value)> extraDetails = const [],
  }) {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet();
    if (sheetName == null) {
      throw StateError('Excel workbook has no default sheet');
    }
    final sheet = excel[sheetName];
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
    setCell(row++, 0, Formatters.textForExport(factoryName), bold: true);
    setCell(row++, 0, documentTitle, bold: true);
    setCell(row++, 0, documentNumber);
    row++;
    setCell(row++, 0, Formatters.textForExport(customerName), bold: true);
    setCell(
      row++,
      0,
      '$referenceLabel: ${Formatters.textForExport(referenceValue)}',
    );
    setCell(row++, 0, '${AppStrings.date}: ${dateFormat.format(invoiceDate)}');
    if (dueDate != null) {
      setCell(
        row++,
        0,
        '${AppStrings.paymentDueDate}: ${dateFormat.format(dueDate)}',
      );
    }
    for (final detail in extraDetails) {
      setCell(
        row++,
        0,
        '${detail.$1}: ${Formatters.textForExport(detail.$2)}',
      );
    }
    row++;

    setCell(row++, 0, AppStrings.description, bold: true);
    setCell(row - 1, 1, AppStrings.amount, bold: true);
    for (final item in lineItems) {
      setCell(row, 0, Formatters.textForExport(item.$1));
      setCell(
        row++,
        1,
        item.$2 > 0 ? Formatters.currencyForExport(item.$2) : Formatters.exportEmpty,
      );
    }
    row++;

    setCell(row, 0, AppStrings.invoiceTotal);
    setCell(row++, 1, Formatters.currencyForExport(totalAmount), bold: true);
    setCell(row, 0, AppStrings.amountPaid);
    setCell(row++, 1, Formatters.currencyForExport(paidAmount));
    setCell(row, 0, AppStrings.amountDue);
    setCell(row++, 1, Formatters.currencyForExport(dueAmount), bold: true);

    if (payments.isNotEmpty) {
      row++;
      setCell(row++, 0, AppStrings.paymentHistory, bold: true);
      for (final payment in payments) {
        setCell(
          row,
          0,
          '${dateFormat.format(payment.paymentDate)} - ${payment.method.label}',
        );
        setCell(row++, 1, Formatters.currencyForExport(payment.amount));
      }
    }

    final encoded = excel.encode();
    if (encoded == null || encoded.isEmpty) {
      throw StateError('Excel encode failed');
    }
    return encoded;
  }
}
