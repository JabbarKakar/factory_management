import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/customer_statement.dart';
import 'pdf_document_theme.dart';
import 'pdf_fonts.dart';

class CustomerStatementPdfExporter {
  Future<pw.Document> build({
    required CustomerStatement statement,
    String factoryName = AppStrings.appName,
  }) async {
    final fonts = await PdfFonts.load();
    final doc = pw.Document();
    final dateFormat = DateFormat.yMMMd();
    final rangeLabel =
        '${dateFormat.format(statement.fromDate)} - ${dateFormat.format(statement.toDate)}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: fonts.theme,
        build: (context) => [
          PdfDocumentTheme.header(
            fonts: fonts,
            title: factoryName,
            subtitle: AppStrings.customerStatement,
            rightLabel: rangeLabel,
          ),
          PdfDocumentTheme.divider(),
          pw.Text(
            Formatters.textForExport(statement.customer.name),
            style: PdfDocumentTheme.titleStyle(fonts, size: 14),
          ),
          if (statement.customer.phone.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              Formatters.textForExport(statement.customer.phone),
              style: PdfDocumentTheme.subtitleStyle(fonts),
            ),
          ],
          PdfDocumentTheme.divider(),
          pw.Table(
            border: pw.TableBorder.all(color: PdfDocumentTheme.border),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              PdfDocumentTheme.tableHeaderRow(fonts, [
                AppStrings.date,
                AppStrings.description,
                AppStrings.reference,
                AppStrings.debit,
                AppStrings.credit,
              ]),
              PdfDocumentTheme.tableDataRow(fonts, [
                Formatters.exportEmpty,
                AppStrings.openingBalance,
                '',
                Formatters.currencyForExport(statement.openingBalance),
                '',
              ]),
              for (final line in statement.lines)
                PdfDocumentTheme.tableDataRow(fonts, [
                  dateFormat.format(line.date),
                  Formatters.textForExport(line.description),
                  Formatters.textForExport(line.reference),
                  line.debit > 0
                      ? Formatters.currencyForExport(line.debit)
                      : '',
                  line.credit > 0
                      ? Formatters.currencyForExport(line.credit)
                      : '',
                ]),
              PdfDocumentTheme.tableDataRow(fonts, [
                Formatters.exportEmpty,
                AppStrings.closingBalance,
                '',
                Formatters.currencyForExport(statement.closingBalance),
                '',
              ]),
            ],
          ),
          pw.SizedBox(height: 16),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.totalDebits,
            Formatters.currencyForExport(statement.totalDebits),
          ),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.totalCredits,
            Formatters.currencyForExport(statement.totalCredits),
          ),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.closingBalance,
            Formatters.currencyForExport(statement.closingBalance),
            bold: true,
          ),
        ],
      ),
    );

    return doc;
  }
}
