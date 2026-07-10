import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/delivery.dart';
import 'pdf_document_theme.dart';
import 'pdf_fonts.dart';

class DeliveryChallanPdfExporter {
  Future<pw.Document> buildDeliveryChallanPdf({
    required Delivery delivery,
    String factoryName = AppStrings.appName,
  }) async {
    final fonts = await PdfFonts.load();
    final doc = pw.Document();
    final dateFormat = DateFormat.yMMMd();
    final scheduledDate = dateFormat.format(delivery.scheduledDate);
    final actualDate = delivery.actualDeliveryDate == null
        ? null
        : dateFormat.format(delivery.actualDeliveryDate!);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: fonts.theme,
        build: (context) => [
          PdfDocumentTheme.header(
            fonts: fonts,
            title: factoryName,
            subtitle: AppStrings.deliveryChallanTitle,
            rightLabel: delivery.deliveryNumber,
          ),
          PdfDocumentTheme.divider(),
          pw.Text(
            Formatters.textForExport(delivery.customerName),
            style: PdfDocumentTheme.titleStyle(fonts, size: 14),
          ),
          pw.SizedBox(height: 8),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.challanNumber,
            Formatters.textForExport(delivery.deliveryNumber),
          ),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.orderNumber,
            Formatters.textForExport(delivery.salesOrderNumber),
          ),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.scheduledDateLabel,
            scheduledDate,
          ),
          if (actualDate != null)
            PdfDocumentTheme.summaryRow(
              fonts,
              AppStrings.actualDispatchDate,
              actualDate,
            ),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.deliveryAddress,
            Formatters.textForExport(delivery.deliveryAddress),
          ),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.statusLabel,
            delivery.status.label,
          ),
          PdfDocumentTheme.divider(),
          pw.Text(
            AppStrings.itemsToDeliver,
            style: PdfDocumentTheme.bodyStyle(fonts, bold: true),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfDocumentTheme.border),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(1.2),
              3: pw.FlexColumnWidth(1.2),
              4: pw.FlexColumnWidth(1.2),
            },
            children: [
              PdfDocumentTheme.tableHeaderRow(fonts, [
                AppStrings.stockDescription,
                AppStrings.scheduledPiecesShort,
                AppStrings.scheduledSquareFeetShort,
                AppStrings.dispatchPiecesShort,
                AppStrings.dispatchSquareFeetShort,
              ]),
              for (final item in delivery.lineItems)
                PdfDocumentTheme.tableDataRow(fonts, [
                  Formatters.textForExport(item.displayLabel),
                  '${item.pieces}',
                  item.squareFeet.toStringAsFixed(2),
                  '${item.effectivePieces}',
                  item.effectiveSquareFeet.toStringAsFixed(2),
                ]),
            ],
          ),
          pw.SizedBox(height: 12),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.totalPieces,
            '${delivery.totalPieces}',
          ),
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.totalSquareFeet,
            delivery.totalSquareFeet.toStringAsFixed(2),
          ),
          if (delivery.status.isTerminal) ...[
            PdfDocumentTheme.summaryRow(
              fonts,
              AppStrings.piecesDispatched,
              '${delivery.effectivePieces}',
            ),
            PdfDocumentTheme.summaryRow(
              fonts,
              AppStrings.squareFeetDispatched,
              delivery.effectiveSquareFeet.toStringAsFixed(2),
            ),
          ],
          if (delivery.vehicleNumber != null &&
              delivery.vehicleNumber!.trim().isNotEmpty) ...[
            PdfDocumentTheme.divider(),
            PdfDocumentTheme.summaryRow(
              fonts,
              AppStrings.deliveryVehicleNumber,
              Formatters.textForExport(delivery.vehicleNumber!),
            ),
          ],
          if (delivery.driverName != null &&
              delivery.driverName!.trim().isNotEmpty)
            PdfDocumentTheme.summaryRow(
              fonts,
              AppStrings.driverName,
              Formatters.textForExport(delivery.driverName!),
            ),
          if (delivery.loadingSupervisor != null &&
              delivery.loadingSupervisor!.isNotEmpty)
            PdfDocumentTheme.summaryRow(
              fonts,
              AppStrings.loadingSupervisor,
              Formatters.textForExport(delivery.loadingSupervisor!),
            ),
          if (delivery.receiverName != null &&
              delivery.receiverName!.trim().isNotEmpty)
            PdfDocumentTheme.summaryRow(
              fonts,
              AppStrings.receiverName,
              Formatters.textForExport(delivery.receiverName!),
            ),
          if (delivery.notes != null && delivery.notes!.trim().isNotEmpty) ...[
            PdfDocumentTheme.divider(),
            pw.Text(
              AppStrings.notes,
              style: PdfDocumentTheme.bodyStyle(fonts, bold: true),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              Formatters.textForExport(delivery.notes!),
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
                    pw.Text(
                      AppStrings.loadingSupervisor,
                      style: PdfDocumentTheme.subtitleStyle(fonts),
                    ),
                    pw.SizedBox(height: 28),
                    pw.Container(
                      width: 180,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(color: PdfDocumentTheme.border),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      delivery.receiverName != null &&
                              delivery.receiverName!.trim().isNotEmpty
                          ? '${AppStrings.receiverName}: ${delivery.receiverName}'
                          : AppStrings.customerSignature,
                      style: PdfDocumentTheme.subtitleStyle(fonts),
                    ),
                    pw.SizedBox(height: 28),
                    pw.Container(
                      width: 180,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(color: PdfDocumentTheme.border),
                        ),
                      ),
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
