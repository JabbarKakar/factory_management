import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/di/injection.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/job_work_invoice.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/sales_invoice.dart';
import '../../repositories/factory_repository.dart';
import '../../repositories/job_work_repository.dart';
import '../../repositories/job_work_load_repository.dart';
import '../../repositories/job_work_collection_repository.dart';
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
  Future<pw.Document> buildSalesInvoicePdf({
    required SalesInvoice invoice,
    required List<Payment> payments,
    String factoryName = AppStrings.appName,
  }) async {
    final fonts = await PdfFonts.load();
    final doc = pw.Document();
    final dateFormat = DateFormat.yMMMd();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: fonts.theme,
        build: (context) => [
          PdfDocumentTheme.header(
            fonts: fonts,
            title: factoryName,
            subtitle: AppStrings.salesInvoice,
            rightLabel: invoice.invoiceNumber,
          ),
          PdfDocumentTheme.divider(),
          pw.Text(
            Formatters.textForExport(invoice.customerName),
            style: PdfDocumentTheme.titleStyle(fonts, size: 14),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${AppStrings.orderNumber}: ${Formatters.textForExport(invoice.orderNumber)}',
            style: PdfDocumentTheme.subtitleStyle(fonts),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${AppStrings.date}: ${dateFormat.format(invoice.createdAt)}',
            style: PdfDocumentTheme.subtitleStyle(fonts),
          ),
          PdfDocumentTheme.divider(),
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
          if (invoice.dueDate != null)
            PdfDocumentTheme.summaryRow(
              fonts,
              AppStrings.paymentDueDate,
              dateFormat.format(invoice.dueDate!),
            ),
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
        ],
      ),
    );

    return doc;
  }

  Future<pw.Document> buildJobWorkInvoicePdf({
    required JobWorkInvoice invoice,
    required List<Payment> payments,
    String factoryName = AppStrings.appName,
  }) async {
    final fonts = await PdfFonts.load();
    final dateFormat = DateFormat.yMMMd();

    final factoryRepo = _factoryRepository ?? getIt<FactoryRepository>();
    final profile = await factoryRepo.getFactory(invoice.factoryId);
    String? factoryPhone = profile?.phone?.trim();
    String? factoryAddress = profile?.address?.trim();
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
