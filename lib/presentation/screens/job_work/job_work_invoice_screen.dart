import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/job_work/job_work_invoice_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../data/services/export/invoice_excel_exporter.dart';
import '../../../data/services/export/invoice_pdf_exporter.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/invoice_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/export_actions.dart';
import '../../utils/export_factory_name.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/export_menu_button.dart';
import '../../widgets/invoice_reminder_history_section.dart';
import '../../widgets/job_work/job_work_invoice_detail_hero.dart';
import '../../widgets/job_work/job_work_invoice_line_items_section.dart';
import '../../widgets/job_work/job_work_invoice_payment_action_bar.dart';
import '../../widgets/job_work/job_work_invoice_pricing_section.dart';
import '../../widgets/send_payment_reminder_button.dart';

class JobWorkInvoiceScreen extends StatelessWidget {
  const JobWorkInvoiceScreen({required this.jobWorkId, super.key});

  final String jobWorkId;

  Future<void> _recordPayment(BuildContext context) async {
    final state = context.read<JobWorkInvoiceBloc>().state;
    final invoice = state.invoice;
    if (invoice == null) return;

    final recorded = await context.push<bool>(
      RoutePaths.recordPayment(invoice.id),
    );
    if (recorded == true && context.mounted) {
      context.read<JobWorkInvoiceBloc>().add(
            JobWorkInvoiceLoadByJobWork(jobWorkId),
          );
    }
  }

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
            state.status == JobWorkInvoiceStatus.initial ||
            (state.status == JobWorkInvoiceStatus.saving &&
                state.invoice == null)) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.jobWorkInvoice)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == JobWorkInvoiceStatus.notFound) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.jobWorkInvoice)),
            body: EmptyStateView(
              icon: Icons.receipt_long_outlined,
              title: AppStrings.invoiceNotReady,
              action: FilledButton.icon(
                onPressed: () => context.read<JobWorkInvoiceBloc>().add(
                      JobWorkInvoiceGenerateRequested(jobWorkId),
                    ),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text(AppStrings.generateInvoice),
              ),
            ),
          );
        }

        final invoice = state.invoice;
        if (invoice == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.jobWorkInvoice)),
            body: EmptyStateView(
              icon: Icons.error_outline,
              title: state.errorMessage ?? 'Invoice not available',
            ),
          );
        }

        final isSaving = state.status == JobWorkInvoiceStatus.saving;
        final appBarForeground =
            Theme.of(context).appBarTheme.foregroundColor ??
                Theme.of(context).colorScheme.onSurface;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.jobWorkInvoice),
                Text(
                  invoice.invoiceNumber,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: appBarForeground.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
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
                    final bytes =
                        getIt<InvoiceExcelExporter>().buildJobWorkInvoice(
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
                SendPaymentReminderButton(
                  customerId: invoice.customerId,
                  customerName: invoice.customerName,
                  invoiceId: invoice.id,
                  invoiceNumber: invoice.invoiceNumber,
                  invoiceType: InvoiceType.jobWork,
                  amountDue: invoice.dueAmount,
                  dueDate: invoice.dueDate,
                  isOverdue: invoice.status == InvoiceStatus.overdue,
                ),
              if (invoice.dueAmount > 0)
                IconButton(
                  onPressed: isSaving ? null : () => _recordPayment(context),
                  icon: const Icon(Icons.payments_outlined),
                  tooltip: AppStrings.recordPayment,
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              JobWorkInvoiceDetailHero(invoice: invoice),
              if (invoice.dueAmount > 0)
                JobWorkInvoicePaymentActionBar(
                  enabled: !isSaving,
                  onRecordPayment: () => _recordPayment(context),
                ),
              JobWorkInvoiceLineItemsSection(lineItems: invoice.lineItems),
              JobWorkInvoicePricingSection(invoice: invoice),
              JobWorkInvoicePaymentHistorySection(payments: state.payments),
              InvoiceReminderHistorySection(invoiceId: invoice.id),
            ],
          ),
        );
      },
    );
  }
}
