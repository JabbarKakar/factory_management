import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/delivery.dart';
import '../../../domain/entities/factory_profile.dart';
import '../../../domain/entities/sales_invoice.dart';
import '../../../domain/entities/sales_order.dart';
import '../../../domain/entities/stock_output.dart';
import '../delivery_quantity_helper.dart';
import 'pdf_document_theme.dart';
import 'pdf_fonts.dart';

/// Single-order Sales Invoice PDF with per-size Small/Large stock tables
/// (Job Work single-load invoice pattern).
abstract final class SingleSalesInvoicePdfTemplate {
  static final NumberFormat _commaFormatter = NumberFormat('#,##0.00');
  static final NumberFormat _wholeCommaFormatter = NumberFormat('#,##0');

  static String _formatAmount(double amount) => _commaFormatter.format(amount);
  static String _formatWhole(num val) => _wholeCommaFormatter.format(val);

  static double _normalizeRemainingSqFt({
    required int remainingPieces,
    required double rawSquareFeet,
  }) {
    if (remainingPieces <= 0) return 0;
    return math.max(0, rawSquareFeet);
  }

  static Future<pw.Document> build({
    required SalesInvoice invoice,
    required SalesOrder order,
    required List<Delivery> deliveries,
    required FactoryProfile? factoryProfile,
    required PdfFonts fonts,
    required PdfFactoryBranding branding,
  }) async {
    final dateFormat = DateFormat.yMMMd();
    final currencySymbol = CurrencyFormatter.getSymbol(
      CurrencyFormatter.activeCurrency,
      asciiSafe: true,
    );
    final isPaid = invoice.dueAmount <= 0;
    final footerNote = branding.footerNote ??
        'Thank you for your business with ${branding.factoryName}!';
    final lineItems = order.lineItems.where((item) => item.hasContent).toList();

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
            left: '${branding.factoryName} · SALES INVOICE',
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
            documentTitle: 'SALES INVOICE',
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
                label: 'Order No:',
                value: Formatters.textForExport(order.orderNumber),
              ),
              if (invoice.agreementNumber != null &&
                  invoice.agreementNumber!.trim().isNotEmpty)
                (
                  label: 'Agreement No:',
                  value: Formatters.textForExport(invoice.agreementNumber!),
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
                'Sales Order',
              ),
              PdfDocumentTheme.cardRow(
                fonts,
                'Payment Terms',
                order.paymentTerms.label,
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          if (lineItems.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text(
                'No stock line items recorded for this order.',
                style: PdfDocumentTheme.subtitleStyle(fonts, size: 8.5),
              ),
            )
          else
            for (var i = 0; i < lineItems.length; i++) ...[
              ..._buildLineItemSection(
                lineItem: lineItems[i],
                index: i + 1,
                deliveries: deliveries,
                fonts: fonts,
                currencySymbol: currencySymbol,
              ),
              if (i < lineItems.length - 1) pw.SizedBox(height: 12),
            ],
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 5,
                child: PdfDocumentTheme.bankRemittanceBlock(
                  fonts: fonts,
                  accounts: factoryProfile?.bankAccounts ?? const [],
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
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
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
          pw.SizedBox(height: 12),
          PdfDocumentTheme.termsAndConditionsBlock(
            fonts: fonts,
            configuredTerms: factoryProfile?.invoiceSettings.termsAndConditions,
            defaultTerms: PdfDocumentTheme.defaultSalesTerms,
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

  static List<pw.Widget> _buildLineItemSection({
    required SalesOrderLineItem lineItem,
    required int index,
    required List<Delivery> deliveries,
    required PdfFonts fonts,
    required String currencySymbol,
  }) {
    final smallStocks = lineItem.activeSmallOutputs;
    final largeStocks = lineItem.activeLargeOutputs;
    final stocks = [...smallStocks, ...largeStocks];

    var smallTotalPieces = 0;
    var smallTotalSqFt = 0.0;
    var smallDispPieces = 0;
    var smallDispSqFt = 0.0;
    var smallTotalAmount = 0.0;

    var largeTotalPieces = 0;
    var largeTotalSqFt = 0.0;
    var largeDispPieces = 0;
    var largeDispSqFt = 0.0;
    var largeTotalAmount = 0.0;

    for (final stock in smallStocks) {
      final dispPcs = DeliveryQuantityHelper.consumedPiecesForStockRow(
        lineItem,
        stock.size,
        deliveries,
      );
      final dispSqFt = DeliveryQuantityHelper.consumedSquareFeetForStockRow(
        lineItem,
        stock.size,
        deliveries,
      );
      smallTotalPieces += stock.pieces;
      smallTotalSqFt += stock.squareFeet;
      smallDispPieces += dispPcs;
      smallDispSqFt += dispSqFt;
      smallTotalAmount += stock.amount;
    }

    for (final stock in largeStocks) {
      final dispPcs = DeliveryQuantityHelper.consumedPiecesForStockRow(
        lineItem,
        stock.size,
        deliveries,
      );
      final dispSqFt = DeliveryQuantityHelper.consumedSquareFeetForStockRow(
        lineItem,
        stock.size,
        deliveries,
      );
      largeTotalPieces += stock.pieces;
      largeTotalSqFt += stock.squareFeet;
      largeDispPieces += dispPcs;
      largeDispSqFt += dispSqFt;
      largeTotalAmount += stock.amount;
    }

    final smallRemPieces = math.max(0, smallTotalPieces - smallDispPieces);
    final smallRemSqFt = _normalizeRemainingSqFt(
      remainingPieces: smallRemPieces,
      rawSquareFeet: smallTotalSqFt - smallDispSqFt,
    );
    final largeRemPieces = math.max(0, largeTotalPieces - largeDispPieces);
    final largeRemSqFt = _normalizeRemainingSqFt(
      remainingPieces: largeRemPieces,
      rawSquareFeet: largeTotalSqFt - largeDispSqFt,
    );

    pw.TableRow stockDataRow({
      required int rowIndex,
      required String label,
      required int pieces,
      required int dispPieces,
      required int remPieces,
      required double squareFeet,
      required double dispSqFt,
      required double remSqFt,
      required String rate,
      required double amount,
    }) {
      return pw.TableRow(
        decoration: pw.BoxDecoration(
          color: rowIndex % 2 == 1
              ? PdfDocumentTheme.bgLight
              : PdfColors.white,
        ),
        children: [
          _tableCell(fonts, label),
          _tableCell(fonts, _formatWhole(pieces)),
          _tableCell(fonts, _formatWhole(dispPieces)),
          _tableCell(fonts, _formatWhole(remPieces)),
          _tableCell(fonts, _formatAmount(squareFeet)),
          _tableCell(fonts, _formatAmount(dispSqFt)),
          _tableCell(fonts, _formatAmount(remSqFt)),
          _tableCell(fonts, rate),
          _tableCell(fonts, _formatAmount(amount)),
        ],
      );
    }

    pw.TableRow categoryHeaderRow(String title) {
      return pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfDocumentTheme.cardHeaderBg),
        children: [
          _tableCell(
            fonts,
            title,
            isBold: true,
            color: PdfColors.white,
          ),
          _tableCell(fonts, ''),
          _tableCell(fonts, ''),
          _tableCell(fonts, ''),
          _tableCell(fonts, ''),
          _tableCell(fonts, ''),
          _tableCell(fonts, ''),
          _tableCell(fonts, ''),
          _tableCell(fonts, ''),
        ],
      );
    }

    List<pw.TableRow> sizeRows(List<StockOutput> sizeStocks) {
      final rows = <pw.TableRow>[];
      for (var i = 0; i < sizeStocks.length; i++) {
        final stock = sizeStocks[i];
        final dispPcs = DeliveryQuantityHelper.consumedPiecesForStockRow(
          lineItem,
          stock.size,
          deliveries,
        );
        final dispSqFt = DeliveryQuantityHelper.consumedSquareFeetForStockRow(
          lineItem,
          stock.size,
          deliveries,
        );
        final remPcs = math.max(0, stock.pieces - dispPcs);
        final remSqFt = _normalizeRemainingSqFt(
          remainingPieces: remPcs,
          rawSquareFeet: stock.squareFeet - dispSqFt,
        );
        final status = dispPcs == 0
            ? 'Ready'
            : (dispPcs >= stock.pieces ? 'Dispatched' : 'Part. Disp.');

        rows.add(
          stockDataRow(
            rowIndex: i,
            label: '${stock.size} ($status)',
            pieces: stock.pieces,
            dispPieces: dispPcs,
            remPieces: remPcs,
            squareFeet: stock.squareFeet,
            dispSqFt: dispSqFt,
            remSqFt: remSqFt,
            rate: stock.pricePerSqFt.toStringAsFixed(2),
            amount: stock.amount,
          ),
        );
      }
      return rows;
    }

    return [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        decoration: const pw.BoxDecoration(
          color: PdfDocumentTheme.navy,
          borderRadius: pw.BorderRadius.only(
            topLeft: pw.Radius.circular(4),
            topRight: pw.Radius.circular(4),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'LINE #$index: ${lineItem.productType.label}',
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 9.5,
                color: PdfColors.white,
              ),
            ),
            pw.Text(
              Formatters.textForExport(lineItem.marbleVariety),
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 8.5,
                color: PdfColors.white,
              ),
            ),
          ],
        ),
      ),
      pw.Container(
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(
              color: PdfDocumentTheme.borderLight,
              width: 0.8,
            ),
            right: pw.BorderSide(
              color: PdfDocumentTheme.borderLight,
              width: 0.8,
            ),
            bottom: pw.BorderSide(
              color: PdfDocumentTheme.borderLight,
              width: 0.8,
            ),
          ),
        ),
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _gridRow(fonts, 'Product Type:', lineItem.productType.label),
                  _gridRow(
                    fonts,
                    'Marble Variety:',
                    Formatters.textForExport(lineItem.marbleVariety),
                  ),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _gridRow(
                    fonts,
                    'Total Pieces:',
                    _formatWhole(lineItem.totalPieces),
                  ),
                  _gridRow(
                    fonts,
                    'Total Sq. Ft:',
                    _formatAmount(lineItem.totalSquareFeet),
                  ),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _gridRow(
                    fonts,
                    'Line Total:',
                    '$currencySymbol ${_formatAmount(lineItem.lineTotal)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 8),
      if (stocks.isNotEmpty) ...[
        if (smallStocks.isNotEmpty) ...[
          pw.Table(
            border: _stockTableBorder,
            columnWidths: _stockColumnWidths,
            children: [
              _stockColumnHeaderRow(fonts, currencySymbol),
              categoryHeaderRow('Small Sizes'),
              ...sizeRows(smallStocks),
            ],
          ),
          pw.SizedBox(height: 4),
          _categorySubtotalBar(
            fonts: fonts,
            label: 'Subtotal Small:',
            totalPieces: smallTotalPieces,
            dispatchedPieces: smallDispPieces,
            remainingPieces: smallRemPieces,
            totalSqFt: smallTotalSqFt,
            dispatchedSqFt: smallDispSqFt,
            remainingSqFt: smallRemSqFt,
            charges: smallTotalAmount,
          ),
        ],
        if (largeStocks.isNotEmpty) ...[
          if (smallStocks.isNotEmpty) pw.SizedBox(height: 8),
          pw.Table(
            border: _stockTableBorder,
            columnWidths: _stockColumnWidths,
            children: [
              if (smallStocks.isEmpty)
                _stockColumnHeaderRow(fonts, currencySymbol),
              categoryHeaderRow('Large Sizes'),
              ...sizeRows(largeStocks),
            ],
          ),
          pw.SizedBox(height: 4),
          _categorySubtotalBar(
            fonts: fonts,
            label: 'Subtotal Large:',
            totalPieces: largeTotalPieces,
            dispatchedPieces: largeDispPieces,
            remainingPieces: largeRemPieces,
            totalSqFt: largeTotalSqFt,
            dispatchedSqFt: largeDispSqFt,
            remainingSqFt: largeRemSqFt,
            charges: largeTotalAmount,
          ),
        ],
      ] else
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: pw.Text(
            'No individual stock outputs recorded for this line.',
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 8.5,
              color: PdfDocumentTheme.mutedGrey,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        decoration: pw.BoxDecoration(
          color: PdfDocumentTheme.goldBg,
          border: pw.Border.all(
            color: PdfDocumentTheme.borderLight,
            width: 0.8,
          ),
          borderRadius: const pw.BorderRadius.only(
            bottomLeft: pw.Radius.circular(4),
            bottomRight: pw.Radius.circular(4),
          ),
        ),
        child: pw.Text(
          'Line #$index Total: $currencySymbol ${_formatAmount(lineItem.lineTotal)}',
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: 8.5,
            color: PdfDocumentTheme.navy,
          ),
        ),
      ),
    ];
  }

  static const Map<int, pw.FlexColumnWidth> _stockColumnWidths = {
    0: pw.FlexColumnWidth(3.2),
    1: pw.FlexColumnWidth(1.2),
    2: pw.FlexColumnWidth(1.2),
    3: pw.FlexColumnWidth(1.2),
    4: pw.FlexColumnWidth(1.5),
    5: pw.FlexColumnWidth(1.5),
    6: pw.FlexColumnWidth(1.5),
    7: pw.FlexColumnWidth(1.5),
    8: pw.FlexColumnWidth(2),
  };

  static const pw.TableBorder _stockTableBorder = pw.TableBorder(
    horizontalInside: pw.BorderSide(
      color: PdfDocumentTheme.borderLight,
      width: 0.4,
    ),
    verticalInside: pw.BorderSide(
      color: PdfDocumentTheme.borderLight,
      width: 0.4,
    ),
    top: pw.BorderSide(color: PdfDocumentTheme.borderLight, width: 0.6),
    bottom: pw.BorderSide(color: PdfDocumentTheme.borderLight, width: 0.6),
    left: pw.BorderSide(color: PdfDocumentTheme.borderLight, width: 0.8),
    right: pw.BorderSide(color: PdfDocumentTheme.borderLight, width: 0.8),
  );

  static pw.TableRow _stockColumnHeaderRow(
    PdfFonts fonts,
    String currencySymbol,
  ) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfDocumentTheme.navy),
      children: [
        _tableHeader(fonts, 'SIZE / DIMENSION (STATUS)'),
        _tableHeader(fonts, 'TOTAL PCS'),
        _tableHeader(fonts, 'DISP. PCS'),
        _tableHeader(fonts, 'REM. PCS'),
        _tableHeader(fonts, 'TOTAL SQFT'),
        _tableHeader(fonts, 'DISP. SQFT'),
        _tableHeader(fonts, 'REM. SQFT'),
        _tableHeader(fonts, 'RATE ($currencySymbol)'),
        _tableHeader(fonts, 'CHARGES ($currencySymbol)'),
      ],
    );
  }

  /// Separate summary strip under each size category (not part of detail rows).
  static pw.Widget _categorySubtotalBar({
    required PdfFonts fonts,
    required String label,
    required int totalPieces,
    required int dispatchedPieces,
    required int remainingPieces,
    required double totalSqFt,
    required double dispatchedSqFt,
    required double remainingSqFt,
    required double charges,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfDocumentTheme.borderLight,
        width: 0.8,
      ),
      columnWidths: _stockColumnWidths,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfDocumentTheme.goldBg),
          children: [
            _tableCell(fonts, label, isBold: true),
            _tableCell(fonts, _formatWhole(totalPieces), isBold: true),
            _tableCell(fonts, _formatWhole(dispatchedPieces), isBold: true),
            _tableCell(fonts, _formatWhole(remainingPieces), isBold: true),
            _tableCell(fonts, _formatAmount(totalSqFt), isBold: true),
            _tableCell(fonts, _formatAmount(dispatchedSqFt), isBold: true),
            _tableCell(fonts, _formatAmount(remainingSqFt), isBold: true),
            _tableCell(fonts, ''),
            _tableCell(fonts, _formatAmount(charges), isBold: true),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableHeader(PdfFonts fonts, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: fonts.bold,
          fontSize: 5.5,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _tableCell(
    PdfFonts fonts,
    String text, {
    pw.TextAlign align = pw.TextAlign.center,
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: isBold ? fonts.bold : fonts.regular,
          fontSize: 7.5,
          color: color ?? PdfDocumentTheme.navy,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _gridRow(PdfFonts fonts, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 85,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 8.5,
                color: PdfDocumentTheme.mutedGrey,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 8.5,
                color: PdfDocumentTheme.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
