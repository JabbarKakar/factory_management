import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/monthly_pl_report.dart';
import 'pdf_document_theme.dart';
import 'pdf_fonts.dart';

class PlReportPdfExporter {
  Future<pw.Document> build({
    required MonthlyPlReport report,
    String factoryName = AppStrings.appName,
  }) async {
    final fonts = await PdfFonts.load();
    final doc = pw.Document();
    final monthLabel = DateFormat.yMMMM().format(
      DateTime(report.year, report.month),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: fonts.theme,
        build: (context) => [
          PdfDocumentTheme.header(
            fonts: fonts,
            title: factoryName,
            subtitle: AppStrings.monthlyPlReport,
            rightLabel: monthLabel,
          ),
          PdfDocumentTheme.divider(),
          pw.Text(
            AppStrings.revenue,
            style: PdfDocumentTheme.bodyStyle(fonts, bold: true),
          ),
          pw.SizedBox(height: 8),
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
          PdfDocumentTheme.divider(),
          pw.Text(
            AppStrings.expenses,
            style: PdfDocumentTheme.bodyStyle(fonts, bold: true),
          ),
          pw.SizedBox(height: 8),
          if (report.expenseLines.isEmpty)
            pw.Text(
              AppStrings.noExpensesThisMonth,
              style: PdfDocumentTheme.subtitleStyle(fonts),
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
          PdfDocumentTheme.divider(),
          PdfDocumentTheme.summaryRow(
            fonts,
            report.netProfit >= 0 ? AppStrings.netProfit : AppStrings.netLoss,
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
          pw.SizedBox(height: 16),
          pw.Text(
            AppStrings.plReportFootnote,
            style: PdfDocumentTheme.subtitleStyle(fonts, size: 9),
          ),
        ],
      ),
    );

    return doc;
  }
}
