import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/job_work_invoice.dart';
import 'pdf_fonts.dart';

/// Visual data for the proforma-style invoice PDF layout.
class ProformaInvoiceData {
  const ProformaInvoiceData({
    required this.companyName,
    required this.billTo,
    required this.receiptNumber,
    required this.documentTitle,
    required this.lineItems,
    required this.notes,
    required this.sumTotal,
    required this.taxes,
    required this.total,
    this.phone,
    this.email,
    this.website,
    this.address,
  });

  final String companyName;
  final String? phone;
  final String? email;
  final String? website;
  final String? address;
  final String billTo;
  final String receiptNumber;
  final String documentTitle;
  final List<ProformaInvoiceLineItem> lineItems;
  final List<String> notes;
  final double sumTotal;
  final double taxes;
  final double total;
}

class ProformaInvoiceLineItem {
  const ProformaInvoiceLineItem({
    required this.description,
    required this.units,
    required this.pricePerUnit,
    required this.amount,
  });

  final String description;
  final String units;
  final String pricePerUnit;
  final String amount;
}

/// Blue proforma invoice layout matching the provided template design.
abstract final class ProformaInvoicePdfTemplate {
  static const PdfColor _navy = PdfColor.fromInt(0xFF1A2E4A);
  static const PdfColor _mediumBlue = PdfColor.fromInt(0xFF4A86C8);
  static const PdfColor _lightBlue = PdfColor.fromInt(0xFFD6E6F5);
  static const PdfColor _titleBlue = PdfColor.fromInt(0xFF1F3A5F);

  static const int _minTableRows = 12;
  static const double _rowHeight = 26;

  static Future<pw.Document> build({
    required ProformaInvoiceData data,
    required PdfFonts fonts,
  }) async {
    final doc = pw.Document(theme: fonts.theme);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Stack(
            children: [
              pw.Container(color: PdfColors.white),
              _topLeftDecoration(),
              _topRightDecoration(data.companyName, fonts),
              _bottomRightDecoration(),
              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(44, 22, 44, 32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.SizedBox(height: 8),
                    _contactRow(data, fonts),
                    pw.SizedBox(height: 18),
                    _billToAndReceipt(data, fonts),
                    pw.SizedBox(height: 14),
                    _documentTitle(data.documentTitle, fonts),
                    pw.SizedBox(height: 12),
                    pw.Expanded(child: _itemsTable(data.lineItems, fonts)),
                    pw.SizedBox(height: 10),
                    _footerSection(data, fonts),
                    pw.SizedBox(height: 10),
                    pw.Center(
                      child: pw.Text(
                        'Thank you for your business!',
                        style: pw.TextStyle(
                          font: fonts.regular,
                          fontSize: 11,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc;
  }

  static pw.Widget _topLeftDecoration() {
    return pw.Positioned(
      left: 0,
      top: 0,
      child: pw.CustomPaint(
        size: const PdfPoint(130, 95),
        painter: (canvas, size) {
          canvas
            ..setFillColor(_lightBlue)
            ..moveTo(0, 0)
            ..lineTo(size.x, 0)
            ..lineTo(0, size.y)
            ..closePath()
            ..fillPath();

          canvas
            ..setFillColor(const PdfColor.fromInt(0xFF2E7D32))
            ..drawEllipse(38, 42, 18, 18)
            ..fillPath();

          canvas
            ..setFillColor(const PdfColor.fromInt(0xFF1565C0))
            ..drawEllipse(38, 42, 14, 14)
            ..fillPath();

          canvas
            ..setStrokeColor(PdfColors.white)
            ..setLineWidth(0.8)
            ..moveTo(24, 42)
            ..lineTo(52, 42)
            ..strokePath()
            ..moveTo(38, 28)
            ..lineTo(38, 56)
            ..strokePath();
        },
      ),
    );
  }

  static pw.Widget _topRightDecoration(String companyName, PdfFonts fonts) {
    return pw.Positioned(
      right: 0,
      top: 0,
      child: pw.Container(
        width: 210,
        height: 96,
        decoration: pw.BoxDecoration(
          color: _navy,
          borderRadius: const pw.BorderRadius.only(
            bottomLeft: pw.Radius.circular(78),
          ),
        ),
        padding: const pw.EdgeInsets.fromLTRB(28, 14, 18, 10),
        alignment: pw.Alignment.topRight,
        child: pw.Text(
          _stackedCompanyName(companyName),
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: 13,
            color: PdfColors.white,
            height: 1.12,
            letterSpacing: 0.4,
          ),
          textAlign: pw.TextAlign.right,
        ),
      ),
    );
  }

  static pw.Widget _bottomRightDecoration() {
    return pw.Positioned(
      right: 0,
      bottom: 0,
      child: pw.Container(
        width: 120,
        height: 72,
        decoration: pw.BoxDecoration(
          color: _navy,
          borderRadius: const pw.BorderRadius.only(
            topLeft: pw.Radius.circular(60),
          ),
        ),
      ),
    );
  }

  static String _stackedCompanyName(String name) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'FACTORY';
    return words.map((w) => w.toUpperCase()).join('\n');
  }

  static pw.Widget _contactRow(ProformaInvoiceData data, PdfFonts fonts) {
    final items = <pw.Widget>[];

    void addContact(String label) {
      if (label.trim().isEmpty) return;
      items.add(_contactChip(label, fonts));
    }

    addContact(data.phone ?? '');
    addContact(data.email ?? '');
    addContact(data.website ?? '');
    if (items.isEmpty && data.address != null && data.address!.trim().isNotEmpty) {
      addContact(data.address!.trim());
    }

    if (items.isEmpty) {
      return pw.SizedBox(height: 16);
    }

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) pw.SizedBox(width: 18),
          items[i],
        ],
      ],
    );
  }

  static pw.Widget _contactChip(String text, PdfFonts fonts) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 8,
          height: 8,
          decoration: const pw.BoxDecoration(
            color: _mediumBlue,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          Formatters.textForExport(text),
          style: pw.TextStyle(
            font: fonts.regular,
            fontSize: 9,
            color: _navy,
          ),
        ),
      ],
    );
  }

  static pw.Widget _billToAndReceipt(ProformaInvoiceData data, PdfFonts fonts) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BILL TO:',
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: 10,
                  color: _mediumBlue,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                height: 72,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _mediumBlue, width: 1.2),
                ),
                child: pw.Align(
                  alignment: pw.Alignment.topLeft,
                  child: pw.Text(
                    Formatters.textForExport(data.billTo),
                    style: pw.TextStyle(
                      font: fonts.regular,
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _mediumBlue, width: 1.2),
          ),
          child: pw.Text(
            'RECEIPT NO: ${Formatters.textForExport(data.receiptNumber)}',
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 9,
              color: _navy,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _documentTitle(String title, PdfFonts fonts) {
    return pw.Center(
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          font: fonts.bold,
          fontSize: 30,
          color: _titleBlue,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  static pw.Widget _itemsTable(
    List<ProformaInvoiceLineItem> items,
    PdfFonts fonts,
  ) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _navy),
        children: [
          _headerCell('ITEM DESCRIPTION', fonts),
          _headerCell('UNITS', fonts, center: true),
          _headerCell('PRICE PER UNIT', fonts, center: true),
          _headerCell('AMOUNT', fonts, center: true),
        ],
      ),
      for (final item in items)
        _dataRow(
          fonts,
          item.description,
          item.units,
          item.pricePerUnit,
          item.amount,
        ),
    ];

    final emptyRows = (_minTableRows - items.length).clamp(0, _minTableRows);
    for (var i = 0; i < emptyRows; i++) {
      rows.add(_dataRow(fonts, '', '', '', ''));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _mediumBlue, width: 1),
      columnWidths: {
        0: const pw.FlexColumnWidth(4.2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.6),
        3: const pw.FlexColumnWidth(1.6),
      },
      children: rows,
    );
  }

  static pw.Widget _headerCell(
    String label,
    PdfFonts fonts, {
    bool center = false,
  }) {
    return pw.Container(
      height: 28,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      alignment: center ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Text(
        label,
        style: pw.TextStyle(
          font: fonts.bold,
          fontSize: 8.5,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.TableRow _dataRow(
    PdfFonts fonts,
    String description,
    String units,
    String pricePerUnit,
    String amount,
  ) {
    pw.Widget cell(String value, {bool center = false}) {
      return pw.Container(
        height: _rowHeight,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        alignment: center ? pw.Alignment.center : pw.Alignment.centerLeft,
        child: pw.Text(
          value,
          style: pw.TextStyle(font: fonts.regular, fontSize: 9),
          maxLines: 2,
          overflow: pw.TextOverflow.clip,
        ),
      );
    }

    return pw.TableRow(
      children: [
        cell(description),
        cell(units, center: true),
        cell(pricePerUnit, center: true),
        cell(amount, center: true),
      ],
    );
  }

  static pw.Widget _footerSection(ProformaInvoiceData data, PdfFonts fonts) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'NOTES:',
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: 10,
                  color: _mediumBlue,
                ),
              ),
              pw.SizedBox(height: 6),
              for (final note in data.notes)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '- ',
                        style: pw.TextStyle(font: fonts.regular, fontSize: 9),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          Formatters.textForExport(note),
                          style: pw.TextStyle(
                            font: fonts.regular,
                            fontSize: 9,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.SizedBox(
          width: 220,
          child: pw.Column(
            children: [
              _totalRow(
                fonts,
                'SUM TOTAL',
                Formatters.currencyForExport(data.sumTotal),
              ),
              pw.SizedBox(height: 6),
              _totalRow(
                fonts,
                'TAXES',
                data.taxes > 0
                    ? Formatters.currencyForExport(data.taxes)
                    : Formatters.exportEmpty,
              ),
              pw.SizedBox(height: 6),
              _totalRow(
                fonts,
                'TOTAL',
                Formatters.currencyForExport(data.total),
                bold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _totalRow(
    PdfFonts fonts,
    String label,
    String value, {
    bool bold = false,
  }) {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(right: 8),
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  font: bold ? fonts.bold : fonts.regular,
                  fontSize: 9,
                  color: _navy,
                ),
              ),
            ),
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            height: 24,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _mediumBlue, width: 1.2),
            ),
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: bold ? fonts.bold : fonts.regular,
                fontSize: 9,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Maps a job work invoice entity into proforma layout data.
  static ProformaInvoiceData fromJobWorkInvoice({
    required JobWorkInvoice invoice,
    required String factoryName,
    String? factoryPhone,
    String? factoryAddress,
    DateFormat? dateFormat,
  }) {
    final df = dateFormat ?? DateFormat.yMMMd();

    final billToLines = <String>[invoice.customerName];
    if (invoice.jobWorkNumber.isNotEmpty) {
      billToLines.add('Job Work: ${invoice.jobWorkNumber}');
    }
    if (invoice.loadId != null && invoice.loadId!.trim().isNotEmpty) {
      billToLines.add('Load: ${invoice.loadNumber!.trim()}');
      if (invoice.mineLocation != null && invoice.mineLocation!.trim().isNotEmpty) {
        billToLines.add(invoice.mineLocation!.trim());
      }
      if (invoice.mineOwner != null && invoice.mineOwner!.trim().isNotEmpty) {
        billToLines.add('Owner: ${invoice.mineOwner!.trim()}');
      }
    }

    final lineItems = invoice.lineItems.map((item) {
      final hasAmount = item.amount > 0;
      return ProformaInvoiceLineItem(
        description: Formatters.textForExport(item.description),
        units: hasAmount ? '1' : '',
        pricePerUnit:
            hasAmount ? Formatters.currencyForExport(item.amount) : '',
        amount: hasAmount ? Formatters.currencyForExport(item.amount) : '',
      );
    }).toList();

    final notes = <String>[
      if (invoice.dueDate != null)
        'Please pay by ${df.format(invoice.dueDate!)}.'
      else
        'Please pay within agreed payment terms.',
      'Payment details are on the invoice.',
    ];

    if (invoice.paidAmount > 0) {
      notes.add('Amount paid: ${Formatters.currencyForExport(invoice.paidAmount)}');
    }
    if (invoice.dueAmount > 0) {
      notes.add('Balance due: ${Formatters.currencyForExport(invoice.dueAmount)}');
    }

    final sumTotal = invoice.lineItems.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    return ProformaInvoiceData(
      companyName: factoryName,
      phone: factoryPhone,
      address: factoryAddress,
      billTo: billToLines.join('\n'),
      receiptNumber: invoice.invoiceNumber,
      documentTitle: 'PROFORMA INVOICE',
      lineItems: lineItems,
      notes: notes,
      sumTotal: sumTotal,
      taxes: 0,
      total: invoice.totalAmount,
    );
  }
}
