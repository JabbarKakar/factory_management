import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/di/injection.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/factory_profile.dart';
import '../../../domain/entities/job_work_invoice.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/sales_invoice.dart';
import '../../repositories/factory_repository.dart';
import '../../repositories/job_work_repository.dart';
import '../../repositories/job_work_load_repository.dart';
import '../../repositories/job_work_collection_repository.dart';
import '../../repositories/job_work_invoice_repository.dart';
import 'pdf_document_theme.dart';
import 'pdf_fonts.dart';
import 'proforma_invoice_pdf_template.dart';
import 'grand_invoice_pdf_template.dart';

class InvoicePdfExporter {
  InvoicePdfExporter({
    FactoryRepository? factoryRepository,
    JobWorkRepository? jobWorkRepository,
    JobWorkLoadRepository? loadRepository,
  })  : _factoryRepository = factoryRepository,
        _jobWorkRepository = jobWorkRepository,
        _loadRepository = loadRepository;

  final FactoryRepository? _factoryRepository;
  final JobWorkRepository? _jobWorkRepository;
  final JobWorkLoadRepository? _loadRepository;

  /// Generates Sales Invoice PDF bytes (Uint8List).
  Future<Uint8List> generateSalesInvoicePdf({
    required SalesInvoice invoice,
    FactoryProfile? factoryProfile,
    List<Payment> payments = const [],
  }) async {
    final doc = await buildSalesInvoicePdf(
      invoice: invoice,
      factoryProfile: factoryProfile,
      payments: payments,
    );
    return doc.save();
  }

  /// Builds a pw.Document for Sales Invoice with complete FactoryProfile branding.
  Future<pw.Document> buildSalesInvoicePdf({
    required SalesInvoice invoice,
    FactoryProfile? factoryProfile,
    List<Payment> payments = const [],
    String factoryName = AppStrings.appName,
  }) async {
    final fonts = await PdfFonts.load();
    final doc = pw.Document();
    final dateFormat = DateFormat.yMMMd();

    // Resolve FactoryProfile from repository if omitted
    final factoryRepo = _factoryRepository ?? getIt<FactoryRepository>();
    final profile = factoryProfile ??
        (invoice.factoryId.isNotEmpty
            ? await factoryRepo.getFactory(invoice.factoryId)
            : null);

    final identity = profile?.identity;
    final contact = profile?.contact;
    final legal = profile?.legal;
    final ownership = profile?.ownership;
    final invSettings = profile?.invoiceSettings;

    final rawBizName = identity?.businessName.trim();
    final rawProfileName = profile?.name.trim();
    final resolvedFactoryName = (rawBizName != null && rawBizName.isNotEmpty
            ? rawBizName
            : rawProfileName != null && rawProfileName.isNotEmpty
                ? rawProfileName
                : factoryName)
        .toUpperCase();

    final rawTagline = identity?.tagline?.trim();
    final tagline = rawTagline != null && rawTagline.isNotEmpty
        ? rawTagline
        : 'PREMIUM MANUFACTURING & SALES';

    final rawOwner = ownership?.ownerName?.trim();
    final rawProfileOwner = profile?.ownerName?.trim();
    final ownerName = rawOwner != null && rawOwner.isNotEmpty
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
    final email = contact?.email?.trim().isNotEmpty == true ? contact!.email!.trim() : null;
    final website = contact?.website?.trim().isNotEmpty == true ? contact!.website!.trim() : null;
    final ntn = legal?.ntn?.trim().isNotEmpty == true ? legal!.ntn!.trim() : null;
    final strn = legal?.strn?.trim().isNotEmpty == true ? legal!.strn!.trim() : null;
    final termsText = invSettings?.termsAndConditions?.trim().isNotEmpty == true
        ? invSettings!.termsAndConditions!.trim()
        : null;
    final footerNoteText = invSettings?.footerNote?.trim().isNotEmpty == true
        ? invSettings!.footerNote!.trim()
        : 'Thank you for your business with $resolvedFactoryName!';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: fonts.theme,
        build: (context) => [
          // Header Section
          PdfDocumentTheme.header(
            fonts: fonts,
            title: resolvedFactoryName,
            subtitle: tagline,
            rightLabel: invoice.invoiceNumber,
          ),
          if (ownerName != null || address != null || phone != null || email != null || strn != null || ntn != null) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (ownerName != null)
                      pw.Text('Proprietor: $ownerName',
                          style: PdfDocumentTheme.subtitleStyle(fonts)),
                    if (address != null)
                      pw.Text('Address: $address',
                          style: PdfDocumentTheme.subtitleStyle(fonts)),
                    if (phone != null || email != null || website != null)
                      pw.Text(
                        [
                          if (phone != null) 'Ph: $phone',
                          if (email != null) 'Email: $email',
                          if (website != null) 'Web: $website',
                        ].join(' | '),
                        style: PdfDocumentTheme.subtitleStyle(fonts),
                      ),
                  ],
                ),
                if (strn != null || ntn != null)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (strn != null)
                        pw.Text('STRN: $strn',
                            style: PdfDocumentTheme.subtitleStyle(fonts)),
                      if (ntn != null)
                        pw.Text('NTN: $ntn',
                            style: PdfDocumentTheme.subtitleStyle(fonts)),
                    ],
                  ),
              ],
            ),
          ],
          PdfDocumentTheme.divider(),

          // Bill To & Order Details
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BILL TO:',
                      style: PdfDocumentTheme.bodyStyle(fonts, bold: true)),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    Formatters.textForExport(invoice.customerName),
                    style: PdfDocumentTheme.titleStyle(fonts, size: 14),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    '${AppStrings.orderNumber}: ${Formatters.textForExport(invoice.orderNumber)}',
                    style: PdfDocumentTheme.subtitleStyle(fonts),
                  ),
                  pw.Text(
                    '${AppStrings.date}: ${dateFormat.format(invoice.createdAt)}',
                    style: PdfDocumentTheme.subtitleStyle(fonts),
                  ),
                  if (invoice.dueDate != null)
                    pw.Text(
                      '${AppStrings.paymentDueDate}: ${dateFormat.format(invoice.dueDate!)}',
                      style: PdfDocumentTheme.subtitleStyle(fonts),
                    ),
                ],
              ),
            ],
          ),
          PdfDocumentTheme.divider(),

          // Line Items Table
          pw.Text(
            AppStrings.lineItems,
            style: PdfDocumentTheme.bodyStyle(fonts, bold: true),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfDocumentTheme.border),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              PdfDocumentTheme.tableHeaderRow(
                fonts,
                [AppStrings.description, AppStrings.amount],
              ),
              for (final item in invoice.lineItems)
                PdfDocumentTheme.tableDataRow(fonts, [
                  Formatters.textForExport(item.description),
                  item.amount > 0
                      ? Formatters.currencyForExport(item.amount)
                      : Formatters.exportEmpty,
                ]),
            ],
          ),
          pw.SizedBox(height: 16),

          // Summary Section
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
          PdfDocumentTheme.summaryRow(
            fonts,
            AppStrings.amountDue,
            Formatters.currencyForExport(invoice.dueAmount),
            bold: true,
          ),

          // Bank Accounts Section if present
          if (profile != null && profile.bankAccounts.isNotEmpty) ...[
            PdfDocumentTheme.divider(),
            pw.Text(
              'Bank Accounts & Remittance',
              style: PdfDocumentTheme.bodyStyle(fonts, bold: true),
            ),
            pw.SizedBox(height: 6),
            for (final acc in profile.bankAccounts)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  '• ${acc.bankName}: Title: ${acc.accountName} | Acc #: ${acc.accountNumber}'
                  '${acc.iban != null && acc.iban!.isNotEmpty ? " | IBAN: ${acc.iban}" : ""}',
                  style: PdfDocumentTheme.subtitleStyle(fonts),
                ),
              ),
          ],

          // Payment History
          if (payments.isNotEmpty) ...[
            PdfDocumentTheme.divider(),
            pw.Text(
              AppStrings.paymentHistory,
              style: PdfDocumentTheme.bodyStyle(fonts, bold: true),
            ),
            pw.SizedBox(height: 8),
            for (final payment in payments)
              PdfDocumentTheme.summaryRow(
                fonts,
                '${dateFormat.format(payment.paymentDate)} - ${payment.method.label}',
                Formatters.currencyForExport(payment.amount),
              ),
          ],

          // Terms and Conditions
          if (termsText != null) ...[
            PdfDocumentTheme.divider(),
            pw.Text(
              'Terms & Conditions',
              style: PdfDocumentTheme.bodyStyle(fonts, bold: true),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              termsText,
              style: PdfDocumentTheme.subtitleStyle(fonts),
            ),
          ],

          PdfDocumentTheme.divider(),
          pw.Center(
            child: pw.Text(
              footerNoteText,
              style: PdfDocumentTheme.subtitleStyle(fonts),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  /// Generates Job Work Invoice PDF bytes (Uint8List).
  Future<Uint8List> generateJobWorkInvoicePdf({
    required JobWorkInvoice invoice,
    FactoryProfile? factoryProfile,
    List<Payment> payments = const [],
  }) async {
    final doc = await buildJobWorkInvoicePdf(
      invoice: invoice,
      factoryProfile: factoryProfile,
      payments: payments,
    );
    return doc.save();
  }

  /// Builds a pw.Document for Job Work Invoice.
  Future<pw.Document> buildJobWorkInvoicePdf({
    required JobWorkInvoice invoice,
    FactoryProfile? factoryProfile,
    List<Payment> payments = const [],
    String factoryName = AppStrings.appName,
  }) async {
    final fonts = await PdfFonts.load();
    final dateFormat = DateFormat.yMMMd();

    final factoryRepo = _factoryRepository ?? getIt<FactoryRepository>();
    final profile = factoryProfile ?? await factoryRepo.getFactory(invoice.factoryId);
    final rawPhone = profile?.contact.phone.trim();
    final rawProfPhone = profile?.phone?.trim();
    String? factoryPhone = rawPhone != null && rawPhone.isNotEmpty
        ? rawPhone
        : rawProfPhone != null && rawProfPhone.isNotEmpty
            ? rawProfPhone
            : null;

    final rawAddr = profile?.contact.fullAddress.trim();
    final rawProfAddr = profile?.address?.trim();
    String? factoryAddress = rawAddr != null && rawAddr.isNotEmpty
        ? rawAddr
        : rawProfAddr != null && rawProfAddr.isNotEmpty
            ? rawProfAddr
            : null;

    if (profile != null && profile.name.trim().isNotEmpty) {
      factoryName = profile.name.trim();
    }

    final jobWorkRepo = _jobWorkRepository ?? getIt<JobWorkRepository>();
    final loadRepo = _loadRepository ?? getIt<JobWorkLoadRepository>();

    final order = await jobWorkRepo.getJobWorkOrder(invoice.jobWorkId);
    if (order != null) {
      final allLoads = await loadRepo.fetchLoadsForJobWork(
        factoryId: invoice.factoryId,
        jobWorkId: invoice.jobWorkId,
      );
      final collections = await getIt<JobWorkCollectionRepository>().fetchCollectionsForJobWork(
        factoryId: invoice.factoryId,
        jobWorkOrderId: invoice.jobWorkId,
      );

      Uint8List? logoBytes;
      try {
        final byteData = await rootBundle.load('assets/images/app_logo.png');
        logoBytes = byteData.buffer.asUint8List();
      } catch (_) {}

      final isGrandInvoice = invoice.loadId == null || invoice.loadId!.trim().isEmpty;

      // Fetch ALL invoices for this job work so the PDF template gets
      // authoritative per-load payment data (load-scoped invoices with
      // correct paidAmount and loadId) instead of stubs with paidAmount=0.
      List<JobWorkInvoice> allInvoices = [];
      try {
        final invoiceRepo = getIt<JobWorkInvoiceRepository>();
        allInvoices = await invoiceRepo.getInvoicesByJobWorkId(
          factoryId: invoice.factoryId,
          jobWorkId: invoice.jobWorkId,
        );
      } catch (_) {
        // Fall back to single invoice if fetch fails
        allInvoices = [invoice];
      }

      if (isGrandInvoice) {
        return GrandInvoicePdfTemplate.build(
          invoice: invoice,
          order: order,
          loads: allLoads,
          collections: collections,
          payments: payments,
          factoryProfile: profile,
          fonts: fonts,
          logoBytes: logoBytes,
          allInvoices: allInvoices,
        );
      } else {
        final specificLoad = allLoads.where((l) => l.id == invoice.loadId).firstOrNull;
        if (specificLoad != null) {
          final loadCollections = collections.where((c) => c.loadId == invoice.loadId).toList();
          return GrandInvoicePdfTemplate.build(
            invoice: invoice,
            order: order,
            loads: [specificLoad],
            collections: loadCollections,
            payments: payments,
            factoryProfile: profile,
            fonts: fonts,
            logoBytes: logoBytes,
            allInvoices: allInvoices,
          );
        }
      }
    }

    final data = ProformaInvoicePdfTemplate.fromJobWorkInvoice(
      invoice: invoice,
      factoryName: factoryName,
      factoryPhone: factoryPhone,
      factoryAddress: factoryAddress,
      dateFormat: dateFormat,
    );

    if (payments.isNotEmpty) {
      final paymentNotes = payments
          .map(
            (payment) =>
                'Payment ${dateFormat.format(payment.paymentDate)} (${payment.method.label}): '
                '${Formatters.currencyForExport(payment.amount)}',
          )
          .toList();
      return ProformaInvoicePdfTemplate.build(
        data: ProformaInvoiceData(
          companyName: data.companyName,
          phone: data.phone,
          email: data.email,
          website: data.website,
          address: data.address,
          billTo: data.billTo,
          receiptNumber: data.receiptNumber,
          documentTitle: data.documentTitle,
          lineItems: data.lineItems,
          notes: [...data.notes, ...paymentNotes],
          sumTotal: data.sumTotal,
          taxes: data.taxes,
          total: data.total,
        ),
        fonts: fonts,
      );
    }

    return ProformaInvoicePdfTemplate.build(data: data, fonts: fonts);
  }
}
