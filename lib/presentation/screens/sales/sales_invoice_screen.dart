import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/sales/sales_invoice_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../data/services/export/invoice_excel_exporter.dart';
import '../../../data/services/export/invoice_pdf_exporter.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/invoice_enums.dart';
import '../../../domain/entities/payment.dart';
import '../../routes/route_paths.dart';
import '../../utils/export_actions.dart';
import '../../utils/export_factory_name.dart';
import '../../utils/auth_context.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/export_menu_button.dart';
import '../../widgets/invoice_reminder_history_section.dart';
import '../../widgets/job_work/job_work_invoice_line_items_section.dart';
import '../../widgets/job_work/job_work_invoice_payment_action_bar.dart';
import '../../widgets/job_work/job_work_invoice_payment_history_section.dart';
import '../../widgets/sales/sales_invoice_detail_hero.dart';
import '../../widgets/sales/sales_invoice_pricing_section.dart';
import '../../widgets/send_payment_reminder_button.dart';

class SalesInvoiceScreen extends StatelessWidget {
  const SalesInvoiceScreen({required this.salesOrderId, super.key});

  final String salesOrderId;

  Future<void> _reload(BuildContext context) async {
    final factoryId = readFactoryId(context);
    if (factoryId == null) return;
    context.read<SalesInvoiceBloc>().add(
          SalesInvoiceLoadByOrder(
            factoryId: factoryId,
            salesOrderId: salesOrderId,
          ),
        );
  }

  Future<void> _recordPayment(BuildContext context) async {
    final state = context.read<SalesInvoiceBloc>().state;
    final invoice = state.invoice;
    if (invoice == null) return;

    final recorded = await context.push<bool>(
      RoutePaths.salesRecordPayment(invoice.id),
    );
    if (recorded == true && context.mounted) {
      await _reload(context);
    }
  }

  Future<void> _editPayment(BuildContext context, Payment payment) async {
    final state = context.read<SalesInvoiceBloc>().state;
    final invoice = state.invoice;
    if (invoice == null) return;

    final updated = await context.push<bool>(
      RoutePaths.salesRecordPaymentEdit(invoice.id, payment.id),
    );
    if (updated == true && context.mounted) {
      await _reload(context);
    }
  }

  Future<void> _deletePayment(BuildContext context, Payment payment) async {
    final bloc = context.read<SalesInvoiceBloc>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deletePaymentTitle,
      message: AppStrings.deletePaymentMessage,
      confirmLabel: AppStrings.deletePayment,
      destructive: true,
      onConfirm: () async {
        bloc.add(SalesInvoicePaymentDeleteRequested(payment.id));
        final next = await bloc.stream.firstWhere(
          (state) =>
              state.status == SalesInvoiceStatus.paymentRecorded ||
              state.status == SalesInvoiceStatus.failure,
        );
        if (next.status == SalesInvoiceStatus.failure) {
          throw Exception(next.errorMessage ?? 'Could not delete payment.');
        }
      },
    );
    if (!confirmed || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.paymentDeleted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SalesInvoiceBloc, SalesInvoiceState>(
      listener: (context, state) {
        if (state.status == SalesInvoiceStatus.generated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.invoiceGenerated)),
          );
        }
        if (state.status == SalesInvoiceStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == SalesInvoiceStatus.loading ||
            state.status == SalesInvoiceStatus.initial ||
            (state.status == SalesInvoiceStatus.saving &&
                state.invoice == null)) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.salesInvoice)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == SalesInvoiceStatus.notFound) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.salesInvoice)),
            body: EmptyStateView(
              icon: Icons.receipt_long_outlined,
              title: AppStrings.salesInvoiceNotReady,
              action: FilledButton.icon(
                onPressed: () => context.read<SalesInvoiceBloc>().add(
                      SalesInvoiceGenerateRequested(salesOrderId),
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
            appBar: AppBar(title: const Text(AppStrings.salesInvoice)),
            body: EmptyStateView(
              icon: Icons.error_outline,
              title: state.errorMessage ?? 'Invoice not available',
            ),
          );
        }

        final isSaving = state.status == SalesInvoiceStatus.saving;
        final canCorrectPayments =
            context.userCanEdit(AppModule.sales) && state.payments.isNotEmpty;
        final canEditInvoice = context.userCanEdit(AppModule.sales) &&
            invoice.status != InvoiceStatus.cancelled;
        final appBarForeground =
            Theme.of(context).appBarTheme.foregroundColor ??
                Theme.of(context).colorScheme.onSurface;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.salesInvoice),
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
              if (canEditInvoice)
                IconButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final updated = await context.push<bool>(
                            RoutePaths.salesInvoiceEdit(invoice.id),
                          );
                          if (updated == true && context.mounted) {
                            await _reload(context);
                          }
                        },
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: AppStrings.editInvoice,
                ),
              if (context.userCanExport(AppModule.sales))
                ExportMenuButton(
                  onExportPdf: (origin) async {
                    final factoryName = await resolveExportFactoryName(context);
                    final exporter = getIt<InvoicePdfExporter>();
                    final doc = await exporter.buildSalesInvoicePdf(
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
                    final bytes = getIt<InvoiceExcelExporter>().buildSalesInvoice(
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
                    final doc = await exporter.buildSalesInvoicePdf(
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
                  invoiceType: InvoiceType.sales,
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
              SalesInvoiceDetailHero(invoice: invoice),
              if (invoice.dueAmount > 0)
                JobWorkInvoicePaymentActionBar(
                  enabled: !isSaving,
                  onRecordPayment: () => _recordPayment(context),
                ),
              JobWorkInvoiceLineItemsSection(lineItems: invoice.lineItems),
              SalesInvoicePricingSection(invoice: invoice),
              JobWorkInvoicePaymentHistorySection(
                payments: state.payments,
                canCorrect: canCorrectPayments,
                onEdit: canCorrectPayments
                    ? (payment) => _editPayment(context, payment)
                    : null,
                onDelete: canCorrectPayments
                    ? (payment) => _deletePayment(context, payment)
                    : null,
              ),
              InvoiceReminderHistorySection(invoiceId: invoice.id),
            ],
          ),
        );
      },
    );
  }
}
