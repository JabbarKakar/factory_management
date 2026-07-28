import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/job_work_sizes.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/job_work_charges_calculator.dart';
import '../../../domain/entities/factory_profile.dart';
import '../../../domain/entities/job_work_collection.dart';
import '../../../domain/entities/job_work_load.dart';
import '../../../domain/entities/job_work_order.dart';
import '../../repositories/factory_repository.dart';
import '../../repositories/job_work_load_repository.dart';
import '../../repositories/job_work_repository.dart';
import 'pdf_fonts.dart';

class JobWorkCollectionSlipPdfExporter {
  JobWorkCollectionSlipPdfExporter({
    FactoryRepository? factoryRepository,
    JobWorkLoadRepository? loadRepository,
    JobWorkRepository? jobWorkRepository,
  })  : _factoryRepository = factoryRepository,
        _loadRepository = loadRepository,
        _jobWorkRepository = jobWorkRepository;

  final FactoryRepository? _factoryRepository;
  final JobWorkLoadRepository? _loadRepository;
  final JobWorkRepository? _jobWorkRepository;

  static final NumberFormat _commaFormatter = NumberFormat('#,##0.00');
  static final NumberFormat _wholeFormatter = NumberFormat('#,##0');

  // Color Palette matching GrandInvoicePdfTemplate & SingleLoadInvoicePdfExporter
  static const PdfColor _navy = PdfColor.fromInt(0xFF1B365D);
  static const PdfColor _accentBlue = PdfColor.fromInt(0xFF0F3F70);
  static const PdfColor _mutedGrey = PdfColor.fromInt(0xFF556987);
  static const PdfColor _borderLight = PdfColor.fromInt(0xFFD2E3FC);
  static const PdfColor _bgLight = PdfColor.fromInt(0xFFF4F8FA);
  static const PdfColor _greenText = PdfColor.fromInt(0xFF137333);
  static const PdfColor _greenBg = PdfColor.fromInt(0xFFE6F4EA);
  static const PdfColor _cardHeaderBg = PdfColor.fromInt(0xFF2C5282);

  Future<Uint8List> generateCollectionSlipPdf({
    required JobWorkCollection collection,
    FactoryProfile? factoryProfile,
    Uint8List? logoBytes,
    String factoryName = AppStrings.appName,
    JobWorkLoad? load,
    JobWorkOrder? jobWorkOrder,
    double? smallStockRate,
    double? largeStockRate,
  }) async {
    final doc = await buildCollectionSlipPdf(
      collection: collection,
      factoryProfile: factoryProfile,
      logoBytes: logoBytes,
      factoryName: factoryName,
      load: load,
      jobWorkOrder: jobWorkOrder,
      smallStockRate: smallStockRate,
      largeStockRate: largeStockRate,
    );
    return doc.save();
  }

  Future<pw.Document> buildCollectionSlipPdf({
    required JobWorkCollection collection,
    FactoryProfile? factoryProfile,
    Uint8List? logoBytes,
    String factoryName = AppStrings.appName,
    JobWorkLoad? load,
    JobWorkOrder? jobWorkOrder,
    double? smallStockRate,
    double? largeStockRate,
  }) async {
    final fonts = await PdfFonts.load();
    final doc = pw.Document(theme: fonts.theme);
    final dateFormat = DateFormat('MMM dd, yyyy');

    // Resolve FactoryProfile from repository if omitted
    final factoryRepo = _factoryRepository ??
        (getIt.isRegistered<FactoryRepository>()
            ? getIt<FactoryRepository>()
            : null);
    final profile = factoryProfile ??
        (factoryRepo != null && collection.factoryId.isNotEmpty
            ? await factoryRepo.getFactory(collection.factoryId)
            : null);

    // Resolve load and order for rate resolution if omitted
    final loadRepo = _loadRepository ??
        (getIt.isRegistered<JobWorkLoadRepository>()
            ? getIt<JobWorkLoadRepository>()
            : null);
    final jobWorkRepo = _jobWorkRepository ??
        (getIt.isRegistered<JobWorkRepository>()
            ? getIt<JobWorkRepository>()
            : null);

    final resolvedLoad = load ??
        (loadRepo != null &&
                collection.loadId != null &&
                collection.loadId!.isNotEmpty
            ? await loadRepo.getLoad(collection.loadId!)
            : null);

    final resolvedOrder = jobWorkOrder ??
        (jobWorkRepo != null && collection.jobWorkOrderId.isNotEmpty
            ? await jobWorkRepo.getJobWorkOrder(collection.jobWorkOrderId)
            : null);

    double resolvedSmallRate = smallStockRate ?? 0;
    double resolvedLargeRate = largeStockRate ?? 0;

    if (resolvedSmallRate <= 0) {
      if (resolvedLoad != null) {
        resolvedSmallRate =
            JobWorkChargesCalculator.defaultSmallPricePerSqFtForLoad(
                resolvedLoad);
      } else if (resolvedOrder != null) {
        resolvedSmallRate =
            JobWorkChargesCalculator.defaultSmallPricePerSqFt(resolvedOrder);
      }
    }

    if (resolvedLargeRate <= 0) {
      if (resolvedLoad != null) {
        resolvedLargeRate =
            JobWorkChargesCalculator.defaultLargePricePerSqFtForLoad(
                resolvedLoad);
      } else if (resolvedOrder != null) {
        resolvedLargeRate =
            JobWorkChargesCalculator.defaultLargePricePerSqFt(resolvedOrder);
      }
    }

    // Consolidated Material Breakdown (Small vs Large Stock)
    int smallPieces = 0;
    double smallSqFt = 0.0;
    int largePieces = 0;
    double largeSqFt = 0.0;

    for (final item in collection.lineItems) {
      final isSmall = item.isSmall || JobWorkSizes.isSmall(item.size);
      if (isSmall) {
        smallPieces += item.pieces;
        smallSqFt += item.squareFeet;
      } else {
        largePieces += item.pieces;
        largeSqFt += item.squareFeet;
      }
    }

    final smallCharges = smallSqFt * resolvedSmallRate;
    final largeCharges = largeSqFt * resolvedLargeRate;

    final totalPieces = smallPieces + largePieces;
    final totalSqFt = smallSqFt + largeSqFt;
    final totalCharges = smallCharges + largeCharges;

    // Resolve logo bytes if omitted
    if (logoBytes == null) {
      try {
        final byteData = await rootBundle.load('assets/images/app_logo.png');
        logoBytes = byteData.buffer.asUint8List();
      } catch (_) {}
    }

    final identity = profile?.identity;
    final contact = profile?.contact;
    final legal = profile?.legal;
    final ownership = profile?.ownership;
    final invSettings = profile?.invoiceSettings;

    final rawBizName = identity?.businessName.trim();
    final rawFacName = profile?.name.trim();
    final resolvedFactoryName = (rawBizName != null && rawBizName.isNotEmpty
            ? rawBizName
            : rawFacName != null && rawFacName.isNotEmpty
                ? rawFacName
                : factoryName)
        .toUpperCase();

    final rawTagline = identity?.tagline?.trim();
    final tagline =
        rawTagline != null && rawTagline.isNotEmpty ? rawTagline : null;

    final rawOwner = ownership?.ownerName?.trim();
    final rawProfileOwner = profile?.ownerName?.trim();
    final factoryOwner = rawOwner != null && rawOwner.isNotEmpty
        ? rawOwner
        : rawProfileOwner != null && rawProfileOwner.isNotEmpty
            ? rawProfileOwner
            : null;

    final rawFullAddr = contact?.fullAddress.trim();
    final rawProfileAddr = profile?.address?.trim();
    final factoryAddress = rawFullAddr != null && rawFullAddr.isNotEmpty
        ? rawFullAddr
        : rawProfileAddr != null && rawProfileAddr.isNotEmpty
            ? rawProfileAddr
            : null;

    final rawPhone = contact?.phone.trim();
    final rawProfilePhone = profile?.phone?.trim();
    final factoryPhone = rawPhone != null && rawPhone.isNotEmpty
        ? rawPhone
        : rawProfilePhone != null && rawProfilePhone.isNotEmpty
            ? rawProfilePhone
            : null;

    final rawEmail = contact?.email?.trim();
    final email = rawEmail != null && rawEmail.isNotEmpty ? rawEmail : null;

    final rawWeb = contact?.website?.trim();
    final website = rawWeb != null && rawWeb.isNotEmpty ? rawWeb : null;

    final rawNtn = legal?.ntn?.trim();
    final ntn = rawNtn != null && rawNtn.isNotEmpty ? rawNtn : null;

    final rawStrn = legal?.strn?.trim();
    final strn = rawStrn != null && rawStrn.isNotEmpty ? rawStrn : null;

    final rawFooter = invSettings?.footerNote?.trim();
    final footerNoteText = rawFooter != null && rawFooter.isNotEmpty
        ? rawFooter
        : '$resolvedFactoryName · ISO 9001:2015 Certified Marble & Natural Stone Processing';

    final collectedDateStr = dateFormat.format(collection.collectedAt);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(vertical: 24, horizontal: 32),
        theme: fonts.theme,
        header: (context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.only(bottom: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: _borderLight, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '$resolvedFactoryName · MATERIAL COLLECTION SLIP',
                  style: pw.TextStyle(
                    font: fonts.bold,
                    fontSize: 8,
                    color: _mutedGrey,
                  ),
                ),
                pw.Text(
                  'Slip No: ${collection.collectionNumber}',
                  style: pw.TextStyle(
                    font: fonts.regular,
                    fontSize: 8,
                    color: _mutedGrey,
                  ),
                ),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 14),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: _borderLight, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    footerNoteText,
                    style: pw.TextStyle(
                      font: fonts.regular,
                      fontSize: 7.5,
                      color: _mutedGrey,
                    ),
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(
                    font: fonts.bold,
                    fontSize: 8,
                    color: _accentBlue,
                  ),
                ),
              ],
            ),
          );
        },
        build: (context) => [
          // Section 1: Factory Header & Header Card
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left Column: Logo & Dynamic Branding Details
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (logoBytes != null && logoBytes.isNotEmpty) ...[
                          pw.Container(
                            width: 56,
                            height: 56,
                            child: pw.Image(
                              pw.MemoryImage(logoBytes),
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                          pw.SizedBox(width: 14),
                        ],
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                resolvedFactoryName,
                                style: pw.TextStyle(
                                  font: fonts.bold,
                                  fontSize: 16,
                                  color: _accentBlue,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              if (tagline != null) ...[
                                pw.SizedBox(height: 1),
                                pw.Text(
                                  tagline,
                                  style: pw.TextStyle(
                                    font: fonts.bold,
                                    fontSize: 7.5,
                                    color: _navy,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (factoryOwner != null ||
                        factoryAddress != null ||
                        factoryPhone != null ||
                        email != null ||
                        website != null ||
                        strn != null ||
                        ntn != null) ...[
                      pw.SizedBox(height: 8),
                      if (factoryOwner != null)
                        pw.Text(
                          'Proprietor / Management: $factoryOwner',
                          style: pw.TextStyle(
                            font: fonts.bold,
                            fontSize: 7,
                            color: _navy,
                          ),
                        ),
                      if (factoryAddress != null)
                        pw.Text(
                          'Factory & Facility: $factoryAddress',
                          style: pw.TextStyle(
                            font: fonts.regular,
                            fontSize: 7,
                            color: _mutedGrey,
                          ),
                        ),
                      if (factoryPhone != null ||
                          email != null ||
                          website != null)
                        pw.Text(
                          [
                            if (factoryPhone != null) 'Phone: $factoryPhone',
                            if (email != null) 'Email: $email',
                            if (website != null) 'Web: $website',
                          ].join(' | '),
                          style: pw.TextStyle(
                            font: fonts.regular,
                            fontSize: 7,
                            color: _mutedGrey,
                          ),
                        ),
                      if (strn != null || ntn != null)
                        pw.Text(
                          [
                            if (strn != null) 'STRN: $strn',
                            if (ntn != null) 'NTN: $ntn',
                          ].join('  ·  '),
                          style: pw.TextStyle(
                            font: fonts.regular,
                            fontSize: 7,
                            color: _mutedGrey,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              // Right Column: Collection Slip Header Card
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 185,
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 7,
                      horizontal: 12,
                    ),
                    decoration: const pw.BoxDecoration(
                      color: _navy,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'COLLECTION SLIP',
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 14,
                        color: PdfColors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _metaRow(fonts, 'Slip No:', collection.collectionNumber),
                  _metaRow(fonts, 'Date Issued:', collectedDateStr),
                  _metaRow(fonts, 'Job Work ID:', collection.jobWorkNumber),
                  if (collection.loadNumber != null &&
                      collection.loadNumber!.trim().isNotEmpty)
                    _metaRow(fonts, 'Load No:', collection.loadNumber!),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 18,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _greenBg,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: _greenText, width: 0.8),
                    ),
                    child: pw.Text(
                      collection.status.label.toUpperCase(),
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 9,
                        color: _greenText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Divider(color: _borderLight, thickness: 1),
          pw.SizedBox(height: 12),

          // Section 2: Two-Column Card Grid (Customer & Receiver Details + Transport & Vehicle Info)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Card 1: Customer & Receiver Details
              pw.Expanded(
                child: _buildDetailCard(
                  fonts: fonts,
                  title: 'CUSTOMER & RECEIVER DETAILS',
                  rows: [
                    _cardRow(
                      fonts,
                      'Customer Name:',
                      Formatters.textForExport(collection.customerName),
                    ),
                    if (collection.receiverName != null &&
                        collection.receiverName!.trim().isNotEmpty)
                      _cardRow(
                        fonts,
                        'Received By:',
                        Formatters.textForExport(collection.receiverName!),
                      ),
                    if (collection.receiverPhone != null &&
                        collection.receiverPhone!.trim().isNotEmpty)
                      _cardRow(
                        fonts,
                        'Receiver Phone:',
                        Formatters.textForExport(collection.receiverPhone!),
                      ),
                    if (collection.receiverAddress != null &&
                        collection.receiverAddress!.trim().isNotEmpty)
                      _cardRow(
                        fonts,
                        'Delivery Address:',
                        Formatters.textForExport(collection.receiverAddress!),
                      ),
                    if (collection.receiverEmail != null &&
                        collection.receiverEmail!.trim().isNotEmpty)
                      _cardRow(
                        fonts,
                        'Receiver Email:',
                        Formatters.textForExport(collection.receiverEmail!),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 14),
              // Card 2: Transport & Vehicle Details
              pw.Expanded(
                child: _buildDetailCard(
                  fonts: fonts,
                  title: 'TRANSPORT & VEHICLE INFO',
                  rows: [
                    if (collection.vehicleNumber != null &&
                        collection.vehicleNumber!.trim().isNotEmpty)
                      _cardRow(
                        fonts,
                        'Vehicle / Plate #:',
                        Formatters.textForExport(collection.vehicleNumber!),
                      ),
                    if (collection.driverName != null &&
                        collection.driverName!.trim().isNotEmpty)
                      _cardRow(
                        fonts,
                        'Driver Name:',
                        Formatters.textForExport(collection.driverName!),
                      ),
                    if (collection.driverPhone != null &&
                        collection.driverPhone!.trim().isNotEmpty)
                      _cardRow(
                        fonts,
                        'Driver Phone:',
                        Formatters.textForExport(collection.driverPhone!),
                      ),
                    if (collection.driverCnic != null &&
                        collection.driverCnic!.trim().isNotEmpty)
                      _cardRow(
                        fonts,
                        'Driver CNIC / ID:',
                        Formatters.textForExport(collection.driverCnic!),
                      ),
                    if (collection.vehicleType != null &&
                        collection.vehicleType!.trim().isNotEmpty)
                      _cardRow(
                        fonts,
                        'Vehicle Type / Mode:',
                        Formatters.textForExport(collection.vehicleType!),
                      ),
                    if ((collection.vehicleNumber == null ||
                            collection.vehicleNumber!.isEmpty) &&
                        (collection.driverName == null ||
                            collection.driverName!.isEmpty))
                      _cardRow(
                        fonts,
                        'Transport Info:',
                        'Self / Factory Direct Pickup',
                      ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 16),

          // Section 3: Line Items / Consolidated Materials Table
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            decoration: const pw.BoxDecoration(
              color: _cardHeaderBg,
              borderRadius:
                  pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'ITEMS COLLECTED & DISPATCHED SUMMARY',
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 9,
                color: PdfColors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
          pw.Table(
            border: pw.TableBorder.all(color: _borderLight, width: 0.8),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.8),
              1: pw.FlexColumnWidth(1.5),
              2: pw.FlexColumnWidth(1.8),
              3: pw.FlexColumnWidth(1.8),
              4: pw.FlexColumnWidth(2.1),
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _navy),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    child: pw.Text(
                      'SIZE CATEGORY',
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 8,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    child: pw.Text(
                      'COLLECTED PCS',
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 8,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    child: pw.Text(
                      'COLLECTED SQ. FT.',
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 8,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    child: pw.Text(
                      'CUTTING RATE (PKR)',
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 8,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    child: pw.Text(
                      'CUTTING CHARGES (PKR)',
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 8,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
              // Small Sizes Row
              if (smallPieces > 0 ||
                  smallSqFt > 0 ||
                  collection.lineItems.isEmpty ||
                  (largePieces == 0 && largeSqFt == 0))
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.white),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: pw.Text(
                        'Small Sizes',
                        style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: 8.5,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: pw.Text(
                        _wholeFormatter.format(smallPieces),
                        style: pw.TextStyle(
                          font: fonts.regular,
                          fontSize: 8.5,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: pw.Text(
                        _commaFormatter.format(smallSqFt),
                        style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: 8.5,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: pw.Text(
                        resolvedSmallRate > 0
                            ? _commaFormatter.format(resolvedSmallRate)
                            : '0.00',
                        style: pw.TextStyle(
                          font: fonts.regular,
                          fontSize: 8.5,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: pw.Text(
                        _commaFormatter.format(smallCharges),
                        style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: 8.5,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              // Large Sizes Row
              if (largePieces > 0 ||
                  largeSqFt > 0 ||
                  (smallPieces == 0 &&
                      smallSqFt == 0 &&
                      collection.lineItems.isNotEmpty))
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _bgLight),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: pw.Text(
                        'Large Sizes',
                        style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: 8.5,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: pw.Text(
                        _wholeFormatter.format(largePieces),
                        style: pw.TextStyle(
                          font: fonts.regular,
                          fontSize: 8.5,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: pw.Text(
                        _commaFormatter.format(largeSqFt),
                        style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: 8.5,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: pw.Text(
                        resolvedLargeRate > 0
                            ? _commaFormatter.format(resolvedLargeRate)
                            : '0.00',
                        style: pw.TextStyle(
                          font: fonts.regular,
                          fontSize: 8.5,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: pw.Text(
                        _commaFormatter.format(largeCharges),
                        style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: 8.5,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Total Collected Summary Row Container
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: const pw.BoxDecoration(
              color: _bgLight,
              border: pw.Border(
                left: pw.BorderSide(color: _borderLight, width: 0.8),
                right: pw.BorderSide(color: _borderLight, width: 0.8),
                bottom: pw.BorderSide(color: _borderLight, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL COLLECTED SUMMARY:',
                  style: pw.TextStyle(
                    font: fonts.bold,
                    fontSize: 8.5,
                    color: _navy,
                  ),
                ),
                pw.Row(
                  children: [
                    pw.Text(
                      'Total Pieces: ${_wholeFormatter.format(totalPieces)} pcs',
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 8.5,
                        color: _navy,
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Text(
                      'Total Sq. Ft.: ${_commaFormatter.format(totalSqFt)} sq ft',
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 8.5,
                        color: _accentBlue,
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Text(
                      'Total Charges: PKR ${_commaFormatter.format(totalCharges)}',
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 8.5,
                        color: _greenText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Section 4: Notes / Instructions Block (if present)
          if (collection.notes != null &&
              collection.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: _bgLight,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: _borderLight, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'NOTES & DISPATCH INSTRUCTIONS:',
                    style: pw.TextStyle(
                      font: fonts.bold,
                      fontSize: 8,
                      color: _navy,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    Formatters.textForExport(collection.notes!),
                    style: pw.TextStyle(
                      font: fonts.regular,
                      fontSize: 8,
                      color: _mutedGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],

          pw.SizedBox(height: 24),

          // Section 5: Sign-off & Signatures Block
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: double.infinity,
                      height: 28,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: _navy, width: 1),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      AppStrings.factorySignature.toUpperCase(),
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 8,
                        color: _navy,
                      ),
                    ),
                    pw.Text(
                      'Authorized Dispatch Stamp / Sign',
                      style: pw.TextStyle(
                        font: fonts.regular,
                        fontSize: 7,
                        color: _mutedGrey,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 32),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: double.infinity,
                      height: 28,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: _navy, width: 1),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      (collection.receiverName != null &&
                              collection.receiverName!.trim().isNotEmpty
                          ? 'RECEIVER: ${collection.receiverName!.toUpperCase()}'
                          : AppStrings.customerSignature.toUpperCase()),
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 8,
                        color: _navy,
                      ),
                    ),
                    pw.Text(
                      'Consignee Acknowledgment & Gate Release',
                      style: pw.TextStyle(
                        font: fonts.regular,
                        fontSize: 7,
                        color: _mutedGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.Text(
              'All stone products listed above have been inspected and collected in good order. Material custody is transferred upon signature.',
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 7,
                color: _mutedGrey,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _metaRow(PdfFonts fonts, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 8,
              color: _mutedGrey,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 8.5,
              color: _navy,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailCard({
    required PdfFonts fonts,
    required String title,
    required List<pw.Widget> rows,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _bgLight,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _borderLight, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: const pw.BoxDecoration(
              color: _cardHeaderBg,
              borderRadius: pw.BorderRadius.vertical(
                top: pw.Radius.circular(3),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 8,
                color: PdfColors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: rows,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cardRow(PdfFonts fonts, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 85,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 7.5,
                color: _navy,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 7.5,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
