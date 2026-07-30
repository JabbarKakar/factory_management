import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/job_work_sizes.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/job_work_charges_calculator.dart';
import '../../../domain/entities/factory_profile.dart';
import '../../../domain/entities/job_work_collection.dart';
import '../../../domain/entities/job_work_load.dart';
import '../../../domain/entities/job_work_order.dart';
import '../../repositories/factory_repository.dart';
import '../../repositories/job_work_load_repository.dart';
import '../../repositories/job_work_repository.dart';
import 'pdf_document_theme.dart';
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

  // Compact Color Palette matching GrandInvoicePdfTemplate & SingleLoadInvoicePdfExporter
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

    double getItemRate(JobWorkCollectionLineItem item) {
      final isSmall = JobWorkSizes.isSmall(item.size) ||
          (item.isSmall && !JobWorkSizes.isLarge(item.size));

      final outputs = isSmall
          ? (resolvedLoad?.output?.smallStockOutputs ??
              resolvedOrder?.output?.smallStockOutputs ??
              const [])
          : (resolvedLoad?.output?.largeStockOutputs ??
              resolvedOrder?.output?.largeStockOutputs ??
              const []);

      for (final o in outputs) {
        if (o.size.trim().toLowerCase() == item.size.trim().toLowerCase() &&
            o.pricePerSqFt > 0) {
          return o.pricePerSqFt;
        }
      }

      if (isSmall) {
        if (resolvedSmallRate > 0) return resolvedSmallRate;
        if (resolvedLoad != null && resolvedLoad.smallStockPrice > 0) {
          return resolvedLoad.smallStockPrice;
        }
        if (resolvedOrder != null && resolvedOrder.smallStockPrice > 0) {
          return resolvedOrder.smallStockPrice;
        }
      } else {
        if (resolvedLargeRate > 0) return resolvedLargeRate;
        if (resolvedLoad != null && resolvedLoad.largeStockPrice > 0) {
          return resolvedLoad.largeStockPrice;
        }
        if (resolvedOrder != null && resolvedOrder.largeStockPrice > 0) {
          return resolvedOrder.largeStockPrice;
        }
      }

      if (resolvedLoad != null && resolvedLoad.agreedRate > 0) {
        return resolvedLoad.agreedRate;
      }
      if (resolvedOrder != null && resolvedOrder.agreedRate > 0) {
        return resolvedOrder.agreedRate;
      }

      return 0.0;
    }

    // Filter active items with quantity
    final activeItems = collection.lineItems
        .where((item) => item.pieces > 0 || item.squareFeet > 0)
        .toList();
    final itemsToDisplay =
        activeItems.isNotEmpty ? activeItems : collection.lineItems;

    final smallItems = itemsToDisplay
        .where((i) =>
            JobWorkSizes.isSmall(i.size) ||
            (i.isSmall && !JobWorkSizes.isLarge(i.size)))
        .toList();

    final largeItems = itemsToDisplay
        .where((i) =>
            JobWorkSizes.isLarge(i.size) ||
            (!i.isSmall && !JobWorkSizes.isSmall(i.size)))
        .toList();

    final categorizedSet = {...smallItems, ...largeItems};
    final uncategorized = itemsToDisplay
        .where((item) => !categorizedSet.contains(item))
        .toList();
    if (uncategorized.isNotEmpty) {
      smallItems.addAll(uncategorized);
    }

    final totalRows = smallItems.length + largeItems.length;

    // Density calculation for auto-fit sizing
    final isHighDensity = totalRows > 12;
    final isUltraDensity = totalRows > 22;

    final double cellPaddingV = isUltraDensity ? 1.8 : (isHighDensity ? 2.5 : 3.5);
    final double cellPaddingH = isUltraDensity ? 3.0 : (isHighDensity ? 4.0 : 5.0);
    final double tableFontSize = isUltraDensity ? 6.2 : (isHighDensity ? 6.8 : 7.5);
    final double headerFontSize = isUltraDensity ? 6.5 : (isHighDensity ? 7.0 : 8.0);
    final double sectionGap = isUltraDensity ? 3.0 : (isHighDensity ? 5.0 : 6.0);
    final bool useSideBySideTables = totalRows > 14 && smallItems.isNotEmpty && largeItems.isNotEmpty;

    int totalSmallPcs = 0;
    double totalSmallSqFt = 0.0;
    double totalSmallCharges = 0.0;

    for (final item in smallItems) {
      final rate = getItemRate(item);
      final charges =
          item.squareFeet > 0 ? item.squareFeet * rate : item.pieces * rate;
      totalSmallPcs += item.pieces;
      totalSmallSqFt += item.squareFeet;
      totalSmallCharges += charges;
    }

    int totalLargePcs = 0;
    double totalLargeSqFt = 0.0;
    double totalLargeCharges = 0.0;

    for (final item in largeItems) {
      final rate = getItemRate(item);
      final charges =
          item.squareFeet > 0 ? item.squareFeet * rate : item.pieces * rate;
      totalLargePcs += item.pieces;
      totalLargeSqFt += item.squareFeet;
      totalLargeCharges += charges;
    }

    final grandTotalPcs = totalSmallPcs + totalLargePcs;
    final grandTotalSqFt = totalSmallSqFt + totalLargeSqFt;
    final grandTotalCharges = totalSmallCharges + totalLargeCharges;

    // Resolve uploaded logo / signature / stamp (falls back to app logo).
    final branding = await PdfFactoryBranding.resolve(
      profile: profile,
      fallbackName: factoryName,
      logoBytes: logoBytes,
    );
    logoBytes = branding.logoBytes;

    final resolvedFactoryName = branding.factoryName;
    final tagline = branding.tagline;
    final factoryOwner = branding.owner;
    final factoryAddress = branding.address;
    final factoryPhone = branding.phone;
    final email = branding.email;
    final website = branding.website;
    final ntn = branding.ntn;
    final strn = branding.strn;
    final footerNoteText = branding.footerNote ??
        '$resolvedFactoryName · ISO 9001:2015 Certified Marble & Natural Stone Processing';

    final invSettings = profile?.invoiceSettings;
    final contact = profile?.contact;

    final bankAcc = profile != null && profile.bankAccounts.isNotEmpty
        ? profile.bankAccounts.first
        : null;
    final bankAccountTitle =
        bankAcc?.accountName ?? factoryOwner ?? 'Hussain marble dealer';
    final bankAccountNumber = bankAcc?.accountNumber ?? '104311645540001';
    final bankName = bankAcc != null
        ? '${bankAcc.bankName}${bankAcc.branch != null && bankAcc.branch!.isNotEmpty ? " (${bankAcc.branch})" : ""}'
        : 'BankIslami Pakistan Limited (1043)';
    final bankIban = bankAcc?.iban ?? 'ABNM567788876666';

    final resolvedCity = contact?.city != null && contact!.city.trim().isNotEmpty
        ? contact.city.trim()
        : factoryAddress != null && factoryAddress.contains(',')
            ? factoryAddress.split(',').last.trim()
            : 'Loralai';

    final termsText = invSettings?.termsAndConditions != null &&
            invSettings!.termsAndConditions!.trim().isNotEmpty
        ? invSettings.termsAndConditions!.trim()
        : null;

    final currencyCode =
        profile?.invoiceSettings.currency ?? Formatters.activeCurrency;
    final currencySymbol =
        CurrencyFormatter.getSymbol(currencyCode, asciiSafe: true);

    final collectedDateStr = dateFormat.format(collection.collectedAt);

    pw.Widget buildStockCategoryTable({
      required String categoryTitle,
      required List<JobWorkCollectionLineItem> items,
      required int categoryPcs,
      required double categorySqFt,
      required double categoryCharges,
    }) {
      if (items.isEmpty) return pw.SizedBox.shrink();

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.symmetric(vertical: cellPaddingV, horizontal: 6),
            decoration: const pw.BoxDecoration(
              color: _cardHeaderBg,
              borderRadius:
                  pw.BorderRadius.vertical(top: pw.Radius.circular(3)),
            ),
            child: pw.Text(
              categoryTitle.toUpperCase(),
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: headerFontSize,
                color: PdfColors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
          pw.Table(
            border: pw.TableBorder.all(color: _borderLight, width: 0.8),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.3),
              1: pw.FlexColumnWidth(1.4),
              2: pw.FlexColumnWidth(1.7),
              3: pw.FlexColumnWidth(1.7),
              4: pw.FlexColumnWidth(2.1),
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _navy),
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(
                        vertical: cellPaddingV + 0.5, horizontal: cellPaddingH),
                    child: pw.Text(
                      'STOCK SIZE',
                      style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: tableFontSize - 0.2,
                          color: PdfColors.white),
                    ),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(
                        vertical: cellPaddingV + 0.5, horizontal: cellPaddingH),
                    child: pw.Text(
                      'COLLECT PCS',
                      style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: tableFontSize - 0.2,
                          color: PdfColors.white),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(
                        vertical: cellPaddingV + 0.5, horizontal: cellPaddingH),
                    child: pw.Text(
                      'SQ FT',
                      style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: tableFontSize - 0.2,
                          color: PdfColors.white),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(
                        vertical: cellPaddingV + 0.5, horizontal: cellPaddingH),
                    child: pw.Text(
                      'RATE ($currencySymbol)',
                      style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: tableFontSize - 0.2,
                          color: PdfColors.white),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(
                        vertical: cellPaddingV + 0.5, horizontal: cellPaddingH),
                    child: pw.Text(
                      'CHARGES ($currencySymbol)',
                      style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: tableFontSize - 0.2,
                          color: PdfColors.white),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
              // Data Rows for each item
              for (int i = 0; i < items.length; i++) ...[
                () {
                  final item = items[i];
                  final rate = getItemRate(item);
                  final charges = item.squareFeet > 0
                      ? item.squareFeet * rate
                      : item.pieces * rate;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: i % 2 == 1 ? _bgLight : PdfColors.white,
                    ),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(
                            vertical: cellPaddingV, horizontal: cellPaddingH),
                        child: pw.Text(
                          Formatters.textForExport(item.displayLabel),
                          style: pw.TextStyle(
                              font: fonts.bold,
                              fontSize: tableFontSize,
                              color: PdfColors.black),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(
                            vertical: cellPaddingV, horizontal: cellPaddingH),
                        child: pw.Text(
                          _wholeFormatter.format(item.pieces),
                          style: pw.TextStyle(
                              font: fonts.regular,
                              fontSize: tableFontSize,
                              color: PdfColors.black),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(
                            vertical: cellPaddingV, horizontal: cellPaddingH),
                        child: pw.Text(
                          _commaFormatter.format(item.squareFeet),
                          style: pw.TextStyle(
                              font: fonts.regular,
                              fontSize: tableFontSize,
                              color: PdfColors.black),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(
                            vertical: cellPaddingV, horizontal: cellPaddingH),
                        child: pw.Text(
                          rate > 0 ? _commaFormatter.format(rate) : '-',
                          style: pw.TextStyle(
                              font: fonts.regular,
                              fontSize: tableFontSize,
                              color: PdfColors.black),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(
                            vertical: cellPaddingV, horizontal: cellPaddingH),
                        child: pw.Text(
                          charges > 0 ? _commaFormatter.format(charges) : '-',
                          style: pw.TextStyle(
                              font: fonts.bold,
                              fontSize: tableFontSize,
                              color: PdfColors.black),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }(),
              ],
              // Category Subtotal Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _bgLight),
                children: [
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(
                        vertical: cellPaddingV + 0.5, horizontal: cellPaddingH),
                    child: pw.Text(
                      'Subtotal ${categoryTitle.split(" ")[0]}:',
                      style: pw.TextStyle(
                          font: fonts.bold, fontSize: tableFontSize, color: _navy),
                    ),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(
                        vertical: cellPaddingV + 0.5, horizontal: cellPaddingH),
                    child: pw.Text(
                      '${_wholeFormatter.format(categoryPcs)} pcs',
                      style: pw.TextStyle(
                          font: fonts.bold, fontSize: tableFontSize, color: _navy),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(
                        vertical: cellPaddingV + 0.5, horizontal: cellPaddingH),
                    child: pw.Text(
                      '${_commaFormatter.format(categorySqFt)} sq ft',
                      style: pw.TextStyle(
                          font: fonts.bold, fontSize: tableFontSize, color: _navy),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(
                        vertical: cellPaddingV + 0.5, horizontal: cellPaddingH),
                    child: pw.Text('-',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontSize: tableFontSize)),
                  ),
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(
                        vertical: cellPaddingV + 0.5, horizontal: cellPaddingH),
                    child: pw.Text(
                      '$currencySymbol ${_commaFormatter.format(categoryCharges)}',
                      style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: tableFontSize,
                          color: _accentBlue),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }

    // Strict 1-Page PDF Document Generation
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        theme: fonts.theme,
        build: (context) {
          final contentWidth = PdfPageFormat.a4.width - 40; // 555.27 pt

          return pw.FittedBox(
            fit: pw.BoxFit.scaleDown,
            alignment: pw.Alignment.topCenter,
            child: pw.Container(
              width: contentWidth,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
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
                                    width: 40,
                                    height: 40,
                                    child: pw.Image(
                                      pw.MemoryImage(logoBytes),
                                      fit: pw.BoxFit.contain,
                                    ),
                                  ),
                                  pw.SizedBox(width: 10),
                                ],
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        resolvedFactoryName,
                                        style: pw.TextStyle(
                                          font: fonts.bold,
                                          fontSize: 14,
                                          color: _accentBlue,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      if (tagline.isNotEmpty) ...[
                                        pw.SizedBox(height: 1),
                                        pw.Text(
                                          tagline,
                                          style: pw.TextStyle(
                                            font: fonts.bold,
                                            fontSize: 6.8,
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
                              pw.SizedBox(height: 4),
                              if (factoryOwner != null)
                                pw.Text(
                                  'Proprietor / Management: $factoryOwner',
                                  style: pw.TextStyle(
                                    font: fonts.bold,
                                    fontSize: 6.5,
                                    color: _navy,
                                  ),
                                ),
                              if (factoryAddress != null)
                                pw.Text(
                                  'Factory & Facility: $factoryAddress',
                                  style: pw.TextStyle(
                                    font: fonts.regular,
                                    fontSize: 6.3,
                                    color: _mutedGrey,
                                  ),
                                ),
                              if (factoryPhone != null ||
                                  email != null ||
                                  website != null)
                                pw.Text(
                                  [
                                    if (factoryPhone != null)
                                      'Phone: $factoryPhone',
                                    if (email != null) 'Email: $email',
                                    if (website != null) 'Web: $website',
                                  ].join(' | '),
                                  style: pw.TextStyle(
                                    font: fonts.regular,
                                    fontSize: 6.3,
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
                                    fontSize: 6.3,
                                    color: _mutedGrey,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 14),
                      // Right Column: Collection Slip Header Card
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(
                            width: 160,
                            padding: const pw.EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            decoration: const pw.BoxDecoration(
                              color: _navy,
                              borderRadius:
                                  pw.BorderRadius.all(pw.Radius.circular(3)),
                            ),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              'COLLECTION SLIP',
                              style: pw.TextStyle(
                                font: fonts.bold,
                                fontSize: 11,
                                color: PdfColors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          _metaRow(fonts, 'Slip No:', collection.collectionNumber),
                          _metaRow(fonts, 'Date Issued:', collectedDateStr),
                          _metaRow(fonts, 'Job Work ID:', collection.jobWorkNumber),
                          if (collection.loadNumber != null &&
                              collection.loadNumber!.trim().isNotEmpty)
                            _metaRow(fonts, 'Load No:', collection.loadNumber!),
                          pw.SizedBox(height: 3),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              vertical: 2.5,
                              horizontal: 12,
                            ),
                            decoration: pw.BoxDecoration(
                              color: _greenBg,
                              borderRadius: pw.BorderRadius.circular(3),
                              border: pw.Border.all(color: _greenText, width: 0.8),
                            ),
                            child: pw.Text(
                              collection.status.label.toUpperCase(),
                              style: pw.TextStyle(
                                font: fonts.bold,
                                fontSize: 7.5,
                                color: _greenText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: sectionGap),
                  pw.Divider(color: _borderLight, thickness: 0.8),
                  pw.SizedBox(height: sectionGap),

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
                      pw.SizedBox(width: 8),
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

                  pw.SizedBox(height: sectionGap),

                  // Section 3: Itemized Stock Tables
                  if (useSideBySideTables) ...[
                    // High item count: render Small Stock and Large Stock side-by-side
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: buildStockCategoryTable(
                            categoryTitle: 'Small Stock',
                            items: smallItems,
                            categoryPcs: totalSmallPcs,
                            categorySqFt: totalSmallSqFt,
                            categoryCharges: totalSmallCharges,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: buildStockCategoryTable(
                            categoryTitle: 'Large Stock',
                            items: largeItems,
                            categoryPcs: totalLargePcs,
                            categorySqFt: totalLargeSqFt,
                            categoryCharges: totalLargeCharges,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Stacked Tables for standard item counts
                    buildStockCategoryTable(
                      categoryTitle: 'Small Stock',
                      items: smallItems,
                      categoryPcs: totalSmallPcs,
                      categorySqFt: totalSmallSqFt,
                      categoryCharges: totalSmallCharges,
                    ),
                    if (smallItems.isNotEmpty && largeItems.isNotEmpty)
                      pw.SizedBox(height: sectionGap),
                    buildStockCategoryTable(
                      categoryTitle: 'Large Stock',
                      items: largeItems,
                      categoryPcs: totalLargePcs,
                      categorySqFt: totalLargeSqFt,
                      categoryCharges: totalLargeCharges,
                    ),
                  ],

                  pw.SizedBox(height: sectionGap),

                  // Grand Total Summary Box
                  pw.Container(
                    padding: pw.EdgeInsets.symmetric(vertical: cellPaddingV + 1, horizontal: 8),
                    decoration: pw.BoxDecoration(
                      color: _bgLight,
                      borderRadius: pw.BorderRadius.circular(3),
                      border: pw.Border.all(color: _navy, width: 0.8),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'GRAND TOTAL COLLECTED:',
                          style: pw.TextStyle(
                            font: fonts.bold,
                            fontSize: tableFontSize + 0.5,
                            color: _navy,
                          ),
                        ),
                        pw.Row(
                          children: [
                            pw.Text(
                              '${AppStrings.totalPieces}: ${_wholeFormatter.format(grandTotalPcs)} pcs',
                              style: pw.TextStyle(
                                font: fonts.bold,
                                fontSize: tableFontSize,
                                color: _navy,
                              ),
                            ),
                            pw.SizedBox(width: 12),
                            pw.Text(
                              '${AppStrings.totalSquareFeet}: ${_commaFormatter.format(grandTotalSqFt)} sq ft',
                              style: pw.TextStyle(
                                font: fonts.bold,
                                fontSize: tableFontSize,
                                color: _accentBlue,
                              ),
                            ),
                            pw.SizedBox(width: 12),
                            pw.Text(
                              'Total Charges: $currencySymbol ${_commaFormatter.format(grandTotalCharges)}',
                              style: pw.TextStyle(
                                font: fonts.bold,
                                fontSize: tableFontSize + 0.5,
                                color: _accentBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: sectionGap),

                  // Section 4: Bank Details & Terms & Conditions (Side-by-side Micro-Footer)
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Bank & Remittance Card
                      pw.Expanded(
                        flex: 45,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          decoration: pw.BoxDecoration(
                            color: _bgLight,
                            borderRadius: pw.BorderRadius.circular(3),
                            border: pw.Border.all(color: _borderLight, width: 0.8),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'BANK & REMITTANCE DETAILS',
                                style: pw.TextStyle(
                                  font: fonts.bold,
                                  fontSize: 7,
                                  color: _navy,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              _bankRow(fonts, 'Account Title:', bankAccountTitle),
                              _bankRow(fonts, 'Account Number:', bankAccountNumber),
                              _bankRow(fonts, 'Bank Name:', bankName),
                              _bankRow(fonts, 'IBAN:', bankIban),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      // Terms & Conditions Block
                      pw.Expanded(
                        flex: 55,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'TERMS & CONDITIONS:',
                              style: pw.TextStyle(
                                font: fonts.bold,
                                fontSize: 6.8,
                                color: _navy,
                              ),
                            ),
                            pw.SizedBox(height: 1.5),
                            if (termsText != null)
                              pw.Text(
                                termsText,
                                style: pw.TextStyle(
                                  font: fonts.regular,
                                  fontSize: 5.8,
                                  color: _mutedGrey,
                                ),
                              )
                            else ...[
                              _termLine(
                                fonts,
                                'Payment Terms:',
                                'Payment due within agreed terms. Late payments +2% monthly.',
                              ),
                              _termLine(
                                fonts,
                                'Claims Window:',
                                'Weight, size, or damage claims must be reported within 24 hours.',
                              ),
                              _termLine(
                                fonts,
                                'Processing Risk:',
                                'Factory is not responsible for stone breakage due to natural veins.',
                              ),
                              _termLine(
                                fonts,
                                'Ownership & Jurisdiction:',
                                'Title stays with seller until paid. Court jurisdiction in $resolvedCity.',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Section 5: Notes / Instructions Block (if present)
                  if (collection.notes != null &&
                      collection.notes!.trim().isNotEmpty) ...[
                    pw.SizedBox(height: sectionGap - 1),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(
                        color: _bgLight,
                        borderRadius: pw.BorderRadius.circular(3),
                        border: pw.Border.all(color: _borderLight, width: 0.8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'NOTES & DISPATCH INSTRUCTIONS:',
                            style: pw.TextStyle(
                              font: fonts.bold,
                              fontSize: 6.5,
                              color: _navy,
                            ),
                          ),
                          pw.SizedBox(height: 1),
                          pw.Text(
                            Formatters.textForExport(collection.notes!),
                            style: pw.TextStyle(
                              font: fonts.regular,
                              fontSize: 6,
                              color: _mutedGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  pw.SizedBox(height: sectionGap + 2),

                  // Section 6: Signature & Verification (QR Code + Prepared By line)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // QR Code Verification Block
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 32,
                            height: 32,
                            padding: const pw.EdgeInsets.all(1.5),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: _navy, width: 0.8),
                              borderRadius: pw.BorderRadius.circular(2),
                            ),
                            child: pw.BarcodeWidget(
                              barcode: pw.Barcode.qrCode(),
                              data: '${collection.collectionNumber}-VERIFIED',
                              drawText: false,
                              color: _navy,
                            ),
                          ),
                          pw.SizedBox(width: 6),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'SCAN TO VERIFY',
                                style: pw.TextStyle(
                                  font: fonts.bold,
                                  fontSize: 7.5,
                                  color: _navy,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              pw.Text(
                                'Digital Authenticity Code',
                                style: pw.TextStyle(
                                  font: fonts.regular,
                                  fontSize: 6,
                                  color: _mutedGrey,
                                ),
                              ),
                              pw.Text(
                                '${collection.collectionNumber}-VERIFIED',
                                style: pw.TextStyle(
                                  font: fonts.bold,
                                  fontSize: 6.5,
                                  color: _navy,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Prepared By line
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.SizedBox(height: 36),
                            pw.Container(
                              width: 120,
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(color: _navy, width: 1),
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'Prepared By / Dispatch Officer',
                              style: pw.TextStyle(
                                font: fonts.bold,
                                fontSize: 7,
                                color: _navy,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      // Uploaded signature + official stamp
                      PdfDocumentTheme.authorizedSignatureColumn(
                        fonts: fonts,
                        branding: branding,
                        width: 120,
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 4),
                  pw.Center(
                    child: pw.Text(
                      'All stone products listed above have been inspected and collected in good order. Material custody is transferred upon signature. · $footerNoteText',
                      style: pw.TextStyle(
                        font: fonts.regular,
                        fontSize: 6,
                        color: _mutedGrey,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return doc;
  }

  static pw.Widget _metaRow(PdfFonts fonts, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 7,
              color: _mutedGrey,
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 7.5,
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
        borderRadius: pw.BorderRadius.circular(3),
        border: pw.Border.all(color: _borderLight, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 5),
            decoration: const pw.BoxDecoration(
              color: _cardHeaderBg,
              borderRadius: pw.BorderRadius.vertical(
                top: pw.Radius.circular(2),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 7,
                color: PdfColors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
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
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 72,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 6.5,
                color: _navy,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 6.5,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _bankRow(PdfFonts fonts, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 68,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 6.2,
                color: _navy,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 6.2,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _termLine(PdfFonts fonts, String prefix, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$prefix ',
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 5.8,
                color: _mutedGrey,
              ),
            ),
            pw.TextSpan(
              text: text,
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 5.8,
                color: _mutedGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
