import 'dart:typed_data';

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
    final dateFormat = DateFormat.yMMMd();

    final factoryRepo = _factoryRepository ?? getIt<FactoryRepository>();
    final profile = factoryProfile ??
        (invoice.factoryId.isNotEmpty
            ? await factoryRepo.getFactory(invoice.factoryId)
            : null);

    final branding = await PdfFactoryBranding.resolve(
      profile: profile,
      fallbackName: factoryName,
      defaultTagline: 'PREMIUM MANUFACTURING & SALES',
    );

    final termsText =
        profile?.invoiceSettings.termsAndConditions?.trim().isNotEmpty == true
            ? profile!.invoiceSettings.termsAndConditions!.trim()
            : null;
    final footerNoteText = branding.footerNote ??
        'Thank you for your business with ${branding.factoryName}!';
    final isPaid = invoice.dueAmount <= 0;

    final doc = pw.Document(theme: fonts.theme);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: PdfDocumentTheme.pageMargin,
        theme: fonts.theme,
        header: (context) {
          if (context.pageNumber == 1) return pw.SizedBox.shrink();
          return PdfDocumentTheme.pageHeaderStrip(
            fonts: fonts,
            left: '${branding.factoryName} · SALES INVOICE',
            right: invoice.invoiceNumber,
          );
        },
        footer: (context) => PdfDocumentTheme.pageFooterStrip(
          fonts: fonts,
          factoryName: branding.factoryName,
          context: context,
        ),
        build: (context) => [
          PdfDocumentTheme.factoryHeader(
            fonts: fonts,
            branding: branding,
            documentTitle: 'SALES INVOICE',
            metaRows: [
              (label: 'Invoice No:', value: invoice.invoiceNumber),
              (label: 'Date Issued:', value: dateFormat.format(invoice.createdAt)),
              if (invoice.dueDate != null)
                (
                  label: 'Due Date:',
                  value: dateFormat.format(invoice.dueDate!),
                ),
              (
                label: 'Order No:',
                value: Formatters.textForExport(invoice.orderNumber),
              ),
            ],
            statusLabel: isPaid ? 'FULLY PAID' : 'OUTSTANDING DUE',
            statusPositive: isPaid,
          ),
          PdfDocumentTheme.divider(),
          PdfDocumentTheme.infoBanner(
            fonts: fonts,
            title: 'Client / Bill To',
            children: [
              PdfDocumentTheme.cardRow(
                fonts,
                'Client Name',
                Formatters.textForExport(invoice.customerName),
              ),
              PdfDocumentTheme.cardRow(
                fonts,
                'Account Type',
                'Sales Order',
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            AppStrings.lineItems.toUpperCase(),
            style: PdfDocumentTheme.sectionTitleStyle(fonts),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfDocumentTheme.borderLight,
              width: 0.8,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              PdfDocumentTheme.tableHeaderRow(
                fonts,
                [AppStrings.description, AppStrings.amount],
              ),
              for (var i = 0; i < invoice.lineItems.length; i++)
                PdfDocumentTheme.tableDataRow(
                  fonts,
                  [
                    Formatters.textForExport(invoice.lineItems[i].description),
                    invoice.lineItems[i].amount > 0
                        ? Formatters.currencyForExport(
                            invoice.lineItems[i].amount,
                          )
                        : Formatters.exportEmpty,
                  ],
                  index: i,
                ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfDocumentTheme.goldBg,
              border: pw.Border.all(
                color: PdfDocumentTheme.borderLight,
                width: 0.8,
              ),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              children: [
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
              ],
            ),
          ),
          if (profile != null && profile.bankAccounts.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            PdfDocumentTheme.detailCard(
              fonts: fonts,
              title: 'Bank Accounts & Remittance',
              rows: [
                for (final acc in profile.bankAccounts)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Text(
                      '• ${acc.bankName}: Title: ${acc.accountName} | Acc #: ${acc.accountNumber}'
                      '${acc.iban != null && acc.iban!.isNotEmpty ? " | IBAN: ${acc.iban}" : ""}',
                      style: PdfDocumentTheme.subtitleStyle(fonts, size: 7.5),
                    ),
                  ),
              ],
            ),
          ],
          if (payments.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            PdfDocumentTheme.detailCard(
              fonts: fonts,
              title: AppStrings.paymentHistory,
              rows: [
                for (final payment in payments)
                  PdfDocumentTheme.summaryRow(
                    fonts,
                    '${dateFormat.format(payment.paymentDate)} - ${payment.method.label}',
                    Formatters.currencyForExport(payment.amount),
                  ),
              ],
            ),
          ],
          if (termsText != null) ...[
            pw.SizedBox(height: 12),
            PdfDocumentTheme.infoBanner(
              fonts: fonts,
              title: 'Terms & Conditions',
              children: [
                pw.Text(
                  termsText,
                  style: PdfDocumentTheme.subtitleStyle(fonts, size: 7.5),
                ),
              ],
            ),
          ],
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              footerNoteText,
              style: PdfDocumentTheme.subtitleStyle(fonts, size: 7.5),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 16),
          PdfDocumentTheme.authorizationBlock(
            fonts: fonts,
            branding: branding,
            preparedLabel: 'Prepared By',
            authorizedLabel: 'Authorized Signature & Stamp',
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

      final branding = await PdfFactoryBranding.resolve(profile: profile);
      final logoBytes = branding.logoBytes;

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
