import 'dart:math' as math;
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/job_work_sizes.dart';
import '../../../domain/entities/job_work_collection.dart';
import '../../../domain/entities/job_work_invoice.dart';
import '../../../domain/entities/job_work_load.dart';
import '../../../domain/entities/job_work_order.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/factory_profile.dart';
import '../../../domain/enums/invoice_enums.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../../../data/services/job_work_container_sync_helper.dart';
import '../../../data/services/job_work_collection_quantity_helper.dart';
import 'pdf_fonts.dart';

abstract final class GrandInvoicePdfTemplate {
  // Mockup Color Palette
  static const PdfColor _navy = PdfColor.fromInt(0xFF1B365D); // Deep Navy header background
  static const PdfColor _accentBlue = PdfColor.fromInt(0xFF0F3F70); // Accent blue headers
  static const PdfColor _mutedGrey = PdfColor.fromInt(0xFF556987); // Cool slate grey body
  static const PdfColor _borderLight = PdfColor.fromInt(0xFFD2E3FC); // Soft light blue-grey border
  static const PdfColor _bgLight = PdfColor.fromInt(0xFFF4F8FA); // Cool white/grey background
  static const PdfColor _goldBg = PdfColor.fromInt(0xFFFDF8E2); // Amber subtotal bar background
  static const PdfColor _greenText = PdfColor.fromInt(0xFF137333); // Google green
  static const PdfColor _redText = PdfColor.fromInt(0xFFC5221F); // Google red
  static const PdfColor _cardHeaderBg = PdfColor.fromInt(0xFF2C5282); // Card sub header

  static final NumberFormat _commaFormatter = NumberFormat('#,##0.00');
  static final NumberFormat _wholeCommaFormatter = NumberFormat('#,##0');

  static String formatAmount(double amount) => _commaFormatter.format(amount);
  static String formatWhole(num val) => _wholeCommaFormatter.format(val);

  static Future<pw.Document> build({
    required JobWorkInvoice invoice,
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
    required List<JobWorkCollection> collections,
    required List<Payment> payments,
    required FactoryProfile? factoryProfile,
    required PdfFonts fonts,
    Uint8List? logoBytes,
  }) async {
    final doc = pw.Document(theme: fonts.theme);
    final dateFormat = DateFormat('MMM dd, yyyy');

    // Factory information with fallback default fields for completeness
    final factoryName = factoryProfile?.name.trim().isNotEmpty == true
        ? factoryProfile!.name.trim()
        : 'JK MARBLE';
    final factoryOwner = factoryProfile?.ownerName?.trim().isNotEmpty == true
        ? factoryProfile!.ownerName!.trim()
        : 'Jabbar Kakar';
    final factoryAddress = factoryProfile?.address?.trim().isNotEmpty == true
        ? factoryProfile!.address!.trim()
        : 'Factory Road, Industrial Estate, Quetta, Balochistan, Pakistan';
    final factoryPhone = factoryProfile?.phone?.trim().isNotEmpty == true
        ? factoryProfile!.phone!.trim()
        : '+92 346 4823221';
    
    // Derived professional details
    final cleanDomain = factoryName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final email = 'info@$cleanDomain.com';
    final website = 'www.$cleanDomain.com';
    const gpsCoordinates = '30.1978° N, 70.6212° E';
    const taxRegNo = 'STRN: 3908671-5  ·  NTN: 9204856-1';

    // Financial calculations
    final isSingleLoad = invoice.loadId != null && invoice.loadId!.trim().isNotEmpty;
    final billable = JobWorkContainerSyncHelper.billableLoadsForGrandInvoice(loads);
    final displayLoads = billable.isNotEmpty ? billable : loads;
    
    final financeMap = JobWorkContainerSyncHelper.calculatePerLoadFinanceMap(
      order: order,
      loads: loads,
      invoices: invoicesForGrand(loads, invoice),
    );

    final aggregated = JobWorkCollectionQuantityHelper.aggregateTotals(
      order: order,
      collections: collections,
      loads: loads,
    );

    // Sum financial metrics
    var totalCuttingCharges = 0.0;
    var totalPaid = 0.0;
    var totalDue = 0.0;
    for (final load in displayLoads) {
      final fin = financeMap[load.id] ?? (charges: load.finalCuttingCharges, paid: load.advanceReceived, due: load.balanceDue);
      totalCuttingCharges += fin.charges;
      totalPaid += fin.paid;
      totalDue += fin.due;
    }

    // Load status aggregation counts over ALL active (non-cancelled, non-virtual) loads
    final statusLoads = loads.where((l) => !l.isVirtual && l.status != JobWorkStatus.cancelled).toList();
    final totalStatusLoads = statusLoads.length;

    final completedLoads = statusLoads.where((l) => l.status.isCompleted).length;

    final inCuttingLoads = statusLoads.where((l) =>
      l.status == JobWorkStatus.inCutting ||
      l.status == JobWorkStatus.qc
    ).length;

    final pendingLoads = totalStatusLoads - completedLoads - inCuttingLoads;

    final collectedPercent = aggregated.totalPieces > 0
        ? (aggregated.collectedPieces / aggregated.totalPieces * 100).toStringAsFixed(1)
        : '0.0';

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
              border: pw.Border(bottom: pw.BorderSide(color: _borderLight, width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '$factoryName · GRAND INVOICE',
                  style: pw.TextStyle(font: fonts.bold, fontSize: 8, color: _mutedGrey),
                ),
                pw.Text(
                  'Invoice No: ${invoice.invoiceNumber}',
                  style: pw.TextStyle(font: fonts.regular, fontSize: 8, color: _mutedGrey),
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
              border: pw.Border(top: pw.BorderSide(color: _borderLight, width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '$factoryName · ISO 9001:2015 Certified Marble & Natural Stone Processing',
                  style: pw.TextStyle(font: fonts.regular, fontSize: 7.5, color: _mutedGrey),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(font: fonts.bold, fontSize: 8, color: _accentBlue),
                ),
              ],
            ),
          );
        },
        build: (context) => [
          // Section 1: Factory Header
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left Column: Logo, Title & Slogan, and details block below
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Logo + Title/Slogan Row
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (logoBytes != null) ...[
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
                                factoryName.toUpperCase(),
                                style: pw.TextStyle(font: fonts.bold, fontSize: 26, color: _accentBlue, letterSpacing: 0.4),
                              ),
                              pw.SizedBox(height: 1),
                              pw.Text(
                                'PREMIUM NATURAL STONE PROCESSING & EXPORT',
                                style: pw.TextStyle(font: fonts.bold, fontSize: 8, color: _navy, letterSpacing: 0.2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    // Details block
                    pw.Text(
                      'Proprietor: $factoryOwner',
                      style: pw.TextStyle(font: fonts.bold, fontSize: 7, color: _navy),
                    ),
                    pw.Text(
                      'Factory & Processing Facility: $factoryAddress',
                      style: pw.TextStyle(font: fonts.regular, fontSize: 7, color: _mutedGrey),
                    ),
                    pw.Text(
                      'GPS Coordinates: $gpsCoordinates | Web: $website',
                      style: pw.TextStyle(font: fonts.regular, fontSize: 7, color: _mutedGrey),
                    ),
                    pw.Text(
                      'Phone: $factoryPhone | Email: $email',
                      style: pw.TextStyle(font: fonts.regular, fontSize: 7, color: _mutedGrey),
                    ),
                    pw.Text(
                      'STRN: ${taxRegNo.split('·').first.replaceAll('STRN:', '').trim()} | NTN: ${taxRegNo.split('·').last.replaceAll('NTN:', '').trim()}',
                      style: pw.TextStyle(font: fonts.regular, fontSize: 7, color: _mutedGrey),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 24),
              // Right Column: Grand Invoice Header Card
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 180,
                    padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                    decoration: const pw.BoxDecoration(
                      color: _navy,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      invoice.loadId != null && invoice.loadId!.trim().isNotEmpty
                          ? 'LOAD INVOICE'
                          : 'GRAND INVOICE',
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 14,
                        color: PdfColors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _metaRow(fonts, 'Invoice No:', invoice.invoiceNumber),
                  _metaRow(fonts, 'Date Issued:', dateFormat.format(DateTime.now())),
                  _metaRow(fonts, 'Job Work ID:', order.jobWorkNumber),
                  pw.SizedBox(height: 6),
                  // Status Badge matching the exact mockup style
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 24),
                    decoration: pw.BoxDecoration(
                      color: totalDue <= 0
                          ? const PdfColor.fromInt(0xFFE6F4EA) // Google Green 100
                          : const PdfColor.fromInt(0xFFFCE8E6), // Google Red 100
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(
                        color: totalDue <= 0
                            ? const PdfColor.fromInt(0xFF34A853)
                            : const PdfColor.fromInt(0xFFEA4335),
                        width: 0.8,
                      ),
                    ),
                    child: pw.Text(
                      totalDue <= 0 ? 'FULLY PAID' : 'OUTSTANDING DUE',
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 9.5,
                        color: totalDue <= 0 ? _greenText : _redText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: _borderLight, height: 16, thickness: 0.8),

          // Section 2: CLIENT / BILL TO (Full Width & Multi-Row)
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _bgLight,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: _borderLight, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CLIENT / BILL TO',
                  style: pw.TextStyle(font: fonts.bold, fontSize: 9.5, color: _accentBlue, letterSpacing: 0.2),
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: _gridRow(fonts, 'Client Name:', invoice.customerName),
                    ),
                    pw.SizedBox(width: 24),
                    pw.Expanded(
                      child: _gridRow(fonts, 'Account Type:', 'Job Work Processing (Contract)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // Section 3: Summary Metrics Row (Status, Piece, Sq Ft)
          pw.Row(
            children: [
              // 1. Status Breakdown
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _borderLight, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'LOAD STATUS BREAKDOWN',
                        style: pw.TextStyle(font: fonts.bold, fontSize: 7.5, color: _accentBlue),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '$totalStatusLoads Total Loads',
                        style: pw.TextStyle(font: fonts.bold, fontSize: 13, color: _navy),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text('$completedLoads Completed', style: pw.TextStyle(font: fonts.bold, fontSize: 8, color: _greenText)),
                          pw.Text('  ·  ', style: pw.TextStyle(font: fonts.regular, fontSize: 8, color: _mutedGrey)),
                          pw.Text('$inCuttingLoads In Cutting', style: pw.TextStyle(font: fonts.regular, fontSize: 8, color: _mutedGrey)),
                          pw.Text('  ·  ', style: pw.TextStyle(font: fonts.regular, fontSize: 8, color: _mutedGrey)),
                          pw.Text('$pendingLoads Pending', style: pw.TextStyle(font: fonts.regular, fontSize: 8, color: _mutedGrey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              // 2. Piece Count
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _borderLight, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'PIECE COUNT INVENTORY',
                        style: pw.TextStyle(font: fonts.bold, fontSize: 7.5, color: _accentBlue),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${formatWhole(aggregated.totalPieces)} Total Pcs',
                        style: pw.TextStyle(font: fonts.bold, fontSize: 13, color: _navy),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text('${formatWhole(aggregated.collectedPieces)} Collected ($collectedPercent%)', style: pw.TextStyle(font: fonts.bold, fontSize: 8, color: _greenText)),
                          pw.Text('  ·  ', style: pw.TextStyle(font: fonts.regular, fontSize: 8, color: _mutedGrey)),
                          pw.Text('${formatWhole(aggregated.remainingPieces)} Rem', style: pw.TextStyle(font: fonts.bold, fontSize: 8, color: _redText)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              // 3. Surface Area
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _borderLight, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'TOTAL SURFACE AREA',
                        style: pw.TextStyle(font: fonts.bold, fontSize: 7.5, color: _accentBlue),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${formatAmount(aggregated.totalSquareFeet)} Sq. Ft.',
                        style: pw.TextStyle(font: fonts.bold, fontSize: 13, color: _navy),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text('${formatAmount(aggregated.collectedSquareFeet)} Coll.', style: pw.TextStyle(font: fonts.bold, fontSize: 8, color: _greenText)),
                          pw.Text('  ·  ', style: pw.TextStyle(font: fonts.regular, fontSize: 8, color: _mutedGrey)),
                          pw.Text('${formatAmount(aggregated.remainingSquareFeet)} Rem.', style: pw.TextStyle(font: fonts.bold, fontSize: 8, color: _redText)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 18),

          // Section 4: Individual Loads Iteration
          for (var i = 0; i < displayLoads.length; i++) ...[
            _buildLoadSection(
              load: displayLoads[i],
              index: i + 1,
              collections: collections,
              fin: financeMap[displayLoads[i].id] ??
                  (charges: displayLoads[i].finalCuttingCharges, paid: displayLoads[i].advanceReceived, due: displayLoads[i].balanceDue),
              fonts: fonts,
              dateFormat: dateFormat,
              isSingleLoad: isSingleLoad,
            ),
            if (i < displayLoads.length - 1) pw.SizedBox(height: 14),
          ],

          pw.SizedBox(height: 18),

          // Section 5: Remittance, Terms & Grand Financial Summary
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left column: Bank & Terms
              pw.Expanded(
                flex: 5,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Bank box
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _borderLight, width: 0.8),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'BANK & REMITTANCE DETAILS',
                            style: pw.TextStyle(font: fonts.bold, fontSize: 8.5, color: _accentBlue),
                          ),
                          pw.SizedBox(height: 4),
                          _bankRow(fonts, 'Account Name:', 'Travertine Stone Processing'),
                          _bankRow(fonts, 'Account Number:', '0924-8560192-005'),
                          _bankRow(fonts, 'Bank & Branch:', 'Quetta Main Branch, Balochistan'),
                          _bankRow(fonts, 'Swift/BIC Code:', 'TRVPPKKA'),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    // Terms
                    pw.Text(
                      'TERMS & CONDITIONS:',
                      style: pw.TextStyle(font: fonts.bold, fontSize: 8.5, color: _navy),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '1. Please review cutting charge calculations and report any discrepancies within 7 days.\n'
                      '2. Payments are to be settled as per agreed international commercial contract terms.\n'
                      '3. All stone materials delivered remain under job work custody until final clearance.',
                      style: pw.TextStyle(font: fonts.regular, fontSize: 8, color: _mutedGrey, height: 1.4),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 18),
              // Right column: Financial Summary Card
              pw.Expanded(
                flex: 5,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: _borderLight, width: 0.8),
                  ),
                  child: pw.Column(
                    children: [
                      _summaryRow(fonts, 'Total Cutting Charges:', 'Rs', formatAmount(totalCuttingCharges)),
                      _summaryRow(fonts, 'Additional Processing Fees:', 'Rs', '0.00'),
                      _summaryRow(fonts, 'Discounts / Adjustments:', 'Rs', '0.00'),
                      pw.Divider(color: _borderLight, height: 10, thickness: 0.6),
                      _summaryRow(fonts, 'Sub Total:', 'Rs', formatAmount(totalCuttingCharges), boldText: true),
                      _summaryRow(fonts, 'Total Payments Allocated:', 'Rs', formatAmount(totalPaid), boldText: true),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(color: _navy, borderRadius: pw.BorderRadius.circular(3.3)),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'OUTSTANDING BALANCE:',
                              style: pw.TextStyle(font: fonts.bold, fontSize: 9.5, color: PdfColors.white),
                            ),
                            pw.Text(
                              'PKR ${formatAmount(totalDue)}',
                              style: pw.TextStyle(font: fonts.bold, fontSize: 13, color: PdfColors.white),
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
          pw.SizedBox(height: 24),

          // Section 6: QR, signatures, and bottom branding
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Scan to Verify
              pw.Row(
                children: [
                  _qrCodeMock(),
                  pw.SizedBox(width: 8),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SCAN TO VERIFY',
                        style: pw.TextStyle(font: fonts.bold, fontSize: 7.5, color: _navy),
                      ),
                      pw.Text(
                        'Digital Authenticity Code',
                        style: pw.TextStyle(font: fonts.regular, fontSize: 7, color: _mutedGrey),
                      ),
                      pw.Text(
                        '${invoice.invoiceNumber}-VERIFIED',
                        style: pw.TextStyle(font: fonts.regular, fontSize: 7, color: _mutedGrey),
                      ),
                    ],
                  ),
                ],
              ),
              // Prepared line
              pw.Column(
                children: [
                  pw.Container(width: 140, height: 0.8, color: _mutedGrey),
                  pw.SizedBox(height: 4),
                  pw.Text('Prepared By / Dispatch Officer', style: pw.TextStyle(font: fonts.regular, fontSize: 7.5, color: _mutedGrey)),
                ],
              ),
              // Authorized line
              pw.Column(
                children: [
                  pw.Container(width: 140, height: 0.8, color: _mutedGrey),
                  pw.SizedBox(height: 4),
                  pw.Text('Authorized Signature & Stamp', style: pw.TextStyle(font: fonts.bold, fontSize: 7.5, color: _navy)),
                  pw.Text('${factoryName.toUpperCase()} MANAGEMENT', style: pw.TextStyle(font: fonts.bold, fontSize: 7.5, color: _accentBlue)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: _borderLight, height: 12, thickness: 0.8),
          pw.Center(
            child: pw.Text(
              'Thank you for your valuable business with $factoryName!',
              style: pw.TextStyle(font: fonts.bold, fontSize: 9.5, color: _accentBlue),
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _buildLoadSection({
    required JobWorkLoad load,
    required int index,
    required List<JobWorkCollection> collections,
    required ({double charges, double paid, double due}) fin,
    required PdfFonts fonts,
    required DateFormat dateFormat,
    required bool isSingleLoad,
  }) {
    // Collect sizes produced and partition them
    final produced = JobWorkCollectionQuantityHelper.producedStockForLoad(load);
    final loadCollections = JobWorkCollectionQuantityHelper.collectionsForLoad(load.id, collections);

    var smallTotalPieces = 0;
    var smallTotalSqFt = 0.0;
    var smallCollectedPieces = 0;
    var smallCollectedSqFt = 0.0;
    var smallTotalAmount = 0.0;
    var smallRates = <double>{};

    var largeTotalPieces = 0;
    var largeTotalSqFt = 0.0;
    var largeCollectedPieces = 0;
    var largeCollectedSqFt = 0.0;
    var largeTotalAmount = 0.0;
    var largeRates = <double>{};

    for (final stock in produced) {
      final isSmall = JobWorkSizes.isSmall(stock.size);
      final colPieces = JobWorkCollectionQuantityHelper.collectedPiecesForSize(stock.size, loadCollections);
      final colSqFt = JobWorkCollectionQuantityHelper.collectedSquareFeetForSize(stock.size, loadCollections);

      if (isSmall) {
        smallTotalPieces += stock.pieces;
        smallTotalSqFt += stock.squareFeet;
        smallCollectedPieces += colPieces;
        smallCollectedSqFt += colSqFt;
        smallTotalAmount += stock.amount;
        if (stock.pieces > 0 && stock.pricePerSqFt > 0) {
          smallRates.add(stock.pricePerSqFt);
        }
      } else {
        largeTotalPieces += stock.pieces;
        largeTotalSqFt += stock.squareFeet;
        largeCollectedPieces += colPieces;
        largeCollectedSqFt += colSqFt;
        largeTotalAmount += stock.amount;
        if (stock.pieces > 0 && stock.pricePerSqFt > 0) {
          largeRates.add(stock.pricePerSqFt);
        }
      }
    }

    final smallRemainingPieces = math.max(0, smallTotalPieces - smallCollectedPieces);
    final smallRemainingSqFt = JobWorkCollectionQuantityHelper.normalizeRemainingSquareFeet(
      remainingPieces: smallRemainingPieces,
      rawSquareFeet: smallTotalSqFt - smallCollectedSqFt,
    );

    final largeRemainingPieces = math.max(0, largeTotalPieces - largeCollectedPieces);
    final largeRemainingSqFt = JobWorkCollectionQuantityHelper.normalizeRemainingSquareFeet(
      remainingPieces: largeRemainingPieces,
      rawSquareFeet: largeTotalSqFt - largeCollectedSqFt,
    );

    final smallRateStr = smallRates.isNotEmpty ? smallRates.map((r) => r.toStringAsFixed(2)).join(', ') : '0.00';
    final largeRateStr = largeRates.isNotEmpty ? largeRates.map((r) => r.toStringAsFixed(2)).join(', ') : '0.00';

    final String thicknessClean;
    final String rawThickness = load.thickness.toString();
    if (rawThickness.toLowerCase().contains('sutar')) {
      thicknessClean = rawThickness;
    } else {
      thicknessClean = '$rawThickness Sutar';
    }
    final String finishClean = load.finish.label;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Header Bar
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          decoration: const pw.BoxDecoration(
            color: _navy,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(4),
              topRight: pw.Radius.circular(4),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'LOAD #$index: ${load.loadNumber.isNotEmpty ? load.loadNumber : "JWL-2026-000${load.loadSequence}"}',
                style: pw.TextStyle(font: fonts.bold, fontSize: 9.5, color: PdfColors.white),
              ),
              pw.Text(
                'Received Date: ${dateFormat.format(load.receivedDate)}',
                style: pw.TextStyle(font: fonts.regular, fontSize: 8.5, color: PdfColors.white),
              ),
            ],
          ),
        ),

        // Metadata Grid (Shifts removed, cutting strategy added)
        pw.Container(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(color: _borderLight, width: 0.8),
              right: pw.BorderSide(color: _borderLight, width: 0.8),
              bottom: pw.BorderSide(color: _borderLight, width: 0.8),
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
                    _gridRow(fonts, 'Marble Variety:', load.marbleVariety),
                    _gridRow(fonts, 'Block Details:', '${load.blockCount} blocks'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _gridRow(fonts, 'Mine Location:', load.mineLocation ?? 'N/A'),
                    _gridRow(fonts, 'Mine Owner:', load.mineOwner ?? 'N/A'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _gridRow(fonts, 'Cutting Strategy:', load.cuttingStrategy.label),
                    _gridRow(fonts, 'Thickness/Finish:', '$thicknessClean $finishClean'),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),

        // Table
        if (produced.isNotEmpty) ...[
          pw.Table(
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _borderLight, width: 0.4),
              top: pw.BorderSide(color: _borderLight, width: 0.6),
              bottom: pw.BorderSide(color: _borderLight, width: 0.6),
              left: pw.BorderSide(color: _borderLight, width: 0.8),
              right: pw.BorderSide(color: _borderLight, width: 0.8),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(3.2),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.5),
              6: const pw.FlexColumnWidth(1.5),
              7: const pw.FlexColumnWidth(1.5),
              8: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _cardHeaderBg),
                children: [
                  _tableHeader(fonts, isSingleLoad ? 'SIZE / DIMENSION (STATUS)' : 'SIZE CATEGORY', alignRight: false),
                  _tableHeader(fonts, 'TOTAL PCS', alignRight: true),
                  _tableHeader(fonts, 'COLL. PCS', alignRight: true),
                  _tableHeader(fonts, 'REM. PCS', alignRight: true),
                  _tableHeader(fonts, 'TOTAL SQFT', alignRight: true),
                  _tableHeader(fonts, 'COLL. SQFT', alignRight: true),
                  _tableHeader(fonts, 'REM. SQFT', alignRight: true),
                  _tableHeader(fonts, 'RATE (PKR)', alignRight: true),
                  _tableHeader(fonts, 'CHARGES (PKR)', alignRight: true),
                ],
              ),
              if (isSingleLoad) ...[
                // Detailed rendering for each individual size (small then large)
                if (produced.where((s) => JobWorkSizes.isSmall(s.size)).isNotEmpty) ...[
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: _bgLight),
                    children: [
                      _tableCell(fonts, 'Small Sizes', alignRight: false, isBold: true),
                      _tableCell(fonts, '', alignRight: true),
                      _tableCell(fonts, '', alignRight: true),
                      _tableCell(fonts, '', alignRight: true),
                      _tableCell(fonts, '', alignRight: true),
                      _tableCell(fonts, '', alignRight: true),
                      _tableCell(fonts, '', alignRight: true),
                      _tableCell(fonts, '', alignRight: true),
                      _tableCell(fonts, '', alignRight: true),
                    ],
                  ),
                  ...produced.where((s) => JobWorkSizes.isSmall(s.size)).map((stock) {
                    final colPieces = JobWorkCollectionQuantityHelper.collectedPiecesForSize(stock.size, loadCollections);
                    final colSqFt = JobWorkCollectionQuantityHelper.collectedSquareFeetForSize(stock.size, loadCollections);
                    final remPieces = math.max(0, stock.pieces - colPieces);
                    final remSqFt = JobWorkCollectionQuantityHelper.normalizeRemainingSquareFeet(
                      remainingPieces: remPieces,
                      rawSquareFeet: stock.squareFeet - colSqFt,
                    );
                    final sizeStatus = colPieces == 0
                        ? 'Ready'
                        : (colPieces >= stock.pieces ? 'Collected' : 'Part. Coll.');

                    return pw.TableRow(
                      children: [
                        _tableCell(fonts, '    ${stock.size} ($sizeStatus)', alignRight: false),
                        _tableCell(fonts, formatWhole(stock.pieces), alignRight: true),
                        _tableCell(fonts, formatWhole(colPieces), alignRight: true),
                        _tableCell(fonts, formatWhole(remPieces), alignRight: true),
                        _tableCell(fonts, formatAmount(stock.squareFeet), alignRight: true),
                        _tableCell(fonts, formatAmount(colSqFt), alignRight: true),
                        _tableCell(fonts, formatAmount(remSqFt), alignRight: true),
                        _tableCell(fonts, stock.pricePerSqFt.toStringAsFixed(2), alignRight: true),
                        _tableCell(fonts, formatAmount(stock.amount), alignRight: true),
                      ],
                    );
                  }),
                ],
                if (produced.where((s) => !JobWorkSizes.isSmall(s.size)).isNotEmpty) ...[
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: _bgLight),
                    children: [
                      _tableCell(fonts, 'Large Sizes', alignRight: false, isBold: true),
                      _tableCell(fonts, '', alignRight: true),
                      _tableCell(fonts, '', alignRight: true),
                      _tableCell(fonts, '', alignRight: true),
                      _tableCell(fonts, '', alignRight: true),
                      _tableCell(fonts, '', alignRight: true),
                      _tableCell(fonts, '', alignRight: true),
                      _tableCell(fonts, '', alignRight: true),
                      _tableCell(fonts, '', alignRight: true),
                    ],
                  ),
                  ...produced.where((s) => !JobWorkSizes.isSmall(s.size)).map((stock) {
                    final colPieces = JobWorkCollectionQuantityHelper.collectedPiecesForSize(stock.size, loadCollections);
                    final colSqFt = JobWorkCollectionQuantityHelper.collectedSquareFeetForSize(stock.size, loadCollections);
                    final remPieces = math.max(0, stock.pieces - colPieces);
                    final remSqFt = JobWorkCollectionQuantityHelper.normalizeRemainingSquareFeet(
                      remainingPieces: remPieces,
                      rawSquareFeet: stock.squareFeet - colSqFt,
                    );
                    final sizeStatus = colPieces == 0
                        ? 'Ready'
                        : (colPieces >= stock.pieces ? 'Collected' : 'Part. Coll.');

                    return pw.TableRow(
                      children: [
                        _tableCell(fonts, '    ${stock.size} ($sizeStatus)', alignRight: false),
                        _tableCell(fonts, formatWhole(stock.pieces), alignRight: true),
                        _tableCell(fonts, formatWhole(colPieces), alignRight: true),
                        _tableCell(fonts, formatWhole(remPieces), alignRight: true),
                        _tableCell(fonts, formatAmount(stock.squareFeet), alignRight: true),
                        _tableCell(fonts, formatAmount(colSqFt), alignRight: true),
                        _tableCell(fonts, formatAmount(remSqFt), alignRight: true),
                        _tableCell(fonts, stock.pricePerSqFt.toStringAsFixed(2), alignRight: true),
                        _tableCell(fonts, formatAmount(stock.amount), alignRight: true),
                      ],
                    );
                  }),
                ],
              ] else ...[
                // Summarized rendering (Grand Invoice)
                pw.TableRow(
                  children: [
                    _tableCell(fonts, '    Small Sizes', alignRight: false),
                    _tableCell(fonts, formatWhole(smallTotalPieces), alignRight: true),
                    _tableCell(fonts, formatWhole(smallCollectedPieces), alignRight: true),
                    _tableCell(fonts, formatWhole(smallRemainingPieces), alignRight: true),
                    _tableCell(fonts, formatAmount(smallTotalSqFt), alignRight: true),
                    _tableCell(fonts, formatAmount(smallCollectedSqFt), alignRight: true),
                    _tableCell(fonts, formatAmount(smallRemainingSqFt), alignRight: true),
                    _tableCell(fonts, smallRateStr, alignRight: true),
                    _tableCell(fonts, formatAmount(smallTotalAmount), alignRight: true),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _tableCell(fonts, '    Large Sizes', alignRight: false),
                    _tableCell(fonts, formatWhole(largeTotalPieces), alignRight: true),
                    _tableCell(fonts, formatWhole(largeCollectedPieces), alignRight: true),
                    _tableCell(fonts, formatWhole(largeRemainingPieces), alignRight: true),
                    _tableCell(fonts, formatAmount(largeTotalSqFt), alignRight: true),
                    _tableCell(fonts, formatAmount(largeCollectedSqFt), alignRight: true),
                    _tableCell(fonts, formatAmount(largeRemainingSqFt), alignRight: true),
                    _tableCell(fonts, largeRateStr, alignRight: true),
                    _tableCell(fonts, formatAmount(largeTotalAmount), alignRight: true),
                  ],
                ),
              ],
            ],
          ),
        ] else ...[
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'No individual stock outputs recorded. General cutting charges apply.',
                  style: pw.TextStyle(font: fonts.regular, fontSize: 8.5, color: _mutedGrey, fontStyle: pw.FontStyle.italic),
                ),
                pw.Text(
                  'PKR ${formatAmount(load.finalCuttingCharges)}',
                  style: pw.TextStyle(font: fonts.bold, fontSize: 9.5, color: _navy),
                ),
              ],
            ),
          ),
        ],

        // Subtotals bar in Gold background with gold borders
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          decoration: pw.BoxDecoration(
            color: _goldBg,
            border: pw.Border.all(color: _borderLight, width: 0.8),
            borderRadius: const pw.BorderRadius.only(
              bottomLeft: pw.Radius.circular(4),
              bottomRight: pw.Radius.circular(4),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Text(
                'Load #$index Total: PKR ${formatAmount(fin.charges)}',
                style: pw.TextStyle(font: fonts.bold, fontSize: 8.5, color: _navy),
              ),
              pw.Spacer(),
              pw.Text(
                'Paid: PKR ${formatAmount(fin.paid)}',
                style: pw.TextStyle(font: fonts.bold, fontSize: 8.5, color: _greenText),
              ),
              pw.SizedBox(width: 24),
              pw.Text(
                'Remaining Balance: PKR ${formatAmount(fin.due)}',
                style: pw.TextStyle(font: fonts.bold, fontSize: 8.5, color: fin.due > 0 ? _redText : _greenText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Header helpers
  static List<JobWorkInvoice> invoicesForGrand(List<JobWorkLoad> loads, JobWorkInvoice invoice) {
    return [
      invoice,
      ...loads
          .map((l) => l.invoiceId)
          .whereType<String>()
          .where((id) => id != invoice.id)
          .map((id) => JobWorkInvoice(
                id: id,
                invoiceNumber: 'JWI-SUB',
                factoryId: invoice.factoryId,
                jobWorkId: invoice.jobWorkId,
                jobWorkNumber: invoice.jobWorkNumber,
                customerId: invoice.customerId,
                customerName: invoice.customerName,
                lineItems: const [],
                totalAmount: 0,
                paidAmount: 0,
                dueAmount: 0,
                status: InvoiceStatus.unpaid,
                createdAt: DateTime.now(),
              )),
    ];
  }

  // Helper widgets
  static pw.Widget _metaRow(PdfFonts fonts, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(
            width: 75,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: fonts.regular, fontSize: 9, color: _mutedGrey),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            value,
            style: pw.TextStyle(font: fonts.bold, fontSize: 9.5, color: _navy),
          ),
        ],
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
              style: pw.TextStyle(font: fonts.regular, fontSize: 8.5, color: _mutedGrey),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: fonts.bold, fontSize: 8.5, color: _navy),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _bankRow(PdfFonts fonts, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: fonts.bold, fontSize: 8, color: _mutedGrey),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: fonts.regular, fontSize: 8, color: _navy),
            ),
          ),
        ],
      ),
    );
  }



  static pw.Widget _tableHeader(PdfFonts fonts, String text, {required bool alignRight}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: fonts.bold, fontSize: 5.5, color: PdfColors.white),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _tableCell(
    PdfFonts fonts,
    String text, {
    required bool alignRight,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: isBold ? fonts.bold : fonts.regular,
          fontSize: 7.5,
          color: _navy,
        ),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _summaryRow(
    PdfFonts fonts,
    String label,
    String currency,
    String value, {
    bool boldText = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: boldText ? fonts.bold : fonts.regular,
              fontSize: 8.5,
              color: boldText ? _navy : _mutedGrey,
            ),
          ),
          pw.Row(
            children: [
              if (currency.isNotEmpty) ...[
                pw.Text(
                  currency,
                  style: pw.TextStyle(font: fonts.regular, fontSize: 8.5, color: _mutedGrey),
                ),
                pw.SizedBox(width: 4),
              ],
              pw.Text(
                value,
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: 9,
                  color: _navy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _qrCodeMock() {
    return pw.Container(
      width: 28,
      height: 28,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _navy, width: 0.8),
      ),
      padding: const pw.EdgeInsets.all(2),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(width: 6, height: 6, color: _navy),
              pw.Container(width: 6, height: 6, color: _navy),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(width: 6, height: 6, color: _navy),
              pw.Container(width: 6, height: 6, color: _mutedGrey),
            ],
          ),
        ],
      ),
    );
  }
}
