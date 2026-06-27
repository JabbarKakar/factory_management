import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_fonts.dart';

abstract final class PdfDocumentTheme {
  static const PdfColor primary = PdfColor.fromInt(0xFF1A237E);
  static const PdfColor muted = PdfColor.fromInt(0xFF616161);
  static const PdfColor border = PdfColor.fromInt(0xFFE0E0E0);

  static pw.TextStyle titleStyle(PdfFonts fonts, {double size = 18}) =>
      pw.TextStyle(
        font: fonts.bold,
        fontSize: size,
        color: primary,
      );

  static pw.TextStyle subtitleStyle(PdfFonts fonts, {double size = 11}) =>
      pw.TextStyle(
        font: fonts.regular,
        fontSize: size,
        color: muted,
      );

  static pw.TextStyle bodyStyle(PdfFonts fonts, {bool bold = false}) =>
      pw.TextStyle(
        font: bold ? fonts.bold : fonts.regular,
        fontSize: 10,
      );

  static pw.Widget header({
    required PdfFonts fonts,
    required String title,
    String? subtitle,
    String? rightLabel,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title, style: titleStyle(fonts)),
              if (subtitle != null) ...[
                pw.SizedBox(height: 4),
                pw.Text(subtitle, style: subtitleStyle(fonts)),
              ],
            ],
          ),
        ),
        if (rightLabel != null)
          pw.Text(rightLabel, style: subtitleStyle(fonts)),
      ],
    );
  }

  static pw.Widget divider() => pw.Divider(color: border, height: 24);

  static pw.TableRow tableHeaderRow(PdfFonts fonts, List<String> labels) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F5F5)),
      children: [
        for (final label in labels)
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(label, style: bodyStyle(fonts, bold: true)),
          ),
      ],
    );
  }

  static pw.TableRow tableDataRow(PdfFonts fonts, List<String> values) {
    return pw.TableRow(
      children: [
        for (final value in values)
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(value, style: bodyStyle(fonts)),
          ),
      ],
    );
  }

  static pw.Widget summaryRow(
    PdfFonts fonts,
    String label,
    String value, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: bodyStyle(fonts, bold: bold))),
          pw.Text(value, style: bodyStyle(fonts, bold: bold)),
        ],
      ),
    );
  }
}
