import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../domain/entities/factory_profile.dart';

/// PDF Service for generating printable high-resolution business cards.
class BusinessCardPdfService {
  static final PdfColor darkBg = PdfColor.fromHex('#1E1E1E');
  static final PdfColor darkBgAlt = PdfColor.fromHex('#141414');
  static final PdfColor goldAccent = PdfColor.fromHex('#D4AF37');
  static final PdfColor goldLight = PdfColor.fromHex('#F3E5AB');
  static final PdfColor warmGray = PdfColor.fromHex('#A0A0A0');
  static final PdfColor cutLineColor = PdfColor.fromHex('#CCCCCC');

  /// Standard Business Card dimensions in PDF Points (1 in = 72 pt)
  /// 3.5 in x 2.0 in = 252 pt x 144 pt
  static const double cardWidthPt = 252.0;
  static const double cardHeightPt = 144.0;

  /// Helper to extract initials for monogram fallback
  static String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'FM';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Generates vCard String for QR code scanning
  static String _generateVCardData(FactoryProfile profile) {
    final mapsUrl = profile.contact.googleMapsLink?.trim();
    final ownerName = profile.ownership.ownerName?.trim().isNotEmpty == true
        ? profile.ownership.ownerName!.trim()
        : (profile.ownerName?.trim().isNotEmpty == true
            ? profile.ownerName!.trim()
            : profile.identity.businessName);

    final bizName = profile.identity.businessName.isNotEmpty
        ? profile.identity.businessName
        : profile.name;

    final phone = profile.contact.phone.trim().isNotEmpty
        ? profile.contact.phone.trim()
        : (profile.contact.whatsapp?.trim() ?? '');

    final email = profile.contact.email?.trim() ?? '';
    final address = profile.contact.fullAddress;

    final sb = StringBuffer();
    sb.writeln('BEGIN:VCARD');
    sb.writeln('VERSION:3.0');
    sb.writeln('FN:$ownerName');
    sb.writeln('ORG:$bizName');
    if (phone.isNotEmpty) sb.writeln('TEL;TYPE=CELL:$phone');
    if (email.isNotEmpty) sb.writeln('EMAIL:$email');
    if (address.isNotEmpty) sb.writeln('ADR:;;$address;;;;');
    if (mapsUrl != null && mapsUrl.isNotEmpty) sb.writeln('URL:$mapsUrl');
    sb.write('END:VCARD');
    return sb.toString();
  }

  /// Generates a single card PDF (Page 1: Front, Page 2: Back)
  static Future<Uint8List> generateSingleCardPdf(
    FactoryProfile profile, {
    Uint8List? logoBytes,
  }) async {
    final doc = pw.Document();

    final fontRegular = await PdfGoogleFonts.outfitRegular();
    final fontBold = await PdfGoogleFonts.outfitBold();

    final format = const PdfPageFormat(
      cardWidthPt,
      cardHeightPt,
      marginAll: 0,
    );

    // Page 1: Front
    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) => _buildFrontCardPdf(
          profile: profile,
          fontRegular: fontRegular,
          fontBold: fontBold,
          logoBytes: logoBytes,
        ),
      ),
    );

    // Page 2: Back
    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) => _buildBackCardPdf(
          profile: profile,
          fontRegular: fontRegular,
          fontBold: fontBold,
        ),
      ),
    );

    return doc.save();
  }

  /// Generates a print-ready A4 sheet containing 10 business cards (2 cols x 5 rows)
  /// Page 1: 10 Front sides with crop/cut lines
  /// Page 2: 10 Back sides with crop/cut lines (grid-aligned for double-sided printing)
  static Future<Uint8List> generateA4PrintSheet(
    FactoryProfile profile, {
    Uint8List? logoBytes,
  }) async {
    final doc = pw.Document();

    final fontRegular = await PdfGoogleFonts.outfitRegular();
    final fontBold = await PdfGoogleFonts.outfitBold();

    // A4 dimensions: 595.28 pt x 841.89 pt
    // 2 columns of 252 pt = 504 pt total card width. Margin horizontal = (595.28 - 504) / 2 = 45.64 pt
    // 5 rows of 144 pt = 720 pt total card height. Margin vertical = (841.89 - 720) / 2 = 60.94 pt
    const double hMargin = 45.64;
    const double vMargin = 60.94;

    // Page 1: 10 Front Sides
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(
          horizontal: hMargin,
          vertical: vMargin,
        ),
        build: (context) => _buildA4Grid(
          itemBuilder: () => _buildFrontCardPdf(
            profile: profile,
            fontRegular: fontRegular,
            fontBold: fontBold,
            logoBytes: logoBytes,
          ),
        ),
      ),
    );

    // Page 2: 10 Back Sides
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(
          horizontal: hMargin,
          vertical: vMargin,
        ),
        build: (context) => _buildA4Grid(
          itemBuilder: () => _buildBackCardPdf(
            profile: profile,
            fontRegular: fontRegular,
            fontBold: fontBold,
          ),
        ),
      ),
    );

    return doc.save();
  }

  /// Builds a 2x5 grid on A4 with thin cut lines
  static pw.Widget _buildA4Grid({
    required pw.Widget Function() itemBuilder,
  }) {
    return pw.Container(
      width: 504,
      height: 720,
      child: pw.Column(
        children: List.generate(5, (row) {
          return pw.Row(
            children: List.generate(2, (col) {
              return pw.Container(
                width: cardWidthPt,
                height: cardHeightPt,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: cutLineColor,
                    width: 0.4,
                    style: pw.BorderStyle.dashed,
                  ),
                ),
                child: itemBuilder(),
              );
            }),
          );
        }),
      ),
    );
  }

  /// Front Side PDF Widget
  static pw.Widget _buildFrontCardPdf({
    required FactoryProfile profile,
    required pw.Font fontRegular,
    required pw.Font fontBold,
    Uint8List? logoBytes,
  }) {
    final businessName = profile.identity.businessName.isNotEmpty
        ? profile.identity.businessName
        : (profile.name.isNotEmpty ? profile.name : 'FACTORY MANAGEMENT');

    final tagline = (profile.identity.tagline != null &&
            profile.identity.tagline!.trim().isNotEmpty)
        ? profile.identity.tagline!.trim()
        : 'NATURAL STONE PROCESSING & EXPORT';

    final establishedYear = profile.identity.establishedYear;

    return pw.Container(
      width: cardWidthPt,
      height: cardHeightPt,
      color: darkBg,
      child: pw.Stack(
        children: [
          // Content
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Spacer(),

                // Logo or Monogram
                if (logoBytes != null && logoBytes.isNotEmpty)
                  pw.Container(
                    width: 36,
                    height: 36,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: goldAccent, width: 1),
                    ),
                    child: pw.ClipOval(
                      child: pw.Image(
                        pw.MemoryImage(logoBytes),
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  )
                else
                  pw.Container(
                    width: 34,
                    height: 34,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: goldAccent, width: 1),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        _getInitials(businessName),
                        style: pw.TextStyle(
                          font: fontBold,
                          color: goldAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                pw.SizedBox(height: 8),

                // Business Name
                pw.Text(
                  businessName.toUpperCase(),
                  textAlign: pw.TextAlign.center,
                  maxLines: 1,
                  style: pw.TextStyle(
                    font: fontBold,
                    color: goldAccent,
                    fontSize: 12.5,
                    letterSpacing: 1.1,
                  ),
                ),

                pw.SizedBox(height: 3),

                // Divider line
                pw.Container(
                  width: 40,
                  height: 0.8,
                  color: goldAccent,
                ),

                pw.SizedBox(height: 4),

                // Tagline
                pw.Text(
                  tagline.toUpperCase(),
                  textAlign: pw.TextAlign.center,
                  maxLines: 1,
                  style: pw.TextStyle(
                    font: fontRegular,
                    color: warmGray,
                    fontSize: 6.5,
                    letterSpacing: 0.8,
                  ),
                ),

                if (establishedYear != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'EST. $establishedYear',
                    style: pw.TextStyle(
                      font: fontBold,
                      color: goldAccent,
                      fontSize: 5.5,
                    ),
                  ),
                ],

                pw.Spacer(),
              ],
            ),
          ),

          // Bottom Gold Line Accent
          pw.Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: pw.Container(
              height: 2.5,
              color: goldAccent,
            ),
          ),
        ],
      ),
    );
  }

  /// Back Side PDF Widget
  static pw.Widget _buildBackCardPdf({
    required FactoryProfile profile,
    required pw.Font fontRegular,
    required pw.Font fontBold,
  }) {
    final ownerName = (profile.ownership.ownerName != null &&
            profile.ownership.ownerName!.trim().isNotEmpty)
        ? profile.ownership.ownerName!.trim()
        : (profile.ownerName != null && profile.ownerName!.trim().isNotEmpty
            ? profile.ownerName!.trim()
            : 'FACTORY OWNER');

    const role = 'Owner / Managing Director';

    final phone = profile.contact.phone.trim().isNotEmpty
        ? profile.contact.phone.trim()
        : (profile.contact.whatsapp?.trim() ?? 'N/A');

    final email = profile.contact.email?.trim();
    final address = profile.contact.fullAddress.isNotEmpty
        ? profile.contact.fullAddress
        : 'Factory Road, Industrial Area';

    final ntn = profile.legal.ntn?.trim();
    final strn = profile.legal.strn?.trim();

    final qrData = _generateVCardData(profile);

    return pw.Container(
      width: cardWidthPt,
      height: cardHeightPt,
      color: darkBg,
      child: pw.Stack(
        children: [
          // Top Gold Line Accent
          pw.Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: pw.Container(
              height: 2.0,
              color: goldAccent,
            ),
          ),

          // Main Layout
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Header: Owner & Role
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          ownerName.toUpperCase(),
                          style: pw.TextStyle(
                            font: fontBold,
                            color: PdfColors.white,
                            fontSize: 9.5,
                            letterSpacing: 0.6,
                          ),
                        ),
                        pw.SizedBox(height: 1),
                        pw.Text(
                          role.toUpperCase(),
                          style: pw.TextStyle(
                            font: fontBold,
                            color: goldAccent,
                            fontSize: 6.5,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1.5),
                      decoration: pw.BoxDecoration(
                        borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(2)),
                        border: pw.Border.all(color: goldAccent, width: 0.5),
                      ),
                      child: pw.Text(
                        profile.identity.businessName.isNotEmpty
                            ? profile.identity.businessName
                            : 'FACTORY',
                        style: pw.TextStyle(
                          font: fontBold,
                          color: goldAccent,
                          fontSize: 5.5,
                        ),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 4),

                pw.Container(
                  height: 0.4,
                  color: goldAccent,
                ),

                pw.SizedBox(height: 6),

                // 2-Column Body
                pw.Expanded(
                  child: pw.Row(
                    children: [
                      // Left Column: Contact Details
                      pw.Expanded(
                        flex: 12,
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildPdfContactRow(
                              'TEL:',
                              phone,
                              fontBold: fontBold,
                              fontRegular: fontRegular,
                            ),
                            if (email != null && email.isNotEmpty)
                              _buildPdfContactRow(
                                'EMAIL:',
                                email,
                                fontBold: fontBold,
                                fontRegular: fontRegular,
                              ),
                            _buildPdfContactRow(
                              'ADDR:',
                              address,
                              fontBold: fontBold,
                              fontRegular: fontRegular,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(width: 6),

                      // Vertical Divider
                      pw.Container(
                        width: 0.4,
                        color: goldAccent,
                      ),

                      pw.SizedBox(width: 6),

                      // Right Column: Tax Info + QR Code
                      pw.Expanded(
                        flex: 8,
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Column(
                              children: [
                                _buildPdfTaxRow('NTN:', ntn ?? 'N/A',
                                    fontBold: fontBold,
                                    fontRegular: fontRegular),
                                pw.SizedBox(height: 1),
                                _buildPdfTaxRow('STRN:', strn ?? 'N/A',
                                    fontBold: fontBold,
                                    fontRegular: fontRegular),
                              ],
                            ),
                            pw.Spacer(),

                            // QR Code
                            pw.Container(
                              padding: const pw.EdgeInsets.all(2),
                              color: PdfColors.white,
                              child: pw.BarcodeWidget(
                                barcode: pw.Barcode.qrCode(),
                                data: qrData,
                                width: 34,
                                height: 34,
                                color: darkBg,
                                backgroundColor: PdfColors.white,
                              ),
                            ),

                            pw.Spacer(),
                          ],
                        ),
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

  static pw.Widget _buildPdfContactRow(
    String label,
    String value, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
    int maxLines = 1,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: fontBold,
            color: goldAccent,
            fontSize: 6.5,
          ),
        ),
        pw.SizedBox(width: 3),
        pw.Expanded(
          child: pw.Text(
            value,
            maxLines: maxLines,
            style: pw.TextStyle(
              font: fontRegular,
              color: PdfColors.white,
              fontSize: 6.0,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfTaxRow(
    String label,
    String value, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: fontBold,
            color: goldAccent,
            fontSize: 5.5,
          ),
        ),
        pw.SizedBox(width: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: fontRegular,
            color: warmGray,
            fontSize: 5.5,
          ),
        ),
      ],
    );
  }
}
