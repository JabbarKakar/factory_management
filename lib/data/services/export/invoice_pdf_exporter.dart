import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/job_work_invoice.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/sales_invoice.dart';
import 'pdf_document_theme.dart';

class InvoicePdfExporter {
  Future<pw.Document> buildSalesInvoicePdf({
    required SalesInvoice invoice,
    required List<Payment> payments,
    String factoryName = AppStrings.appName,
  }) async {
    final doc = pw.Document();
    final dateFormat = DateFormat.yMMMd();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          PdfDocumentTheme.header(
            title: factoryName,
            subtitle: AppStrings.salesInvoice,
            rightLabel: invoice.invoiceNumber,
          ),
          PdfDocumentTheme.divider(),
          pw.Text(invoice.customerName, style: PdfDocumentTheme.titleStyle(size: 14)),
          pw.SizedBox(height: 4),
          pw.Text(
            '${AppStrings.orderNumber}: ${invoice.orderNumber}',
            style: PdfDocumentTheme.subtitleStyle(),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${AppStrings.date}: ${dateFormat.format(invoice.createdAt)}',
            style: PdfDocumentTheme.subtitleStyle(),
          ),
          PdfDocumentTheme.divider(),
          pw.Text(AppStrings.lineItems, style: PdfDocumentTheme.bodyStyle(bold: true)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfDocumentTheme.border),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              PdfDocumentTheme.tableHeaderRow([AppStrings.description, AppStrings.amount]),
              for (final item in invoice.lineItems)
                PdfDocumentTheme.tableDataRow([
                  item.description,
                  item.amount > 0 ? Formatters.currencyPkr(item.amount) : '—',
                ]),
            ],
          ),
          pw.SizedBox(height: 16),
          PdfDocumentTheme.summaryRow(
            AppStrings.invoiceTotal,
            Formatters.currencyPkr(invoice.totalAmount),
          ),
          PdfDocumentTheme.summaryRow(
            AppStrings.amountPaid,
            Formatters.currencyPkr(invoice.paidAmount),
          ),
          PdfDocumentTheme.summaryRow(
            AppStrings.amountDue,
            Formatters.currencyPkr(invoice.dueAmount),
            bold: true,
          ),
          if (invoice.dueDate != null)
            PdfDocumentTheme.summaryRow(
              AppStrings.paymentDueDate,
              dateFormat.format(invoice.dueDate!),
            ),
          if (payments.isNotEmpty) ...[
            PdfDocumentTheme.divider(),
            pw.Text(
              AppStrings.paymentHistory,
              style: PdfDocumentTheme.bodyStyle(bold: true),
            ),
            pw.SizedBox(height: 8),
            for (final payment in payments)
              PdfDocumentTheme.summaryRow(
                '${dateFormat.format(payment.paymentDate)} · ${payment.method.label}',
                Formatters.currencyPkr(payment.amount),
              ),
          ],
        ],
      ),
    );

    return doc;
  }

  Future<pw.Document> buildJobWorkInvoicePdf({
    required JobWorkInvoice invoice,
    required List<Payment> payments,
    String factoryName = AppStrings.appName,
  }) async {
    final doc = pw.Document();
    final dateFormat = DateFormat.yMMMd();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          PdfDocumentTheme.header(
            title: factoryName,
            subtitle: AppStrings.jobWorkInvoice,
            rightLabel: invoice.invoiceNumber,
          ),
          PdfDocumentTheme.divider(),
          pw.Text(invoice.customerName, style: PdfDocumentTheme.titleStyle(size: 14)),
          pw.SizedBox(height: 4),
          pw.Text(
            '${AppStrings.jobWorkNumber}: ${invoice.jobWorkNumber}',
            style: PdfDocumentTheme.subtitleStyle(),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${AppStrings.date}: ${dateFormat.format(invoice.createdAt)}',
            style: PdfDocumentTheme.subtitleStyle(),
          ),
          PdfDocumentTheme.divider(),
          pw.Text(AppStrings.lineItems, style: PdfDocumentTheme.bodyStyle(bold: true)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfDocumentTheme.border),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              PdfDocumentTheme.tableHeaderRow([AppStrings.description, AppStrings.amount]),
              for (final item in invoice.lineItems)
                PdfDocumentTheme.tableDataRow([
                  item.description,
                  item.amount > 0 ? Formatters.currencyPkr(item.amount) : '—',
                ]),
            ],
          ),
          pw.SizedBox(height: 16),
          PdfDocumentTheme.summaryRow(
            AppStrings.invoiceTotal,
            Formatters.currencyPkr(invoice.totalAmount),
          ),
          PdfDocumentTheme.summaryRow(
            AppStrings.amountPaid,
            Formatters.currencyPkr(invoice.paidAmount),
          ),
          PdfDocumentTheme.summaryRow(
            AppStrings.amountDue,
            Formatters.currencyPkr(invoice.dueAmount),
            bold: true,
          ),
          if (invoice.dueDate != null)
            PdfDocumentTheme.summaryRow(
              AppStrings.paymentDueDate,
              dateFormat.format(invoice.dueDate!),
            ),
          if (payments.isNotEmpty) ...[
            PdfDocumentTheme.divider(),
            pw.Text(
              AppStrings.paymentHistory,
              style: PdfDocumentTheme.bodyStyle(bold: true),
            ),
            pw.SizedBox(height: 8),
            for (final payment in payments)
              PdfDocumentTheme.summaryRow(
                '${dateFormat.format(payment.paymentDate)} · ${payment.method.label}',
                Formatters.currencyPkr(payment.amount),
              ),
          ],
        ],
      ),
    );

    return doc;
  }
}
