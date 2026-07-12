import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/job_work_collection.dart';
import 'pdf_document_theme.dart';
import 'pdf_fonts.dart';

class JobWorkCollectionSlipPdfExporter {
  Future<pw.Document> buildCollectionSlipPdf({
    required JobWorkCollection collection,
    String factoryName = AppStrings.appName,
  }) async {
    final fonts = await PdfFonts.load();
    final doc = pw.Document();
    final dateFormat = DateFormat.yMMMd();
    final collectedDate = dateFormat.format(collection.collectedAt);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: fonts.theme,
        build: (context) => [
          PdfDocumentTheme.header(
            fonts: fonts,
            title: factoryName,
            subtitle: AppStrings.collectionSlipTitle,
            rightLabel: collection.collectionNumber,
          ),
          PdfDocumentTheme.divider(),
          pw.Text(
            Formatters.textForExport(collection.customerName),
            style: PdfDocumentTheme.titleStyle(fonts, size: 14),
          ),
          pw.SizedBox(height: 8),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.slipNumber,
            Formatters.textForExport(collection.collectionNumber),
          ),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.jobWorkNumber,
            Formatters.textForExport(collection.jobWorkNumber),
          ),
          if (collection.loadNumber != null &&
              collection.loadNumber!.trim().isNotEmpty)
            PdfDocumentTheme.summaryRow(
              fonts,
              AppStrings.load,
              Formatters.textForExport(collection.loadNumber!),
            ),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.collectionDate,
            collectedDate,
          ),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.statusLabel,
            collection.status.label,
          ),
          if (collection.receiverName != null &&
              collection.receiverName!.trim().isNotEmpty)
            PdfDocumentTheme.summaryRow(
              fonts,
              AppStrings.receiverName,
              Formatters.textForExport(collection.receiverName!),
            ),
          PdfDocumentTheme.divider(),
          pw.Text(
            AppStrings.itemsCollected,
            style: PdfDocumentTheme.bodyStyle(fonts, bold: true),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfDocumentTheme.border),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(1.4),
              2: pw.FlexColumnWidth(1.6),
            },
            children: [
              PdfDocumentTheme.tableHeaderRow(fonts, [
                AppStrings.stockSize,
                AppStrings.collectPiecesShort,
                AppStrings.collectSquareFeetShort,
              ]),
              for (final item in collection.lineItems)
                PdfDocumentTheme.tableDataRow(fonts, [
                  Formatters.textForExport(item.displayLabel),
                  '${item.pieces}',
                  item.squareFeet.toStringAsFixed(2),
                ]),
            ],
          ),
          pw.SizedBox(height: 12),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.totalPieces,
            '${collection.totalPieces}',
          ),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.totalSquareFeet,
            collection.totalSquareFeet.toStringAsFixed(2),
          ),
          if (collection.notes != null &&
              collection.notes!.trim().isNotEmpty) ...[
            PdfDocumentTheme.divider(),
            pw.Text(
              AppStrings.notes,
              style: PdfDocumentTheme.bodyStyle(fonts, bold: true),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              Formatters.textForExport(collection.notes!),
              style: PdfDocumentTheme.bodyStyle(fonts),
            ),
          ],
          PdfDocumentTheme.divider(),
          pw.SizedBox(height: 24),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: double.infinity,
                      height: 28,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfDocumentTheme.border),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      AppStrings.factorySignature,
                      style: PdfDocumentTheme.subtitleStyle(fonts),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: double.infinity,
                      height: 28,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfDocumentTheme.border),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      collection.receiverName != null &&
                              collection.receiverName!.trim().isNotEmpty
                          ? '${AppStrings.receiverName}: ${collection.receiverName}'
                          : AppStrings.customerSignature,
                      style: PdfDocumentTheme.subtitleStyle(fonts),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return doc;
  }
}
