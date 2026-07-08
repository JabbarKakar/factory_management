import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/sales/sales_order_form_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/delivery.dart';
import '../../../domain/entities/sales_order.dart';
import '../../../domain/entities/stock_output.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/delivery_enums.dart';
import '../../../domain/enums/sales_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/job_work/job_work_detail_row.dart';
import '../../widgets/job_work/job_work_detail_section.dart';
import '../../widgets/job_work/stock_output_recording_panel.dart';
import '../../widgets/sales/sales_order_detail_hero.dart';

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

        final canEdit = order.status == SalesOrderStatus.received &&
            context.userCanEdit(AppModule.sales);
        final nextStatus = order.status.nextStatus;
        final isSaving = state.status == SalesOrderFormStatus.saving;
        final canInvoice = order.status == SalesOrderStatus.ready ||
            order.status == SalesOrderStatus.invoiced ||
            order.status == SalesOrderStatus.paid;
        final hasInvoice =
            order.invoiceId != null && order.invoiceId!.isNotEmpty;
        final showDeliveries = state.deliveries.isNotEmpty ||
            (canInvoice && order.status != SalesOrderStatus.closed);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.salesOrderDetails),
                Text(
                  order.orderNumber,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: (Theme.of(context).appBarTheme.foregroundColor ??
                                Theme.of(context).colorScheme.onSurface)
                            .withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
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
              SalesOrderDetailHero(
                order: order,
                isSaving: isSaving,
                canInvoice: canInvoice,
                hasInvoice: hasInvoice,
                onAdvanceStatus: nextStatus != null
                    ? () => _advanceStatus(context, nextStatus)
                    : null,
                onScheduleDelivery: canInvoice
                    ? () => context.push(
                          RoutePaths.deliveriesAddForOrder(order.id),
                        )
                    : null,
                onOpenInvoice:
                    canInvoice ? () => _openInvoice(context) : null,
                onRecordPayment: hasInvoice &&
                        order.status != SalesOrderStatus.paid &&
                        order.balanceDue > 0
                    ? () => _openRecordPayment(context, order.invoiceId!)
                    : null,
              ),
              JobWorkDetailSection(
                title: AppStrings.lineItems,
                icon: Icons.list_alt_outlined,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < order.lineItems.length; i++) ...[
                        _SalesLineItemCard(item: order.lineItems[i]),
                        if (i < order.lineItems.length - 1)
                          const SizedBox(height: 12),
                      ],
                      if (order.lineItems.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        StockOutputReadOnlyPanel(
                          smallOutputs: _aggregateSmall(order.lineItems),
                          largeOutputs: _aggregateLarge(order.lineItems),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (showDeliveries)
                JobWorkDetailSection(
                  title: AppStrings.orderDeliveries,
                  icon: Icons.local_shipping_outlined,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: state.deliveries.isEmpty
                        ? Text(
                            AppStrings.noOrderDeliveries,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          )
                        : Column(
                            children: [
                              for (var i = 0;
                                  i < state.deliveries.length;
                                  i++) ...[
                                _DeliveryRow(
                                  delivery: state.deliveries[i],
                                  onTap: isSaving
                                      ? null
                                      : () => context.push(
                                            RoutePaths.deliveryDetail(
                                              state.deliveries[i].id,
                                            ),
                                          ),
                                ),
                                if (i < state.deliveries.length - 1)
                                  const SizedBox(height: 6),
                              ],
                            ],
                          ),
                  ),
                ),
              JobWorkDetailSection(
                title: AppStrings.salesOrderTotals,
                icon: Icons.payments_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.totalPieces,
                      value: '${order.totalPieces}',
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.totalSquareFeet,
                      value: '${order.totalSquareFeet.toStringAsFixed(2)} sq. ft',
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.grandTotal,
                      value: Formatters.currencyPkr(order.grandTotal),
                      bold: true,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.advanceReceived,
                      value: Formatters.currencyPkr(order.advanceReceived),
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.balanceDue,
                      value: Formatters.currencyPkr(order.balanceDue),
                      bold: true,
                      highlight: order.balanceDue > 0,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.paymentTerms,
                      value: order.paymentTerms.label,
                    ),
                    if (order.paymentDueDate != null)
                      JobWorkDetailRow(
                        label: AppStrings.paymentDueDate,
                        value:
                            DateFormat.yMMMd().format(order.paymentDueDate!),
                      ),
                  ],
                ),
              ),
              JobWorkDetailSection(
                title: AppStrings.orderDetails,
                icon: Icons.receipt_long_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.orderDate,
                      value: DateFormat.yMMMd().format(order.orderDate),
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.orderSource,
                      value: order.orderSource.label,
                    ),
                    if (order.expectedDeliveryDate != null)
                      JobWorkDetailRow(
                        label: AppStrings.expectedDelivery,
                        value: DateFormat.yMMMd()
                            .format(order.expectedDeliveryDate!),
                      ),
                    if (order.deliveryAddress != null &&
                        order.deliveryAddress!.isNotEmpty)
                      JobWorkDetailRow(
                        label: AppStrings.deliveryAddress,
                        value: order.deliveryAddress!,
                      ),
                    if (order.specialInstructions != null &&
                        order.specialInstructions!.isNotEmpty)
                      JobWorkDetailRow(
                        label: AppStrings.specialInstructions,
                        value: order.specialInstructions!,
                      ),
                    if (order.closedAt != null)
                      JobWorkDetailRow(
                        label: AppStrings.closedDate,
                        value: DateFormat.yMMMd().format(order.closedAt!),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

List<StockOutput> _aggregateSmall(List<SalesOrderLineItem> items) {
  final outputs = <StockOutput>[];
  for (final item in items) {
    outputs.addAll(item.activeSmallOutputs);
  }
  return outputs;
}

List<StockOutput> _aggregateLarge(List<SalesOrderLineItem> items) {
  final outputs = <StockOutput>[];
  for (final item in items) {
    outputs.addAll(item.activeLargeOutputs);
  }
  return outputs;
}

class _SalesLineItemCard extends StatelessWidget {
  const _SalesLineItemCard({required this.item});

  final SalesOrderLineItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.productType.label} — ${item.marbleVariety}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  Formatters.currencyPkr(item.lineTotal),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${item.totalPieces} pcs · '
              '${item.totalSquareFeet.toStringAsFixed(2)} sq. ft',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: muted,
                height: 1.35,
              ),
            ),
            if (item.activeOutputs.isNotEmpty) ...[
              const SizedBox(height: 10),
              StockOutputReadOnlyPanel(
                smallOutputs: item.activeSmallOutputs,
                largeOutputs: item.activeLargeOutputs,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  const _DeliveryRow({
    required this.delivery,
    this.onTap,
  });

  final Delivery delivery;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final accent = _accentFor(delivery.status);
    final dateLabel = DateFormat.yMMMd().format(delivery.scheduledDate);

    return Material(
      color: accent.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 14,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery.deliveryNumber,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  delivery.status.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: muted.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _accentFor(DeliveryStatus status) {
    return switch (status) {
      DeliveryStatus.scheduled => const Color(0xFF1565C0),
      DeliveryStatus.loaded => const Color(0xFF3949AB),
      DeliveryStatus.inTransit => AppColors.warning,
      DeliveryStatus.delivered => AppColors.success,
      DeliveryStatus.partiallyDelivered => AppColors.success,
      DeliveryStatus.failed => AppColors.error,
    };
  }
}
