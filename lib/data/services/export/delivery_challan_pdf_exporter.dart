import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/delivery.dart';
import '../../../domain/entities/factory_profile.dart';
import 'pdf_document_theme.dart';
import 'pdf_fonts.dart';

class DeliveryChallanPdfExporter {
  Future<pw.Document> buildDeliveryChallanPdf({
    required Delivery delivery,
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
    final dateFormat = DateFormat.yMMMd();
    final scheduledDate = dateFormat.format(delivery.scheduledDate);
    final actualDate = delivery.actualDeliveryDate == null
        ? null
        : dateFormat.format(delivery.actualDeliveryDate!);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: PdfDocumentTheme.pageMargin,
        theme: fonts.theme,
        header: (context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return PdfDocumentTheme.pageHeaderStrip(
            fonts: fonts,
            left: '${branding.factoryName} · DELIVERY CHALLAN',
            right: Formatters.textForExport(delivery.deliveryNumber),
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
            documentTitle: 'DELIVERY CHALLAN',
            metaRows: [
              (
                label: 'Challan No:',
                value: Formatters.textForExport(delivery.deliveryNumber),
              ),
              (label: 'Scheduled:', value: scheduledDate),
              if (actualDate != null) (label: 'Dispatched:', value: actualDate),
            ],
            statusLabel: delivery.status.label,
            statusPositive: delivery.status.isTerminal,
          ),
          PdfDocumentTheme.divider(),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: PdfDocumentTheme.detailCard(
                  fonts: fonts,
                  title: 'Customer & Delivery',
                  rows: [
                    PdfDocumentTheme.cardRow(
                      fonts,
                      'Customer',
                      Formatters.textForExport(delivery.customerName),
                    ),
                    PdfDocumentTheme.cardRow(
                      fonts,
                      'Order No',
                      Formatters.textForExport(delivery.salesOrderNumber),
                    ),
                    PdfDocumentTheme.cardRow(
                      fonts,
                      'Address',
                      Formatters.textForExport(delivery.deliveryAddress),
                    ),
                    if (delivery.receiverName != null &&
                        delivery.receiverName!.trim().isNotEmpty)
                      PdfDocumentTheme.cardRow(
                        fonts,
                        'Receiver',
                        Formatters.textForExport(delivery.receiverName!),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: PdfDocumentTheme.detailCard(
                  fonts: fonts,
                  title: 'Transport & Vehicle',
                  rows: [
                    if (delivery.vehicleNumber != null &&
                        delivery.vehicleNumber!.trim().isNotEmpty)
                      PdfDocumentTheme.cardRow(
                        fonts,
                        'Vehicle',
                        Formatters.textForExport(delivery.vehicleNumber!),
                      ),
                    if (delivery.driverName != null &&
                        delivery.driverName!.trim().isNotEmpty)
                      PdfDocumentTheme.cardRow(
                        fonts,
                        'Driver',
                        Formatters.textForExport(delivery.driverName!),
                      ),
                    if (delivery.loadingSupervisor != null &&
                        delivery.loadingSupervisor!.isNotEmpty)
                      PdfDocumentTheme.cardRow(
                        fonts,
                        'Supervisor',
                        Formatters.textForExport(delivery.loadingSupervisor!),
                      ),
                    PdfDocumentTheme.cardRow(
                      fonts,
                      'Status',
                      delivery.status.label,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            AppStrings.itemsToDeliver.toUpperCase(),
            style: PdfDocumentTheme.sectionTitleStyle(fonts),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfDocumentTheme.borderLight,
              width: 0.8,
            ),
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
              for (var i = 0; i < delivery.lineItems.length; i++)
                PdfDocumentTheme.tableDataRow(
                  fonts,
                  [
                    Formatters.textForExport(
                      delivery.lineItems[i].displayLabel,
                    ),
                    '${delivery.lineItems[i].pieces}',
                    delivery.lineItems[i].squareFeet.toStringAsFixed(2),
                    '${delivery.lineItems[i].effectivePieces}',
                    delivery.lineItems[i].effectiveSquareFeet
                        .toStringAsFixed(2),
                  ],
                  index: i,
                ),
            ],
          ),
          pw.SizedBox(height: 10),
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
                  AppStrings.totalPieces,
                  '${delivery.totalPieces}',
                  bold: true,
                ),
                PdfDocumentTheme.summaryRow(
                  fonts,
                  AppStrings.totalSquareFeet,
                  delivery.totalSquareFeet.toStringAsFixed(2),
                  bold: true,
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
              ],
            ),
          ),
          if (delivery.notes != null && delivery.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 10),
            PdfDocumentTheme.infoBanner(
              fonts: fonts,
              title: AppStrings.notes,
              children: [
                pw.Text(
                  Formatters.textForExport(delivery.notes!),
                  style: PdfDocumentTheme.subtitleStyle(fonts, size: 8),
                ),
              ],
            ),
          ],
          pw.SizedBox(height: 28),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.SizedBox(height: 42),
                    pw.Container(
                      width: 160,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                            color: PdfDocumentTheme.navy,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      delivery.receiverName != null &&
                              delivery.receiverName!.trim().isNotEmpty
                          ? '${AppStrings.receiverName}: ${delivery.receiverName}'
                          : AppStrings.customerSignature,
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 8,
                        color: PdfDocumentTheme.navy,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 24),
              PdfDocumentTheme.authorizedSignatureColumn(
                fonts: fonts,
                branding: branding,
                label: AppStrings.loadingSupervisor,
                width: 160,
              ),
            ],
          ),
        ],
      ),
    );

    return doc;
  }
}
