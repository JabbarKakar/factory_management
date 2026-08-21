import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/factory_profile.dart';
import '../../../domain/entities/supplier_statement.dart';
import 'pdf_document_theme.dart';
import 'pdf_fonts.dart';

class SupplierStatementPdfExporter {
  Future<pw.Document> build({
    required SupplierStatement statement,
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
    final rangeLabel =
        '${dateFormat.format(statement.fromDate)} – ${dateFormat.format(statement.toDate)}';

    final isPaidUp = statement.closingBalance <= 0;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: PdfDocumentTheme.pageMargin,
        theme: fonts.theme,
        header: (context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return PdfDocumentTheme.pageHeaderStrip(
            fonts: fonts,
            left: '${branding.factoryName} · SUPPLIER STATEMENT',
            right: Formatters.textForExport(statement.supplier.name),
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
            documentTitle: 'SUPPLIER STATEMENT / INVOICE',
            metaRows: [
              (label: 'Period:', value: rangeLabel),
              (
                label: 'Supplier #:',
                value: Formatters.textForExport(statement.supplier.supplierNumber),
              ),
              (
                label: 'Type:',
                value: statement.supplier.supplierType.label,
              ),
              (
                label: 'Terms:',
                value: statement.supplier.paymentTerms.label,
              ),
            ],
            statusLabel: isPaidUp ? 'ALL DUES SETTLED' : 'OUTSTANDING PAYABLE',
            statusPositive: isPaidUp,
          ),
          PdfDocumentTheme.divider(),
          PdfDocumentTheme.infoBanner(
            fonts: fonts,
            title: 'Vendor / Supplier Information',
            children: [
              PdfDocumentTheme.infoItemsRow(
                fonts: fonts,
                items: [
                  (
                    label: 'Supplier Name',
                    value: Formatters.textForExport(statement.supplier.name),
                  ),
                  (
                    label: 'Phone',
                    value: statement.supplier.phone.isNotEmpty
                        ? statement.supplier.phone
                        : Formatters.exportEmpty,
                  ),
                  (
                    label: 'Contact Person',
                    value: statement.supplier.contactPersonName != null &&
                            statement.supplier.contactPersonName!.isNotEmpty
                        ? statement.supplier.contactPersonName!
                        : Formatters.exportEmpty,
                  ),
                  (
                    label: 'City / Location',
                    value: Formatters.textForExport(
                      statement.supplier.displayLocation,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'PURCHASE & PAYMENT LEDGER',
            style: PdfDocumentTheme.sectionTitleStyle(fonts),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfDocumentTheme.borderLight,
              width: 0.8,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.1),
              1: const pw.FlexColumnWidth(2.3),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              PdfDocumentTheme.tableHeaderRow(fonts, [
                AppStrings.date,
                'Item / Description',
                AppStrings.reference,
                'Purchases',
                'Paid (Credit)',
              ]),
              PdfDocumentTheme.tableDataRow(
                fonts,
                [
                  Formatters.exportEmpty,
                  'Opening Balance',
                  '',
                  statement.openingBalance > 0
                      ? Formatters.currencyForExport(statement.openingBalance)
                      : '',
                  statement.openingBalance < 0
                      ? Formatters.currencyForExport(
                          statement.openingBalance.abs(),
                        )
                      : '',
                ],
                index: 0,
                bold: true,
              ),
              for (var i = 0; i < statement.lines.length; i++)
                PdfDocumentTheme.tableDataRow(
                  fonts,
                  [
                    dateFormat.format(statement.lines[i].date),
                    _formatLineDescription(statement.lines[i]),
                    Formatters.textForExport(statement.lines[i].reference),
                    statement.lines[i].debit > 0
                        ? Formatters.currencyForExport(statement.lines[i].debit)
                        : '',
                    statement.lines[i].credit > 0
                        ? Formatters.currencyForExport(
                            statement.lines[i].credit,
                          )
                        : '',
                  ],
                  index: i + 1,
                ),
              PdfDocumentTheme.tableDataRow(
                fonts,
                [
                  Formatters.exportEmpty,
                  'Closing Balance (Remaining Due)',
                  '',
                  statement.closingBalance > 0
                      ? Formatters.currencyForExport(statement.closingBalance)
                      : '',
                  statement.closingBalance <= 0
                      ? Formatters.currencyForExport(
                          statement.closingBalance.abs(),
                        )
                      : '',
                ],
                index: statement.lines.length + 1,
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
                  'Opening Balance',
                  Formatters.currencyForExport(statement.openingBalance),
                ),
                PdfDocumentTheme.summaryRow(
                  fonts,
                  'Total Purchases (Invoiced)',
                  Formatters.currencyForExport(statement.totalPurchases),
                ),
                PdfDocumentTheme.summaryRow(
                  fonts,
                  'Total Paid (History)',
                  Formatters.currencyForExport(statement.totalPaid),
                ),
                PdfDocumentTheme.summaryRow(
                  fonts,
                  'Remaining Balance Due',
                  Formatters.currencyForExport(statement.closingBalance),
                  bold: true,
                ),
              ],
            ),
          ),
          if (branding.footerNote != null) ...[
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                branding.footerNote!,
                style: PdfDocumentTheme.subtitleStyle(fonts, size: 7.5),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
          pw.SizedBox(height: 16),
          PdfDocumentTheme.authorizationBlock(
            fonts: fonts,
            branding: branding,
            preparedLabel: 'Prepared By (Accounts)',
            authorizedLabel: 'Authorized / Owner Signature',
            showPreparedLine: true,
          ),
        ],
      ),
    );

    return doc;
  }

  String _formatLineDescription(SupplierStatementLine line) {
    if (line.quantity != null && line.quantity! > 0) {
      final unitStr = line.unit ?? '';
      final rateStr = line.unitPrice != null && line.unitPrice! > 0
          ? ' @ ${Formatters.currencyForExport(line.unitPrice!)}'
          : '';
      return '${line.description} (${line.quantity!.toStringAsFixed(line.quantity! % 1 == 0 ? 0 : 2)} $unitStr$rateStr)';
    }
    return line.description;
  }
}
