import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/factory_profile.dart';
import '../../../domain/entities/sales_agreement.dart';
import '../../../domain/entities/sales_invoice.dart';
import '../../../domain/entities/sales_order.dart';
import '../sales_container_sync_helper.dart';
import 'pdf_document_theme.dart';
import 'pdf_fonts.dart';

/// Agreement-level Grand Sales Invoice PDF (Job Work grand chrome parallel).
abstract final class GrandSalesInvoicePdfTemplate {
  static Future<pw.Document> build({
    required SalesInvoice invoice,
    required SalesAgreement? agreement,
    required List<SalesOrder> orders,
    required List<SalesInvoice> invoices,
    required FactoryProfile? factoryProfile,
    required PdfFonts fonts,
    required PdfFactoryBranding branding,
  }) async {
    final dateFormat = DateFormat.yMMMd();
    final isPaid = invoice.dueAmount <= 0;
    final billable =
        SalesContainerSyncHelper.billableOrdersForGrandInvoice(orders);
    final displayOrders = billable.isNotEmpty ? billable : orders;
    final footerNote = branding.footerNote ??
        'Thank you for your business with ${branding.factoryName}!';

    final doc = pw.Document(theme: fonts.theme);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: PdfDocumentTheme.pageMargin,
        theme: fonts.theme,
        header: (context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return PdfDocumentTheme.pageHeaderStrip(
            fonts: fonts,
            left: '${branding.factoryName} · GRAND SALES INVOICE',
            right: invoice.invoiceNumber,
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
            documentTitle: 'GRAND SALES INVOICE',
            metaRows: [
              (label: 'Invoice No:', value: invoice.invoiceNumber),
              (
                label: 'Date Issued:',
                value: dateFormat.format(invoice.createdAt),
              ),
              if (invoice.dueDate != null)
                (
                  label: 'Due Date:',
                  value: dateFormat.format(invoice.dueDate!),
                ),
              (
                label: 'Agreement No:',
                value: Formatters.textForExport(
                  invoice.agreementNumber?.trim().isNotEmpty == true
                      ? invoice.agreementNumber!
                      : (agreement?.agreementNumber ?? '—'),
                ),
              ),
            ],
            statusLabel: isPaid ? 'FULLY PAID' : 'OUTSTANDING DUE',
            statusPositive: isPaid,
          ),
          PdfDocumentTheme.divider(),
          PdfDocumentTheme.infoBanner(
            fonts: fonts,
            title: 'Client / Bill To',
            children: [
              PdfDocumentTheme.cardRow(
                fonts,
                'Client Name',
                Formatters.textForExport(invoice.customerName),
              ),
              PdfDocumentTheme.cardRow(
                fonts,
                'Account Type',
                'Sales Agreement',
              ),
              PdfDocumentTheme.cardRow(
                fonts,
                'Orders on Invoice',
                '${displayOrders.length}',
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          for (var i = 0; i < displayOrders.length; i++) ...[
            _orderSection(
              order: displayOrders[i],
              index: i + 1,
              invoices: invoices,
              fonts: fonts,
              dateFormat: dateFormat,
            ),
            if (i < displayOrders.length - 1) pw.SizedBox(height: 12),
          ],
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 5,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    PdfDocumentTheme.bankRemittanceBlock(
                      fonts: fonts,
                      accounts: factoryProfile?.bankAccounts ?? const [],
                    ),
                    pw.SizedBox(height: 10),
                    PdfDocumentTheme.termsAndConditionsBlock(
                      fonts: fonts,
                      configuredTerms: factoryProfile
                          ?.invoiceSettings.termsAndConditions,
                      defaultTerms: PdfDocumentTheme.defaultSalesTerms,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                flex: 5,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(
                      color: PdfDocumentTheme.borderLight,
                      width: 0.8,
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      PdfDocumentTheme.summaryRow(
                        fonts,
                        AppStrings.invoiceTotal,
                        Formatters.currencyForExport(invoice.totalAmount),
                      ),
                      PdfDocumentTheme.summaryRow(
                        fonts,
                        AppStrings.amountPaid,
                        Formatters.currencyForExport(invoice.paidAmount),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfDocumentTheme.navy,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: pw.Row(
                          mainAxisAlignment:
                              pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'OUTSTANDING BALANCE',
                              style: pw.TextStyle(
                                font: fonts.bold,
                                fontSize: 8,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.Text(
                              Formatters.currencyForExport(invoice.dueAmount),
                              style: pw.TextStyle(
                                font: fonts.bold,
                                fontSize: 11,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Center(
            child: pw.Text(
              footerNote,
              style: PdfDocumentTheme.subtitleStyle(fonts, size: 8),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 16),
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

  static pw.Widget _orderSection({
    required SalesOrder order,
    required int index,
    required List<SalesInvoice> invoices,
    required PdfFonts fonts,
    required DateFormat dateFormat,
  }) {
    final finance = SalesContainerSyncHelper.financeForOrderOnGrand(
      order: order,
      invoices: invoices,
    );
    final lineItems = order.lineItems
        .where((item) => item.hasContent)
        .toList();

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfDocumentTheme.borderLight, width: 0.8),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: const pw.BoxDecoration(
              color: PdfDocumentTheme.navy,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(3.2),
                topRight: pw.Radius.circular(3.2),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'ORDER $index · ${Formatters.textForExport(order.orderNumber)}',
                    style: pw.TextStyle(
                      font: fonts.bold,
                      fontSize: 9,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.Text(
                  dateFormat.format(order.orderDate),
                  style: pw.TextStyle(
                    font: fonts.regular,
                    fontSize: 8,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: pw.Column(
              children: [
                if (lineItems.isEmpty)
                  pw.Text(
                    'No line items recorded',
                    style: PdfDocumentTheme.subtitleStyle(fonts, size: 8),
                  )
                else
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfDocumentTheme.borderLight,
                      width: 0.6,
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3.2),
                      1: const pw.FlexColumnWidth(1.1),
                      2: const pw.FlexColumnWidth(1.2),
                      3: const pw.FlexColumnWidth(1.3),
                    },
                    children: [
                      PdfDocumentTheme.tableHeaderRow(
                        fonts,
                        [
                          AppStrings.description,
                          'Pcs',
                          'Sq. Ft',
                          AppStrings.amount,
                        ],
                      ),
                      for (var i = 0; i < lineItems.length; i++)
                        PdfDocumentTheme.tableDataRow(
                          fonts,
                          [
                            Formatters.textForExport(
                              '${lineItems[i].productType.label} — ${lineItems[i].marbleVariety}',
                            ),
                            '${lineItems[i].totalPieces}',
                            lineItems[i].totalSquareFeet.toStringAsFixed(1),
                            Formatters.currencyForExport(lineItems[i].lineTotal),
                          ],
                          index: i,
                        ),
                    ],
                  ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfDocumentTheme.goldBg,
                    borderRadius: pw.BorderRadius.circular(3),
                    border: pw.Border.all(
                      color: PdfDocumentTheme.borderLight,
                      width: 0.6,
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _miniMetric(
                        fonts,
                        'Charges',
                        Formatters.currencyForExport(finance.charges),
                      ),
                      _miniMetric(
                        fonts,
                        'Paid',
                        Formatters.currencyForExport(finance.paid),
                      ),
                      _miniMetric(
                        fonts,
                        'Remaining',
                        Formatters.currencyForExport(finance.due),
                        emphasize: finance.due > 0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _miniMetric(
    PdfFonts fonts,
    String label,
    String value, {
    bool emphasize = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: PdfDocumentTheme.subtitleStyle(fonts, size: 7),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: 8.5,
            color: emphasize ? PdfDocumentTheme.accentBlue : PdfDocumentTheme.navy,
          ),
        ),
      ],
    );
  }
}
