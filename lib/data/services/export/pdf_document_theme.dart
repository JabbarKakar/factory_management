import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

abstract final class PdfDocumentTheme {
  static const PdfColor primary = PdfColor.fromInt(0xFF1A237E);
  static const PdfColor muted = PdfColor.fromInt(0xFF616161);
  static const PdfColor border = PdfColor.fromInt(0xFFE0E0E0);

  static pw.TextStyle titleStyle({double size = 18}) => pw.TextStyle(
        fontSize: size,
        fontWeight: pw.FontWeight.bold,
        color: primary,
      );

  static pw.TextStyle subtitleStyle({double size = 11}) => pw.TextStyle(
        fontSize: size,
        color: muted,
      );

  static pw.TextStyle bodyStyle({bool bold = false}) => pw.TextStyle(
        fontSize: 10,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      );

  static pw.Widget header({
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
              pw.Text(title, style: titleStyle()),
              if (subtitle != null) ...[
                pw.SizedBox(height: 4),
                pw.Text(subtitle, style: subtitleStyle()),
              ],
            ],
          ),
        ),
        if (rightLabel != null)
          pw.Text(rightLabel, style: subtitleStyle()),
      ],
    );
  }

  static pw.Widget divider() => pw.Divider(color: border, height: 24);

  static pw.TableRow tableHeaderRow(List<String> labels) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F5F5)),
      children: [
        for (final label in labels)
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(label, style: bodyStyle(bold: true)),
          ),
      ],
    );
  }

  static pw.TableRow tableDataRow(List<String> values) {
    return pw.TableRow(
      children: [
        for (final value in values)
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(value, style: bodyStyle()),
          ),
      ],
    );
  }

  static pw.Widget summaryRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: bodyStyle(bold: bold))),
          pw.Text(value, style: bodyStyle(bold: bold)),
        ],
      ),
    );
  }
}
