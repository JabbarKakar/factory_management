import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/expense_summary_report.dart';
import 'pdf_document_theme.dart';
import 'pdf_fonts.dart';

class ExpenseSummaryPdfExporter {
  Future<pw.Document> build({
    required ExpenseSummaryReport report,
    String factoryName = AppStrings.appName,
  }) async {
    final fonts = await PdfFonts.load();
    final doc = pw.Document();
    final monthLabel = DateFormat.yMMMM().format(
      DateTime(report.year, report.month),
    );
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
            subtitle: AppStrings.expenseSummaryReport,
            rightLabel: monthLabel,
          ),
          PdfDocumentTheme.divider(),
          pw.Text(
            AppStrings.expensesByCategory,
            style: PdfDocumentTheme.bodyStyle(fonts, bold: true),
          ),
          pw.SizedBox(height: 8),
          for (final entry in report.categoryTotals)
            PdfDocumentTheme.summaryRow(
              fonts,
              entry.$1.label,
              Formatters.currencyForExport(entry.$2),
            ),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.totalExpenses,
            Formatters.currencyForExport(report.totalExpenses),
            bold: true,
          ),
          PdfDocumentTheme.divider(),
          pw.Text(
            AppStrings.expenseDetails,
            style: PdfDocumentTheme.bodyStyle(fonts, bold: true),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfDocumentTheme.border),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              PdfDocumentTheme.tableHeaderRow(
                fonts,
                [
                  AppStrings.date,
                  AppStrings.expenseNumber,
                  AppStrings.expenseCategory,
                  AppStrings.description,
                  AppStrings.amount,
                ],
              ),
              for (final line in report.lines)
                PdfDocumentTheme.tableDataRow(fonts, [
                  dateFormat.format(line.expense.expenseDate),
                  Formatters.textForExport(line.expense.expenseNumber),
                  line.category.label,
                  Formatters.textForExport(line.expense.description),
                  Formatters.currencyForExport(line.amount),
                ]),
            ],
          ),
        ],
      ),
    );

    return doc;
  }
}
