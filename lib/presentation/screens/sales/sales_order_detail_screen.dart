import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/sales/sales_order_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/enums/sales_enums.dart';
import '../../routes/route_paths.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/sales/sales_order_status_badge.dart';
import '../../widgets/settings_section.dart';

class SalesOrderDetailScreen extends StatelessWidget {
  const SalesOrderDetailScreen({required this.salesOrderId, super.key});

  final String salesOrderId;

  Future<void> _openInvoice(BuildContext context) async {
    await context.push(RoutePaths.salesInvoice(salesOrderId));
    if (context.mounted) {
      context
          .read<SalesOrderFormBloc>()
          .add(SalesOrderFormLoadRequested(salesOrderId));
    }
  }

  Future<void> _openRecordPayment(
    BuildContext context,
    String invoiceId,
  ) async {
    final recorded = await context.push<bool>(
      RoutePaths.salesRecordPayment(invoiceId),
    );
    if (recorded == true && context.mounted) {
      context
          .read<SalesOrderFormBloc>()
          .add(SalesOrderFormLoadRequested(salesOrderId));
    }
  }

  Future<void> _advanceStatus(
    BuildContext context,
    SalesOrderStatus nextStatus,
  ) async {
    if (nextStatus == SalesOrderStatus.closed) {
      final confirmed = await AppConfirmDialog.show(
        context,
        title: AppStrings.closeSalesOrderTitle,
        message: AppStrings.closeSalesOrderMessage,
        confirmLabel: AppStrings.closeJobWorkOrder,
      );
      if (confirmed != true || !context.mounted) return;
    }

    context.read<SalesOrderFormBloc>().add(
          SalesOrderFormStatusAdvanceRequested(
            salesOrderId: salesOrderId,
            newStatus: nextStatus,
          ),
        );
  }

  Future<void> _cancelOrder(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.cancelSalesOrderTitle,
      message: AppStrings.cancelSalesOrderMessage,
      confirmLabel: AppStrings.cancelOrder,
      destructive: true,
    );
    if (confirmed == true && context.mounted) {
      context
          .read<SalesOrderFormBloc>()
          .add(SalesOrderFormCancelRequested(salesOrderId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SalesOrderFormBloc, SalesOrderFormState>(
      listener: (context, state) {
        if (state.status == SalesOrderFormStatus.cancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.salesOrderCancelled)),
          );
          context.pop(true);
        }
        if (state.status == SalesOrderFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );
        }
        if (state.status == SalesOrderFormStatus.ready &&
            state.order != null) {
          // status advanced snackbar handled by rebuild
        }
      },
      builder: (context, state) {
        if (state.status == SalesOrderFormStatus.loading ||
            state.status == SalesOrderFormStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.salesOrderDetails)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final order = state.order;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.salesOrderDetails)),
            body: Center(
              child: Text(state.errorMessage ?? 'Sales order not found'),
            ),
          );
        }

        final canEdit = order.status == SalesOrderStatus.received;
        final nextStatus = order.status.nextStatus;
        final isSaving = state.status == SalesOrderFormStatus.saving;
        final canInvoice = order.status == SalesOrderStatus.ready ||
            order.status == SalesOrderStatus.invoiced ||
            order.status == SalesOrderStatus.paid;
        final hasInvoice = order.invoiceId != null && order.invoiceId!.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.salesOrderDetails),
            actions: [
              if (canEdit)
                IconButton(
                  onPressed: isSaving
                      ? null
                      : () => context.push(RoutePaths.salesEdit(order.id)),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: AppStrings.editSalesOrder,
                ),
              if (canEdit)
                IconButton(
                  onPressed: isSaving ? null : () => _cancelOrder(context),
                  icon: const Icon(Icons.cancel_outlined),
                  tooltip: AppStrings.cancelOrder,
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
                              order.orderNumber,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          SalesOrderStatusBadge(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.customerName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (nextStatus != null) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: isSaving
                                ? null
                                : () => _advanceStatus(context, nextStatus),
                            child: Text(order.status.advanceActionLabel),
                          ),
                        ),
                      ],
                      if (canInvoice) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () => _openInvoice(context),
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: Text(
                              hasInvoice
                                  ? AppStrings.viewInvoice
                                  : AppStrings.generateInvoice,
                            ),
                          ),
                        ),
                      ],
                      if (hasInvoice &&
                          order.status != SalesOrderStatus.paid &&
                          order.balanceDue > 0) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: isSaving
                                ? null
                                : () => _openRecordPayment(
                                      context,
                                      order.invoiceId!,
                                    ),
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text(AppStrings.recordPayment),
                          ),
                        ),
                      ],
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
                      for (final item in order.lineItems) ...[
                        _Row(
                          '${item.productType.label} — ${item.marbleVariety}',
                          Formatters.currencyPkr(item.lineTotal),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${item.sizeThickness} · ${item.quantity} ${item.quantityUnit.label} @ ${Formatters.currencyPkr(item.unitRate)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
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
                        AppStrings.subtotal,
                        Formatters.currencyPkr(order.subtotal),
                      ),
                      const SizedBox(height: 8),
                      if (order.orderDiscount > 0)
                        _Row(
                          AppStrings.orderDiscount,
                          '-${Formatters.currencyPkr(order.orderDiscount)}',
                        ),
                      if (order.tax > 0) ...[
                        const SizedBox(height: 8),
                        _Row(AppStrings.taxAmount, Formatters.currencyPkr(order.tax)),
                      ],
                      const SizedBox(height: 8),
                      _Row(
                        AppStrings.grandTotal,
                        Formatters.currencyPkr(order.grandTotal),
                        bold: true,
                      ),
                      const SizedBox(height: 8),
                      _Row(
                        AppStrings.advanceReceived,
                        Formatters.currencyPkr(order.advanceReceived),
                      ),
                      const SizedBox(height: 8),
                      _Row(
                        AppStrings.balanceDue,
                        Formatters.currencyPkr(order.balanceDue),
                        bold: true,
                      ),
                      const SizedBox(height: 8),
                      _Row(AppStrings.paymentTerms, order.paymentTerms.label),
                      if (order.paymentDueDate != null) ...[
                        const SizedBox(height: 8),
                        _Row(
                          AppStrings.paymentDueDate,
                          DateFormat.yMMMd().format(order.paymentDueDate!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SettingsSection(
                title: AppStrings.orderDetails,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _Row(
                        AppStrings.orderDate,
                        DateFormat.yMMMd().format(order.orderDate),
                      ),
                      const SizedBox(height: 8),
                      _Row(AppStrings.orderSource, order.orderSource.label),
                      if (order.expectedDeliveryDate != null) ...[
                        const SizedBox(height: 8),
                        _Row(
                          AppStrings.expectedDelivery,
                          DateFormat.yMMMd().format(order.expectedDeliveryDate!),
                        ),
                      ],
                      if (order.deliveryAddress != null &&
                          order.deliveryAddress!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _Row(AppStrings.deliveryAddress, order.deliveryAddress!),
                      ],
                      if (order.specialInstructions != null &&
                          order.specialInstructions!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _Row(
                          AppStrings.specialInstructions,
                          order.specialInstructions!,
                        ),
                      ],
                      if (order.closedAt != null) ...[
                        const SizedBox(height: 8),
                        _Row(
                          AppStrings.closedDate,
                          DateFormat.yMMMd().format(order.closedAt!),
                        ),
                      ],
                    ],
                  ),
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
