import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/job_work/job_work_invoice_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../routes/route_paths.dart';
import '../../../core/di/injection.dart';
import '../../../data/services/export/invoice_excel_exporter.dart';
import '../../../data/services/export/invoice_pdf_exporter.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../utils/export_actions.dart';
import '../../utils/export_factory_name.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/export_menu_button.dart';
import '../../widgets/job_work/invoice_status_badge.dart';
import '../../widgets/settings_section.dart';

class JobWorkInvoiceScreen extends StatelessWidget {
  const JobWorkInvoiceScreen({required this.jobWorkId, super.key});

  final String jobWorkId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JobWorkInvoiceBloc, JobWorkInvoiceState>(
      listener: (context, state) {
        if (state.status == JobWorkInvoiceStatus.generated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.invoiceGenerated)),
          );
        }
        if (state.status == JobWorkInvoiceStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == JobWorkInvoiceStatus.loading ||
            state.status == JobWorkInvoiceStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.jobWorkInvoice)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == JobWorkInvoiceStatus.notFound) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.jobWorkInvoice)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.invoiceNotReady,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: state.status == JobWorkInvoiceStatus.saving
                          ? null
                          : () => context.read<JobWorkInvoiceBloc>().add(
                                JobWorkInvoiceGenerateRequested(jobWorkId),
                              ),
                      icon: const Icon(Icons.receipt_long),
                      label: const Text(AppStrings.generateInvoice),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final invoice = state.invoice;
        if (invoice == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.jobWorkInvoice)),
            body: Center(
              child: Text(state.errorMessage ?? 'Invoice not available'),
            ),
          );
        }

        final isSaving = state.status == JobWorkInvoiceStatus.saving;

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.jobWorkInvoice),
            actions: [
              if (context.userCanExport(AppModule.jobWork))
                ExportMenuButton(
                  onExportPdf: (origin) async {
                    final factoryName = await resolveExportFactoryName(context);
                    final exporter = getIt<InvoicePdfExporter>();
                    final doc = await exporter.buildJobWorkInvoicePdf(
                      invoice: invoice,
                      payments: state.payments,
                      factoryName: factoryName,
                    );
                    await ExportActions.sharePdf(
                      document: doc,
                      filename: '${invoice.invoiceNumber}.pdf',
                      sharePositionOrigin: origin,
                    );
                  },
                  onExportExcel: (origin) async {
                    final factoryName = await resolveExportFactoryName(context);
                    final bytes = getIt<InvoiceExcelExporter>().buildJobWorkInvoice(
                      invoice: invoice,
                      payments: state.payments,
                      factoryName: factoryName,
                    );
                    await ExportActions.shareExcel(
                      bytes: bytes,
                      filename: '${invoice.invoiceNumber}.xlsx',
                      sharePositionOrigin: origin,
                    );
                  },
                  onPrint: () async {
                    final factoryName = await resolveExportFactoryName(context);
                    final exporter = getIt<InvoicePdfExporter>();
                    final doc = await exporter.buildJobWorkInvoicePdf(
                      invoice: invoice,
                      payments: state.payments,
                      factoryName: factoryName,
                    );
                    await ExportActions.printPdf(
                      document: doc,
                      filename: '${invoice.invoiceNumber}.pdf',
                    );
                  },
                ),
              if (invoice.dueAmount > 0)
                IconButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final recorded = await context.push<bool>(
                            RoutePaths.recordPayment(invoice.id),
                          );
                          if (recorded == true && context.mounted) {
                            context.read<JobWorkInvoiceBloc>().add(
                                  JobWorkInvoiceLoadByJobWork(jobWorkId),
                                );
                          }
                        },
                  icon: const Icon(Icons.payments_outlined),
                  tooltip: AppStrings.recordPayment,
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              invoice.invoiceNumber,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          InvoiceStatusBadge(status: invoice.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(invoice.customerName),
                      Text(
                        invoice.jobWorkNumber,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              SettingsSection(
                title: AppStrings.lineItems,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (final item in invoice.lineItems) ...[
                        _Row(
                          item.description,
                          item.amount > 0
                              ? Formatters.currencyPkr(item.amount)
                              : '—',
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
              SettingsSection(
                title: AppStrings.pricingAgreement,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _Row(
                        AppStrings.invoiceTotal,
                        Formatters.currencyPkr(invoice.totalAmount),
                      ),
                      const SizedBox(height: 8),
                      _Row(
                        AppStrings.amountPaid,
                        Formatters.currencyPkr(invoice.paidAmount),
                      ),
                      const SizedBox(height: 8),
                      _Row(
                        AppStrings.amountDue,
                        Formatters.currencyPkr(invoice.dueAmount),
                        bold: true,
                      ),
                      if (invoice.dueDate != null) ...[
                        const SizedBox(height: 8),
                        _Row(
                          AppStrings.paymentDueDate,
                          DateFormat.yMMMd().format(invoice.dueDate!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SettingsSection(
                title: AppStrings.paymentHistory,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: state.payments.isEmpty
                      ? Text(AppStrings.noPaymentsYet)
                      : Column(
                          children: [
                            for (final payment in state.payments) ...[
                              _Row(
                                '${DateFormat.yMMMd().format(payment.paymentDate)} · ${payment.method.label}',
                                Formatters.currencyPkr(payment.amount),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                ),
              ),
              if (invoice.dueAmount > 0)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final recorded = await context.push<bool>(
                              RoutePaths.recordPayment(invoice.id),
                            );
                            if (recorded == true && context.mounted) {
                              context.read<JobWorkInvoiceBloc>().add(
                                    JobWorkInvoiceLoadByJobWork(jobWorkId),
                                  );
                            }
                          },
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text(AppStrings.recordPayment),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: TextStyle(color: muted)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
