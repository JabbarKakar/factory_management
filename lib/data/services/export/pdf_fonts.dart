import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfFonts {
  const PdfFonts({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;

  pw.ThemeData get theme => pw.ThemeData.withFont(base: regular, bold: bold);

  static Future<PdfFonts> load() async {
    try {
      final regularData =
          await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      return PdfFonts(
        regular: pw.Font.ttf(regularData),
        bold: pw.Font.ttf(boldData),
      );
    } catch (error) {
      debugPrint('PdfFonts: bundled Noto Sans unavailable: $error');
    }

    try {
      final regular = await PdfGoogleFonts.notoSansRegular();
      final bold = await PdfGoogleFonts.notoSansBold();
      return PdfFonts(regular: regular, bold: bold);
    } catch (error) {
      debugPrint('PdfFonts: Google Noto Sans unavailable: $error');
    }

    try {
      final regular = await PdfGoogleFonts.openSansRegular();
      final bold = await PdfGoogleFonts.openSansBold();
      return PdfFonts(regular: regular, bold: bold);
    } catch (_) {
      return PdfFonts(
        regular: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      );
    }
  }
}
