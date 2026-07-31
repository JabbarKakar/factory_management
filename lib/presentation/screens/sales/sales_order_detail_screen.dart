import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/sales/sales_order_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/services/delivery_quantity_helper.dart';
import '../../../data/services/sales_order_dispatch_status_helper.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/sales_order.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/sales_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/delivery/delivery_history_section.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/job_work/job_work_detail_row.dart';
import '../../widgets/job_work/job_work_detail_section.dart';
import '../../widgets/job_work/job_work_invoice_payment_history_section.dart';
import '../../widgets/job_work/stock_output_recording_panel.dart';
import '../../widgets/sales/sales_order_detail_hero.dart';

class SalesOrderDetailScreen extends StatelessWidget {
  const SalesOrderDetailScreen({
    required this.salesOrderId,
    this.agreementId,
    super.key,
  });

  final String salesOrderId;
  final String? agreementId;

  String? _resolveAgreementId(BuildContext context) {
    final fromParam = agreementId?.trim() ?? '';
    if (fromParam.isNotEmpty) return fromParam;
    final fromOrder =
        context.read<SalesOrderFormBloc>().state.order?.agreementId?.trim() ??
            '';
    return fromOrder.isEmpty ? null : fromOrder;
  }

  Future<void> _openInvoice(BuildContext context) async {
    final resolvedAgreementId = _resolveAgreementId(context);
    if (resolvedAgreementId == null) {
      await context.push(RoutePaths.salesOrderLink(salesOrderId));
      return;
    }
    await context.push(
      RoutePaths.salesInvoice(
        agreementId: resolvedAgreementId,
        salesOrderId: salesOrderId,
      ),
    );
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
    await context.push<bool>(
      RoutePaths.salesRecordPayment(invoiceId),
    );
  }

  Future<void> _editPayment(BuildContext context, Payment payment) async {
    await context.push<bool>(
      RoutePaths.salesRecordPaymentEdit(payment.invoiceId, payment.id),
    );
  }

  Future<void> _deletePayment(BuildContext context, Payment payment) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deletePaymentTitle,
      message: AppStrings.deletePaymentMessage,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await getIt<PaymentRepository>().deletePayment(payment.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.paymentDeleted)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not delete payment. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _openEdit(BuildContext context) async {
    final resolvedAgreementId = _resolveAgreementId(context);
    final saved = await context.push<bool>(
      resolvedAgreementId == null
          ? RoutePaths.salesOrderLink(salesOrderId)
          : RoutePaths.salesOrderEdit(
              agreementId: resolvedAgreementId,
              salesOrderId: salesOrderId,
            ),
    );
    if (saved == true && context.mounted) {
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
        final canMutateSales = context.userCanEdit(AppModule.sales);
        final canInvoice = order.status == SalesOrderStatus.ready ||
            order.status == SalesOrderStatus.partiallyDispatched ||
            order.status == SalesOrderStatus.invoiced ||
            order.status == SalesOrderStatus.paid ||
            order.status == SalesOrderStatus.delivered;
        final canDispatch =
            SalesOrderDispatchStatusHelper.canScheduleDispatch(order.status);
        final invoice = state.invoice;
        final hasInvoice = invoice != null ||
            (order.invoiceId != null && order.invoiceId!.isNotEmpty);
        final invoiceId = invoice?.id ?? order.invoiceId;
        final showInvoiceSection = context.userCanView(AppModule.sales) &&
            (canInvoice ||
                hasInvoice ||
                order.status == SalesOrderStatus.ready ||
                order.status == SalesOrderStatus.partiallyDispatched);
        final dueForPayment = invoice?.dueAmount ?? order.balanceDue;
        final canCorrectPayments =
            canMutateSales && state.payments.isNotEmpty && invoice != null;
        final showDeliveries = state.deliveries.isNotEmpty ||
            canDispatch ||
            order.status == SalesOrderStatus.delivered;
        final dispatchTotals = DeliveryQuantityHelper.orderTotals(
          order,
          state.deliveries,
        );
        final showDispatchSummary =
            (canInvoice || order.status == SalesOrderStatus.delivered) &&
            order.status != SalesOrderStatus.closed;

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
                  onPressed: isSaving ? null : () => _openEdit(context),
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
                onScheduleDelivery: canDispatch
                    ? () => context.push(
                          RoutePaths.deliveriesAddForOrder(order.id),
                        )
                    : null,
                onOpenInvoice: (hasInvoice || canMutateSales) &&
                        (canInvoice || hasInvoice)
                    ? () => _openInvoice(context)
                    : null,
                onRecordPayment: canMutateSales &&
                        hasInvoice &&
                        dueForPayment > 0 &&
                        invoiceId != null &&
                        invoiceId.isNotEmpty
                    ? () => _openRecordPayment(context, invoiceId)
                    : null,
              ),
              JobWorkDetailSection(
                title: AppStrings.lineItems,
                icon: Icons.list_alt_outlined,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < order.lineItems.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.18),
                          ),
                        _SalesLineItemCard(
                          item: order.lineItems[i],
                          index: i,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (showInvoiceSection) ...[
                JobWorkDetailSection(
                  title: AppStrings.salesInvoice,
                  icon: Icons.receipt_long_outlined,
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!hasInvoice)
                        if (canMutateSales)
                          FilledButton(
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: isSaving
                                ? null
                                : () => _openInvoice(context),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 14),
                                SizedBox(width: 4),
                                Text(AppStrings.generateInvoice),
                              ],
                            ),
                          )
                        else
                          const SizedBox.shrink()
                      else ...[
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            minimumSize: const Size(0, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: isSaving
                              ? null
                              : () => _openInvoice(context),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 14),
                              SizedBox(width: 4),
                              Text(AppStrings.viewInvoice),
                            ],
                          ),
                        ),
                        if (canMutateSales &&
                            dueForPayment > 0 &&
                            invoiceId != null &&
                            invoiceId.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: isSaving
                                ? null
                                : () => _openRecordPayment(context, invoiceId),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.payments_outlined, size: 14),
                                SizedBox(width: 4),
                                Text(AppStrings.recordPayment),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                  child: invoice != null
                      ? JobWorkDetailRows(
                          rows: [
                            JobWorkDetailRow(
                              label: AppStrings.invoiceNumber,
                              value: invoice.invoiceNumber,
                              bold: true,
                            ),
                            JobWorkDetailRow(
                              label: AppStrings.totalAmountLabel,
                              value: Formatters.currencyPkr(invoice.totalAmount),
                            ),
                            JobWorkDetailRow(
                              label: AppStrings.amountPaid,
                              value: Formatters.currencyPkr(invoice.paidAmount),
                            ),
                            JobWorkDetailRow(
                              label: AppStrings.balanceDue,
                              value: Formatters.currencyPkr(invoice.dueAmount),
                              bold: invoice.dueAmount > 0,
                              highlight: invoice.dueAmount > 0,
                            ),
                            if (invoice.dueDate != null)
                              JobWorkDetailRow(
                                label: AppStrings.paymentDueDate,
                                value: DateFormat.yMMMd()
                                    .format(invoice.dueDate!),
                              ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            AppStrings.salesInvoiceNotReady,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                ),
                if (invoice != null)
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
              ],
              if (showDispatchSummary)
                JobWorkDetailSection(
                  title: AppStrings.stockDispatchSummary,
                  icon: Icons.inventory_2_outlined,
                  child: JobWorkDetailRows(
                    rows: [
                      JobWorkDetailRow(
                        label: AppStrings.totalPieces,
                        value: '${dispatchTotals.totalPieces}',
                      ),
                      JobWorkDetailRow(
                        label: AppStrings.piecesDispatched,
                        value: '${dispatchTotals.dispatchedPieces}',
                      ),
                      JobWorkDetailRow(
                        label: AppStrings.piecesRemaining,
                        value: '${dispatchTotals.remainingPieces}',
                        bold: true,
                        highlight: dispatchTotals.remainingPieces > 0,
                      ),
                      JobWorkDetailRow(
                        label: AppStrings.totalSquareFeet,
                        value:
                            '${dispatchTotals.totalSquareFeet.toStringAsFixed(2)} sq. ft',
                      ),
                      JobWorkDetailRow(
                        label: AppStrings.squareFeetDispatched,
                        value:
                            '${dispatchTotals.dispatchedSquareFeet.toStringAsFixed(2)} sq. ft',
                      ),
                      JobWorkDetailRow(
                        label: AppStrings.squareFeetRemaining,
                        value:
                            '${dispatchTotals.remainingSquareFeet.toStringAsFixed(2)} sq. ft',
                        bold: true,
                        highlight: dispatchTotals.remainingSquareFeet > 0,
                      ),
                    ],
                  ),
                ),
              if (showDeliveries)
                DeliveryHistorySection(
                  deliveries: state.deliveries,
                  enabled: !isSaving,
                  onScheduleDelivery: canDispatch
                      ? () => context.push(
                            RoutePaths.deliveriesAddForOrder(order.id),
                          )
                      : null,
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

class _SalesLineItemCard extends StatelessWidget {
  const _SalesLineItemCard({
    required this.item,
    required this.index,
  });

  final SalesOrderLineItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${AppStrings.lineItem} ${index + 1}: '
                '${item.productType.label} â€” ${item.marbleVariety}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
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
        subtitle: Text(
          '${item.totalPieces} pcs · '
          '${item.totalSquareFeet.toStringAsFixed(2)} sq. ft',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: muted,
            height: 1.35,
          ),
        ),
        children: [
          if (item.activeOutputs.isNotEmpty)
            StockOutputReadOnlyPanel(
              smallOutputs: item.activeSmallOutputs,
              largeOutputs: item.activeLargeOutputs,
            ),
        ],
      ),
    );
  }
}

