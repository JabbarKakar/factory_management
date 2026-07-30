import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/factory_profile.dart';
import '../../../domain/entities/monthly_pl_report.dart';
import 'pdf_document_theme.dart';
import 'pdf_fonts.dart';

class PlReportPdfExporter {
  Future<pw.Document> build({
    required MonthlyPlReport report,
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
    final isProfit = report.netProfit >= 0;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: PdfDocumentTheme.pageMargin,
        theme: fonts.theme,
        header: (context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return PdfDocumentTheme.pageHeaderStrip(
            fonts: fonts,
            left: '${branding.factoryName} · MONTHLY P&L',
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
            documentTitle: 'MONTHLY P&L',
            metaRows: [
              (label: 'Period:', value: monthLabel),
              (
                label: isProfit ? 'Net Profit:' : 'Net Loss:',
                value: Formatters.currencyForExport(report.netProfit.abs()),
              ),
            ],
            statusLabel: isProfit ? 'NET PROFIT' : 'NET LOSS',
            statusPositive: isProfit,
          ),
          PdfDocumentTheme.divider(),
          PdfDocumentTheme.detailCard(
            fonts: fonts,
            title: AppStrings.revenue,
            rows: [
              PdfDocumentTheme.summaryRow(
                fonts,
                AppStrings.salesRevenue,
                Formatters.currencyForExport(report.salesRevenue),
              ),
              PdfDocumentTheme.summaryRow(
                fonts,
                AppStrings.jobWorkRevenue,
                Formatters.currencyForExport(report.jobWorkRevenue),
              ),
              PdfDocumentTheme.summaryRow(
                fonts,
                AppStrings.totalRevenue,
                Formatters.currencyForExport(report.totalRevenue),
                bold: true,
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          PdfDocumentTheme.detailCard(
            fonts: fonts,
            title: AppStrings.expenses,
            rows: [
              if (report.expenseLines.isEmpty)
                pw.Text(
                  AppStrings.noExpensesThisMonth,
                  style: PdfDocumentTheme.subtitleStyle(fonts, size: 8),
                )
              else
                for (final line in report.expenseLines)
                  PdfDocumentTheme.summaryRow(
                    fonts,
                    line.category.label,
                    Formatters.currencyForExport(line.amount),
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
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfDocumentTheme.goldBg,
              border: pw.Border.all(
                color: PdfDocumentTheme.borderLight,
                width: 0.8,
              ),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              children: [
                PdfDocumentTheme.summaryRow(
                  fonts,
                  isProfit ? AppStrings.netProfit : AppStrings.netLoss,
                  Formatters.currencyForExport(report.netProfit.abs()),
                  bold: true,
                ),
                if (report.totalRevenue > 0)
                  PdfDocumentTheme.summaryRow(
                    fonts,
                    AppStrings.netProfitMargin,
                    '${report.netProfitMargin.toStringAsFixed(1)}%',
                    bold: true,
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            AppStrings.plReportFootnote,
            style: PdfDocumentTheme.subtitleStyle(fonts, size: 7.5),
          ),
          pw.SizedBox(height: 18),
          PdfDocumentTheme.authorizationBlock(
            fonts: fonts,
            branding: branding,
            preparedLabel: 'Prepared By',
            authorizedLabel: 'Authorized Signature & Stamp',
          ),
        ],
      ),
    );

    return doc;
  }
}
