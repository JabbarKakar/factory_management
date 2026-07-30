import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/customer_statement.dart';
import '../../../domain/entities/factory_profile.dart';
import 'pdf_document_theme.dart';
import 'pdf_fonts.dart';

class CustomerStatementPdfExporter {
  Future<pw.Document> build({
    required CustomerStatement statement,
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
        '${dateFormat.format(statement.fromDate)} - ${dateFormat.format(statement.toDate)}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: PdfDocumentTheme.pageMargin,
        theme: fonts.theme,
        header: (context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return PdfDocumentTheme.pageHeaderStrip(
            fonts: fonts,
            left: '${branding.factoryName} · CUSTOMER STATEMENT',
            right: Formatters.textForExport(statement.customer.name),
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
            documentTitle: 'CUSTOMER STATEMENT',
            metaRows: [
              (label: 'Period:', value: rangeLabel),
              (label: 'Customer:', value: Formatters.textForExport(statement.customer.name)),
            ],
          ),
          PdfDocumentTheme.divider(),
          PdfDocumentTheme.infoBanner(
            fonts: fonts,
            title: 'Account Summary',
            children: [
              PdfDocumentTheme.cardRow(
                fonts,
                'Customer',
                Formatters.textForExport(statement.customer.name),
              ),
              if (statement.customer.phone.isNotEmpty)
                PdfDocumentTheme.cardRow(
                  fonts,
                  'Phone',
                  Formatters.textForExport(statement.customer.phone),
                ),
              PdfDocumentTheme.cardRow(
                fonts,
                'Opening Balance',
                Formatters.currencyForExport(statement.openingBalance),
              ),
              PdfDocumentTheme.cardRow(
                fonts,
                'Closing Balance',
                Formatters.currencyForExport(statement.closingBalance),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfDocumentTheme.borderLight,
              width: 0.8,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              PdfDocumentTheme.tableHeaderRow(fonts, [
                AppStrings.date,
                AppStrings.description,
                AppStrings.reference,
                AppStrings.debit,
                AppStrings.credit,
              ]),
              PdfDocumentTheme.tableDataRow(
                fonts,
                [
                  Formatters.exportEmpty,
                  AppStrings.openingBalance,
                  '',
                  Formatters.currencyForExport(statement.openingBalance),
                  '',
                ],
                index: 0,
                bold: true,
              ),
              for (var i = 0; i < statement.lines.length; i++)
                PdfDocumentTheme.tableDataRow(
                  fonts,
                  [
                    dateFormat.format(statement.lines[i].date),
                    Formatters.textForExport(statement.lines[i].description),
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
                  AppStrings.closingBalance,
                  '',
                  Formatters.currencyForExport(statement.closingBalance),
                  '',
                ],
                index: statement.lines.length + 1,
                bold: true,
              ),
            ],
          ),
          pw.SizedBox(height: 14),
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
                  AppStrings.totalDebits,
                  Formatters.currencyForExport(statement.totalDebits),
                ),
                PdfDocumentTheme.summaryRow(
                  fonts,
                  AppStrings.totalCredits,
                  Formatters.currencyForExport(statement.totalCredits),
                ),
                PdfDocumentTheme.summaryRow(
                  fonts,
                  AppStrings.closingBalance,
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
                style: PdfDocumentTheme.subtitleStyle(fonts, size: 7),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
          pw.SizedBox(height: 16),
          PdfDocumentTheme.authorizationBlock(
            fonts: fonts,
            branding: branding,
            preparedLabel: 'Prepared By',
            showPreparedLine: true,
          ),
        ],
      ),
    );

    return doc;
  }
}
