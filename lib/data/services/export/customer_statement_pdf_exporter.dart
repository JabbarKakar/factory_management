import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/customer_statement.dart';
import 'pdf_document_theme.dart';

class CustomerStatementPdfExporter {
  Future<pw.Document> build({
    required CustomerStatement statement,
    String factoryName = AppStrings.appName,
  }) async {
    final doc = pw.Document();
    final dateFormat = DateFormat.yMMMd();
    final rangeLabel =
        '${dateFormat.format(statement.fromDate)} – ${dateFormat.format(statement.toDate)}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          PdfDocumentTheme.header(
            title: factoryName,
            subtitle: AppStrings.customerStatement,
            rightLabel: rangeLabel,
          ),
          PdfDocumentTheme.divider(),
          pw.Text(
            statement.customer.name,
            style: PdfDocumentTheme.titleStyle(size: 14),
          ),
          if (statement.customer.phone.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              statement.customer.phone,
              style: PdfDocumentTheme.subtitleStyle(),
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
              PdfDocumentTheme.tableHeaderRow([
                AppStrings.date,
                AppStrings.description,
                AppStrings.reference,
                AppStrings.debit,
                AppStrings.credit,
              ]),
              PdfDocumentTheme.tableDataRow([
                '—',
                AppStrings.openingBalance,
                '',
                Formatters.currencyPkr(statement.openingBalance),
                '',
              ]),
              for (final line in statement.lines)
                PdfDocumentTheme.tableDataRow([
                  dateFormat.format(line.date),
                  line.description,
                  line.reference,
                  line.debit > 0 ? Formatters.currencyPkr(line.debit) : '',
                  line.credit > 0 ? Formatters.currencyPkr(line.credit) : '',
                ]),
              PdfDocumentTheme.tableDataRow([
                '—',
                AppStrings.closingBalance,
                '',
                Formatters.currencyPkr(statement.closingBalance),
                '',
              ]),
            ],
          ),
          pw.SizedBox(height: 16),
          PdfDocumentTheme.summaryRow(
            AppStrings.totalDebits,
            Formatters.currencyPkr(statement.totalDebits),
          ),
          PdfDocumentTheme.summaryRow(
            AppStrings.totalCredits,
            Formatters.currencyPkr(statement.totalCredits),
          ),
          PdfDocumentTheme.summaryRow(
            AppStrings.closingBalance,
            Formatters.currencyPkr(statement.closingBalance),
            bold: true,
          ),
        ],
      ),
    );

    return doc;
  }
}
