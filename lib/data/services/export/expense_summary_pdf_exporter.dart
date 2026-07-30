import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/expense_summary_report.dart';
import '../../../domain/entities/factory_profile.dart';
import 'pdf_document_theme.dart';
import 'pdf_fonts.dart';

class ExpenseSummaryPdfExporter {
  Future<pw.Document> build({
    required ExpenseSummaryReport report,
    String factoryName = AppStrings.appName,
    FactoryProfile? factoryProfile,
    Uint8List? logoBytes,
  }) async {
    final fonts = await PdfFonts.load();
    final branding = await PdfFactoryBranding.resolve(
      profile: factoryProfile,
      fallbackName: factoryName,
      logoBytes: logoBytes,
    );
    final doc = pw.Document(theme: fonts.theme);
    final monthLabel = DateFormat.yMMMM().format(
      DateTime(report.year, report.month),
    );
    final dateFormat = DateFormat.yMMMd();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: PdfDocumentTheme.pageMargin,
        theme: fonts.theme,
        header: (context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return PdfDocumentTheme.pageHeaderStrip(
            fonts: fonts,
            left: '${branding.factoryName} · EXPENSE SUMMARY',
            right: monthLabel,
          );
        },
        footer: (context) => PdfDocumentTheme.pageFooterStrip(
          fonts: fonts,
          factoryName: branding.factoryName,
          context: context,
        ),
        build: (context) => [
          PdfDocumentTheme.factoryHeader(
            fonts: fonts,
            branding: branding,
            documentTitle: 'EXPENSE SUMMARY',
            metaRows: [
              (label: 'Period:', value: monthLabel),
              (
                label: 'Total:',
                value: Formatters.currencyForExport(report.totalExpenses),
              ),
            ],
          ),
          PdfDocumentTheme.divider(),
          PdfDocumentTheme.detailCard(
            fonts: fonts,
            title: AppStrings.expensesByCategory,
            rows: [
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
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            AppStrings.expenseDetails.toUpperCase(),
            style: PdfDocumentTheme.sectionTitleStyle(fonts),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfDocumentTheme.borderLight,
              width: 0.8,
            ),
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
              for (var i = 0; i < report.lines.length; i++)
                PdfDocumentTheme.tableDataRow(
                  fonts,
                  [
                    dateFormat.format(report.lines[i].expense.expenseDate),
                    Formatters.textForExport(
                      report.lines[i].expense.expenseNumber,
                    ),
                    report.lines[i].category.label,
                    Formatters.textForExport(
                      report.lines[i].expense.description,
                    ),
                    Formatters.currencyForExport(report.lines[i].amount),
                  ],
                  index: i,
                ),
            ],
          ),
        ],
      ),
    );

    return doc;
  }
}
