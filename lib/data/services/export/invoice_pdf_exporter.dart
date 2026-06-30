import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/job_work_invoice.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/sales_invoice.dart';
import 'pdf_document_theme.dart';
import 'pdf_fonts.dart';

class InvoicePdfExporter {
  Future<pw.Document> buildSalesInvoicePdf({
    required SalesInvoice invoice,
    required List<Payment> payments,
    String factoryName = AppStrings.appName,
  }) async {
    final fonts = await PdfFonts.load();
    final doc = pw.Document();
    final dateFormat = DateFormat.yMMMd();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: fonts.theme,
        build: (context) => [
          PdfDocumentTheme.header(
            fonts: fonts,
            title: factoryName,
            subtitle: AppStrings.salesInvoice,
            rightLabel: invoice.invoiceNumber,
          ),
          PdfDocumentTheme.divider(),
          pw.Text(
            Formatters.textForExport(invoice.customerName),
            style: PdfDocumentTheme.titleStyle(fonts, size: 14),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${AppStrings.orderNumber}: ${Formatters.textForExport(invoice.orderNumber)}',
            style: PdfDocumentTheme.subtitleStyle(fonts),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${AppStrings.date}: ${dateFormat.format(invoice.createdAt)}',
            style: PdfDocumentTheme.subtitleStyle(fonts),
          ),
          PdfDocumentTheme.divider(),
          pw.Text(
            AppStrings.lineItems,
            style: PdfDocumentTheme.bodyStyle(fonts, bold: true),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfDocumentTheme.border),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              PdfDocumentTheme.tableHeaderRow(
                fonts,
                [AppStrings.description, AppStrings.amount],
              ),
              for (final item in invoice.lineItems)
                PdfDocumentTheme.tableDataRow(fonts, [
                  Formatters.textForExport(item.description),
                  item.amount > 0
                      ? Formatters.currencyForExport(item.amount)
                      : Formatters.exportEmpty,
                ]),
            ],
          ),
          pw.SizedBox(height: 16),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.invoiceTotal,
            Formatters.currencyForExport(invoice.totalAmount),
          ),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.amountPaid,
            Formatters.currencyForExport(invoice.paidAmount),
          ),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.amountDue,
            Formatters.currencyForExport(invoice.dueAmount),
            bold: true,
          ),
          if (invoice.dueDate != null)
            PdfDocumentTheme.summaryRow(
              fonts,
              AppStrings.paymentDueDate,
              dateFormat.format(invoice.dueDate!),
            ),
          if (payments.isNotEmpty) ...[
            PdfDocumentTheme.divider(),
            pw.Text(
              AppStrings.paymentHistory,
              style: PdfDocumentTheme.bodyStyle(fonts, bold: true),
            ),
            pw.SizedBox(height: 8),
            for (final payment in payments)
              PdfDocumentTheme.summaryRow(
                fonts,
                '${dateFormat.format(payment.paymentDate)} - ${payment.method.label}',
                Formatters.currencyForExport(payment.amount),
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
    final fonts = await PdfFonts.load();
    final doc = pw.Document();
    final dateFormat = DateFormat.yMMMd();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: fonts.theme,
        build: (context) => [
          PdfDocumentTheme.header(
            fonts: fonts,
            title: factoryName,
            subtitle: AppStrings.jobWorkInvoice,
            rightLabel: invoice.invoiceNumber,
          ),
          PdfDocumentTheme.divider(),
          pw.Text(
            Formatters.textForExport(invoice.customerName),
            style: PdfDocumentTheme.titleStyle(fonts, size: 14),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${AppStrings.jobWorkNumber}: ${Formatters.textForExport(invoice.jobWorkNumber)}',
            style: PdfDocumentTheme.subtitleStyle(fonts),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${AppStrings.date}: ${dateFormat.format(invoice.createdAt)}',
            style: PdfDocumentTheme.subtitleStyle(fonts),
          ),
          if (invoice.mineLocation != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              '${AppStrings.mineLocation}: ${Formatters.textForExport(invoice.mineLocation!)}',
              style: PdfDocumentTheme.subtitleStyle(fonts),
            ),
          ],
          if (invoice.mineOwner != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              '${AppStrings.mineOwner}: ${Formatters.textForExport(invoice.mineOwner!)}',
              style: PdfDocumentTheme.subtitleStyle(fonts),
            ),
          ],
          PdfDocumentTheme.divider(),
          pw.Text(
            AppStrings.lineItems,
            style: PdfDocumentTheme.bodyStyle(fonts, bold: true),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfDocumentTheme.border),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              PdfDocumentTheme.tableHeaderRow(
                fonts,
                [AppStrings.description, AppStrings.amount],
              ),
              for (final item in invoice.lineItems)
                PdfDocumentTheme.tableDataRow(fonts, [
                  Formatters.textForExport(item.description),
                  item.amount > 0
                      ? Formatters.currencyForExport(item.amount)
                      : Formatters.exportEmpty,
                ]),
            ],
          ),
          pw.SizedBox(height: 16),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.invoiceTotal,
            Formatters.currencyForExport(invoice.totalAmount),
          ),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.amountPaid,
            Formatters.currencyForExport(invoice.paidAmount),
          ),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.amountDue,
            Formatters.currencyForExport(invoice.dueAmount),
            bold: true,
          ),
          if (invoice.dueDate != null)
            PdfDocumentTheme.summaryRow(
              fonts,
              AppStrings.paymentDueDate,
              dateFormat.format(invoice.dueDate!),
            ),
          if (payments.isNotEmpty) ...[
            PdfDocumentTheme.divider(),
            pw.Text(
              AppStrings.paymentHistory,
              style: PdfDocumentTheme.bodyStyle(fonts, bold: true),
            ),
            pw.SizedBox(height: 8),
            for (final payment in payments)
              PdfDocumentTheme.summaryRow(
                fonts,
                '${dateFormat.format(payment.paymentDate)} - ${payment.method.label}',
                Formatters.currencyForExport(payment.amount),
              ),
          ],
        ],
      ),
    );

    return doc;
  }
}
