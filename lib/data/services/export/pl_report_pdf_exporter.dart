import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/monthly_pl_report.dart';
import 'pdf_document_theme.dart';

class PlReportPdfExporter {
  Future<pw.Document> build({
    required MonthlyPlReport report,
    String factoryName = AppStrings.appName,
  }) async {
    final doc = pw.Document();
    final monthLabel = DateFormat.yMMMM().format(
      DateTime(report.year, report.month),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          PdfDocumentTheme.header(
            title: factoryName,
            subtitle: AppStrings.monthlyPlReport,
            rightLabel: monthLabel,
          ),
          PdfDocumentTheme.divider(),
          pw.Text(AppStrings.revenue, style: PdfDocumentTheme.bodyStyle(bold: true)),
          pw.SizedBox(height: 8),
          PdfDocumentTheme.summaryRow(
            AppStrings.salesRevenue,
            Formatters.currencyPkr(report.salesRevenue),
          ),
          PdfDocumentTheme.summaryRow(
            AppStrings.jobWorkRevenue,
            Formatters.currencyPkr(report.jobWorkRevenue),
          ),
          PdfDocumentTheme.summaryRow(
            AppStrings.totalRevenue,
            Formatters.currencyPkr(report.totalRevenue),
            bold: true,
          ),
          PdfDocumentTheme.divider(),
          pw.Text(AppStrings.expenses, style: PdfDocumentTheme.bodyStyle(bold: true)),
          pw.SizedBox(height: 8),
          if (report.expenseLines.isEmpty)
            pw.Text(
              AppStrings.noExpensesThisMonth,
              style: PdfDocumentTheme.subtitleStyle(),
            )
          else
            for (final line in report.expenseLines)
              PdfDocumentTheme.summaryRow(
                line.category.label,
                Formatters.currencyPkr(line.amount),
              ),
          PdfDocumentTheme.summaryRow(
            AppStrings.totalExpenses,
            Formatters.currencyPkr(report.totalExpenses),
            bold: true,
          ),
          PdfDocumentTheme.divider(),
          PdfDocumentTheme.summaryRow(
            report.netProfit >= 0 ? AppStrings.netProfit : AppStrings.netLoss,
            Formatters.currencyPkr(report.netProfit.abs()),
            bold: true,
          ),
          if (report.totalRevenue > 0)
            PdfDocumentTheme.summaryRow(
              AppStrings.netProfitMargin,
              '${report.netProfitMargin.toStringAsFixed(1)}%',
              bold: true,
            ),
          pw.SizedBox(height: 16),
          pw.Text(
            AppStrings.plReportFootnote,
            style: PdfDocumentTheme.subtitleStyle(size: 9),
          ),
        ],
      ),
    );

    return doc;
  }
}
