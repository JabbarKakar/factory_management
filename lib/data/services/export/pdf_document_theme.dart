import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../domain/entities/bank_account.dart';
import '../../../domain/entities/factory_profile.dart';
import 'pdf_fonts.dart';

/// Resolved factory branding for PDF chrome (Grand Invoice / Collection Slip).
class PdfFactoryBranding {
  const PdfFactoryBranding({
    required this.factoryName,
    required this.tagline,
    this.owner,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.ntn,
    this.strn,
    this.footerNote,
    this.logoBytes,
    this.signatureBytes,
    this.stampBytes,
  });

  final String factoryName;
  final String tagline;
  final String? owner;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? ntn;
  final String? strn;
  final String? footerNote;
  final Uint8List? logoBytes;
  final Uint8List? signatureBytes;
  final Uint8List? stampBytes;

  /// Downloads logo / signature / stamp from FactoryProfile URLs.
  /// Falls back to bundled app logo when no uploaded logo is available.
  static Future<PdfFactoryBranding> resolve({
    FactoryProfile? profile,
    String fallbackName = 'FACTORY',
    Uint8List? logoBytes,
    Uint8List? signatureBytes,
    Uint8List? stampBytes,
    String defaultTagline =
        'PREMIUM NATURAL STONE PROCESSING & EXPORT',
  }) async {
    final identity = profile?.identity;
    final contact = profile?.contact;
    final legal = profile?.legal;
    final ownership = profile?.ownership;
    final invSettings = profile?.invoiceSettings;

    final rawBiz = identity?.businessName.trim();
    final rawName = profile?.name.trim();
    final factoryName = (rawBiz != null && rawBiz.isNotEmpty
            ? rawBiz
            : rawName != null && rawName.isNotEmpty
                ? rawName
                : fallbackName)
        .toUpperCase();

    final rawTagline = identity?.tagline?.trim();
    final tagline = rawTagline != null && rawTagline.isNotEmpty
        ? rawTagline.toUpperCase()
        : defaultTagline;

    final rawOwner = ownership?.ownerName?.trim();
    final rawProfileOwner = profile?.ownerName?.trim();
    final owner = rawOwner != null && rawOwner.isNotEmpty
        ? rawOwner
        : rawProfileOwner != null && rawProfileOwner.isNotEmpty
            ? rawProfileOwner
            : null;

    final rawAddr = contact?.fullAddress.trim();
    final rawProfileAddr = profile?.address?.trim();
    final address = rawAddr != null && rawAddr.isNotEmpty
        ? rawAddr
        : rawProfileAddr != null && rawProfileAddr.isNotEmpty
            ? rawProfileAddr
            : null;

    final rawPhone = contact?.phone.trim();
    final rawProfilePhone = profile?.phone?.trim();
    final phone = rawPhone != null && rawPhone.isNotEmpty
        ? rawPhone
        : rawProfilePhone != null && rawProfilePhone.isNotEmpty
            ? rawProfilePhone
            : null;

    final email = contact?.email?.trim().isNotEmpty == true
        ? contact!.email!.trim()
        : null;
    final website = contact?.website?.trim().isNotEmpty == true
        ? contact!.website!.trim()
        : null;
    final ntn =
        legal?.ntn?.trim().isNotEmpty == true ? legal!.ntn!.trim() : null;
    final strn =
        legal?.strn?.trim().isNotEmpty == true ? legal!.strn!.trim() : null;
    final footerNote =
        invSettings?.footerNote?.trim().isNotEmpty == true
            ? invSettings!.footerNote!.trim()
            : null;

    final downloaded = await Future.wait([
      _bytesFromUrlOrFallback(
        explicit: logoBytes,
        url: identity?.logoUrl,
        assetFallback: 'assets/images/app_logo.png',
      ),
      _bytesFromUrlOrFallback(
        explicit: signatureBytes,
        url: invSettings?.signatureImageUrl,
      ),
      _bytesFromUrlOrFallback(
        explicit: stampBytes,
        url: invSettings?.stampImageUrl,
      ),
    ]);

    return PdfFactoryBranding(
      factoryName: factoryName,
      tagline: tagline,
      owner: owner,
      address: address,
      phone: phone,
      email: email,
      website: website,
      ntn: ntn,
      strn: strn,
      footerNote: footerNote,
      logoBytes: downloaded[0],
      signatureBytes: downloaded[1],
      stampBytes: downloaded[2],
    );
  }

  static Future<Uint8List?> _bytesFromUrlOrFallback({
    Uint8List? explicit,
    String? url,
    String? assetFallback,
  }) async {
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final remote = await downloadImageBytes(url);
    if (remote != null && remote.isNotEmpty) return remote;

    if (assetFallback == null || assetFallback.isEmpty) return null;
    try {
      final byteData = await rootBundle.load(assetFallback);
      return byteData.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// Downloads image bytes from a Firebase / HTTPS URL.
  static Future<Uint8List?> downloadImageBytes(String? url) async {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    try {
      final uri = Uri.parse(trimmed);
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return null;
      }
      final client = HttpClient();
      try {
        final request = await client.getUrl(uri).timeout(
              const Duration(seconds: 20),
            );
        final response = await request.close().timeout(
              const Duration(seconds: 20),
            );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return null;
        }
        return await consolidateHttpClientResponseBytes(response);
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      return null;
    }
  }
}

/// Shared branded PDF chrome aligned with Grand Invoice & Collection Slip.
abstract final class PdfDocumentTheme {
  // Palette (Grand Invoice / Collection Slip)
  static const PdfColor navy = PdfColor.fromInt(0xFF1B365D);
  static const PdfColor accentBlue = PdfColor.fromInt(0xFF0F3F70);
  static const PdfColor mutedGrey = PdfColor.fromInt(0xFF556987);
  static const PdfColor borderLight = PdfColor.fromInt(0xFFD2E3FC);
  static const PdfColor bgLight = PdfColor.fromInt(0xFFF4F8FA);
  static const PdfColor goldBg = PdfColor.fromInt(0xFFFDF8E2);
  static const PdfColor greenText = PdfColor.fromInt(0xFF137333);
  static const PdfColor redText = PdfColor.fromInt(0xFFC5221F);
  static const PdfColor cardHeaderBg = PdfColor.fromInt(0xFF2C5282);

  /// Legacy aliases kept for any remaining callers.
  static const PdfColor primary = navy;
  static const PdfColor muted = mutedGrey;
  static const PdfColor border = borderLight;

  static const pw.EdgeInsets pageMargin =
      pw.EdgeInsets.symmetric(vertical: 28, horizontal: 28);

  static pw.TextStyle titleStyle(PdfFonts fonts, {double size = 16}) =>
      pw.TextStyle(
        font: fonts.bold,
        fontSize: size,
        color: accentBlue,
        letterSpacing: 0.3,
      );

  static pw.TextStyle subtitleStyle(PdfFonts fonts, {double size = 8}) =>
      pw.TextStyle(
        font: fonts.regular,
        fontSize: size,
        color: mutedGrey,
      );

  static pw.TextStyle bodyStyle(PdfFonts fonts, {bool bold = false}) =>
      pw.TextStyle(
        font: bold ? fonts.bold : fonts.regular,
        fontSize: 9,
        color: navy,
      );

  static pw.TextStyle sectionTitleStyle(PdfFonts fonts) => pw.TextStyle(
        font: fonts.bold,
        fontSize: 9.5,
        color: accentBlue,
        letterSpacing: 0.2,
      );

  /// Factory logo + name + contact block on the left, document badge on the right.
  static pw.Widget factoryHeader({
    required PdfFonts fonts,
    required PdfFactoryBranding branding,
    required String documentTitle,
    required List<({String label, String value})> metaRows,
    String? statusLabel,
    bool statusPositive = true,
    double logoSize = 48,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (branding.logoBytes != null &&
                      branding.logoBytes!.isNotEmpty) ...[
                    pw.Container(
                      width: logoSize,
                      height: logoSize,
                      child: pw.Image(
                        pw.MemoryImage(branding.logoBytes!),
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                    pw.SizedBox(width: 12),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          branding.factoryName,
                          style: titleStyle(fonts),
                        ),
                        pw.SizedBox(height: 1),
                        pw.Text(
                          branding.tagline,
                          style: pw.TextStyle(
                            font: fonts.bold,
                            fontSize: 7.5,
                            color: navy,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (branding.owner != null ||
                  branding.address != null ||
                  branding.phone != null ||
                  branding.email != null ||
                  branding.website != null ||
                  branding.strn != null ||
                  branding.ntn != null) ...[
                pw.SizedBox(height: 6),
                if (branding.owner != null)
                  pw.Text(
                    'Proprietor / Management: ${branding.owner}',
                    style: pw.TextStyle(
                      font: fonts.bold,
                      fontSize: 7,
                      color: navy,
                    ),
                  ),
                if (branding.address != null)
                  pw.Text(
                    'Factory & Facility: ${branding.address}',
                    style: subtitleStyle(fonts, size: 7),
                  ),
                if (branding.phone != null ||
                    branding.email != null ||
                    branding.website != null)
                  pw.Text(
                    [
                      if (branding.phone != null) 'Phone: ${branding.phone}',
                      if (branding.email != null) 'Email: ${branding.email}',
                      if (branding.website != null) 'Web: ${branding.website}',
                    ].join(' | '),
                    style: subtitleStyle(fonts, size: 7),
                  ),
                if (branding.strn != null || branding.ntn != null)
                  pw.Text(
                    [
                      if (branding.strn != null) 'STRN: ${branding.strn}',
                      if (branding.ntn != null) 'NTN: ${branding.ntn}',
                    ].join('  ·  '),
                    style: subtitleStyle(fonts, size: 7),
                  ),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              width: 170,
              padding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 10,
              ),
              decoration: const pw.BoxDecoration(
                color: navy,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                documentTitle.toUpperCase(),
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: 11,
                  color: PdfColors.white,
                  letterSpacing: 0.4,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 6),
            for (final row in metaRows) metaRow(fonts, row.label, row.value),
            if (statusLabel != null) ...[
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 14,
                ),
                decoration: pw.BoxDecoration(
                  color: statusPositive
                      ? const PdfColor.fromInt(0xFFE6F4EA)
                      : const PdfColor.fromInt(0xFFFCE8E6),
                  borderRadius: pw.BorderRadius.circular(3),
                  border: pw.Border.all(
                    color: statusPositive
                        ? const PdfColor.fromInt(0xFF34A853)
                        : const PdfColor.fromInt(0xFFEA4335),
                    width: 0.8,
                  ),
                ),
                child: pw.Text(
                  statusLabel.toUpperCase(),
                  style: pw.TextStyle(
                    font: fonts.bold,
                    fontSize: 8,
                    color: statusPositive ? greenText : redText,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static pw.Widget metaRow(PdfFonts fonts, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 7.5,
              color: mutedGrey,
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 8,
              color: navy,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget divider() => pw.Divider(
        color: borderLight,
        height: 16,
        thickness: 0.8,
      );

  /// MultiPage header strip (page 2+).
  static pw.Widget pageHeaderStrip({
    required PdfFonts fonts,
    required String left,
    required String right,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: borderLight, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            left,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 8,
              color: mutedGrey,
            ),
          ),
          pw.Text(
            right,
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 8,
              color: mutedGrey,
            ),
          ),
        ],
      ),
    );
  }

  /// MultiPage footer strip with page numbers.
  static pw.Widget pageFooterStrip({
    required PdfFonts fonts,
    required String factoryName,
    required pw.Context context,
    String certification =
        'ISO 9001:2015 Certified Marble & Natural Stone Processing',
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: borderLight, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              '$factoryName · $certification',
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 7.5,
                color: mutedGrey,
              ),
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 8,
              color: accentBlue,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget detailCard({
    required PdfFonts fonts,
    required String title,
    required List<pw.Widget> rows,
  }) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderLight, width: 0.8),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            decoration: const pw.BoxDecoration(
              color: cardHeaderBg,
              borderRadius: pw.BorderRadius.vertical(
                top: pw.Radius.circular(3),
              ),
            ),
            child: pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 8,
                color: PdfColors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: rows,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget cardRow(PdfFonts fonts, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 8,
                color: mutedGrey,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 8.5,
                color: navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget infoBanner({
    required PdfFonts fonts,
    required String title,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bgLight,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: borderLight, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title.toUpperCase(), style: sectionTitleStyle(fonts)),
          pw.SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  /// Label/value metrics laid out in a single horizontal row (e.g. Bill To).
  static pw.Widget infoItemsRow({
    required PdfFonts fonts,
    required List<({String label, String value})> items,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  items[i].label,
                  style: pw.TextStyle(
                    font: fonts.regular,
                    fontSize: 7.5,
                    color: mutedGrey,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  items[i].value,
                  style: pw.TextStyle(
                    font: fonts.bold,
                    fontSize: 8.5,
                    color: navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static pw.TableRow tableHeaderRow(PdfFonts fonts, List<String> labels) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: navy),
      children: [
        for (final label in labels)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 7.5,
                color: PdfColors.white,
              ),
            ),
          ),
      ],
    );
  }

  /// Zebra data row — white / light blue like Collection Slip.
  static pw.TableRow tableDataRow(
    PdfFonts fonts,
    List<String> values, {
    int index = 0,
    bool bold = false,
  }) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: index % 2 == 1 ? bgLight : PdfColors.white,
      ),
      children: [
        for (final value in values)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: bold ? fonts.bold : fonts.regular,
                fontSize: 8,
                color: navy,
              ),
            ),
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
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: bold ? fonts.bold : fonts.regular,
                fontSize: 9,
                color: bold ? navy : mutedGrey,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 9,
              color: navy,
            ),
          ),
        ],
      ),
    );
  }

  /// Legacy simple header (kept for compatibility; prefer [factoryHeader]).
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
                pw.Text(subtitle, style: subtitleStyle(fonts, size: 9)),
              ],
            ],
          ),
        ),
        if (rightLabel != null)
          pw.Text(rightLabel, style: subtitleStyle(fonts, size: 9)),
      ],
    );
  }

  /// Structured bank / remittance card (shared by Sales + Job Work invoices).
  static pw.Widget bankRemittanceBlock({
    required PdfFonts fonts,
    required List<BankAccount> accounts,
    String title = 'BANK & REMITTANCE DETAILS',
    String emptyHint =
        'Bank details are not configured in Factory Settings.',
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderLight, width: 0.8),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 8.5,
              color: accentBlue,
            ),
          ),
          pw.SizedBox(height: 4),
          if (accounts.isEmpty)
            pw.Text(
              emptyHint,
              style: subtitleStyle(fonts, size: 7.5),
            )
          else
            for (var i = 0; i < accounts.length; i++) ...[
              _bankDetailRow(fonts, 'Account Title:', accounts[i].accountName),
              _bankDetailRow(
                fonts,
                'Account Number:',
                accounts[i].accountNumber,
              ),
              _bankDetailRow(
                fonts,
                'Bank Name:',
                [
                  accounts[i].bankName,
                  if (accounts[i].branch != null &&
                      accounts[i].branch!.trim().isNotEmpty)
                    '(${accounts[i].branch!.trim()})',
                ].join(' '),
              ),
              if (accounts[i].iban != null &&
                  accounts[i].iban!.trim().isNotEmpty)
                _bankDetailRow(fonts, 'IBAN:', accounts[i].iban!),
              if (accounts[i].swiftCode != null &&
                  accounts[i].swiftCode!.trim().isNotEmpty)
                _bankDetailRow(fonts, 'SWIFT / BIC:', accounts[i].swiftCode!),
              if (i < accounts.length - 1)
                pw.Divider(color: borderLight, height: 8),
            ],
        ],
      ),
    );
  }

  static pw.Widget _bankDetailRow(
    PdfFonts fonts,
    String label,
    String value,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 8,
                color: mutedGrey,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 8,
                color: navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Terms block with optional factory defaults for Sales / Job Work.
  static pw.Widget termsAndConditionsBlock({
    required PdfFonts fonts,
    String? configuredTerms,
    required String defaultTerms,
    String title = 'TERMS & CONDITIONS',
  }) {
    final raw = configuredTerms?.trim();
    final text = (raw != null && raw.isNotEmpty) ? raw : defaultTerms;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: 7.5,
            color: navy,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          text,
          style: pw.TextStyle(
            font: fonts.regular,
            fontSize: 6.5,
            color: mutedGrey,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  static const String defaultSalesTerms =
      '1. Please review quantities and pricing and report any discrepancies within 7 days.\n'
      '2. Payments are to be settled as per agreed commercial terms.\n'
      '3. Goods remain the property of the seller until full payment is received.';

  static const String defaultJobWorkTerms =
      '1. Please review cutting charge calculations and report any discrepancies within 7 days.\n'
      '2. Payments are to be settled as per agreed commercial terms.\n'
      '3. All stone materials delivered remain under job work custody until final clearance.';

  /// Signature / stamp authorization block for document footers.
  static pw.Widget authorizationBlock({
    required PdfFonts fonts,
    required PdfFactoryBranding branding,
    String preparedLabel = 'Prepared By / Dispatch Officer',
    String authorizedLabel = 'Authorized Signature & Stamp',
    bool showPreparedLine = true,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        if (showPreparedLine)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(height: 42),
                pw.Container(
                  width: 140,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: navy, width: 1),
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  preparedLabel,
                  style: pw.TextStyle(
                    font: fonts.bold,
                    fontSize: 7.5,
                    color: navy,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        if (showPreparedLine) pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(
                height: 48,
                child: pw.Stack(
                  alignment: pw.Alignment.center,
                  children: [
                    if (branding.stampBytes != null &&
                        branding.stampBytes!.isNotEmpty)
                      pw.Opacity(
                        opacity: 0.85,
                        child: pw.Image(
                          pw.MemoryImage(branding.stampBytes!),
                          width: 56,
                          height: 56,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    if (branding.signatureBytes != null &&
                        branding.signatureBytes!.isNotEmpty)
                      pw.Image(
                        pw.MemoryImage(branding.signatureBytes!),
                        width: 110,
                        height: 42,
                        fit: pw.BoxFit.contain,
                      )
                    else
                      pw.Container(
                        width: 140,
                        margin: const pw.EdgeInsets.only(top: 36),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: navy, width: 1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                authorizedLabel,
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: 7.5,
                  color: navy,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                '${branding.factoryName} MANAGEMENT',
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: 7,
                  color: accentBlue,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Compact authorized signature + stamp for invoice-style footers.
  static pw.Widget authorizedSignatureColumn({
    required PdfFonts fonts,
    required PdfFactoryBranding branding,
    String label = 'Authorized Signature & Stamp',
    double width = 140,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(
          width: width,
          height: 52,
          child: pw.Stack(
            alignment: pw.Alignment.center,
            children: [
              if (branding.stampBytes != null &&
                  branding.stampBytes!.isNotEmpty)
                pw.Opacity(
                  opacity: 0.85,
                  child: pw.Image(
                    pw.MemoryImage(branding.stampBytes!),
                    width: 54,
                    height: 54,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              if (branding.signatureBytes != null &&
                  branding.signatureBytes!.isNotEmpty)
                pw.Image(
                  pw.MemoryImage(branding.signatureBytes!),
                  width: width - 20,
                  height: 40,
                  fit: pw.BoxFit.contain,
                )
              else
                pw.Container(
                  width: width,
                  margin: const pw.EdgeInsets.only(top: 38),
                  height: 0.8,
                  color: mutedGrey,
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: 7.5,
            color: navy,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          '${branding.factoryName} MANAGEMENT',
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: 7.5,
            color: accentBlue,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
}
