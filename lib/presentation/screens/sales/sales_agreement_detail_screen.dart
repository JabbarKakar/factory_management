import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/sales/sales_agreement_detail_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/sales_order_repository.dart';
import '../../../data/services/sales_container_sync_helper.dart';
import '../../../data/services/sales_order_dispatch_status_helper.dart';
import '../../../domain/entities/sales_agreement.dart';
import '../../../domain/entities/sales_order.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/sales_agreement_enums.dart';
import '../../../domain/enums/sales_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_detail_row.dart';
import '../../widgets/job_work/job_work_detail_section.dart';
import '../../widgets/sales/sales_order_list_tile.dart';
import '../../widgets/tile_options_menu.dart';

class SalesAgreementDetailScreen extends StatefulWidget {
  const SalesAgreementDetailScreen({
    required this.agreementId,
    super.key,
  });

  final String agreementId;

  @override
  State<SalesAgreementDetailScreen> createState() =>
      _SalesAgreementDetailScreenState();
}

class _SalesAgreementDetailScreenState
    extends State<SalesAgreementDetailScreen> {
  String? _busyOrderId;

  Color _accentFor(SalesAgreementSummaryStatus status) {
    return switch (status) {
      SalesAgreementSummaryStatus.active => AppColors.primary,
      SalesAgreementSummaryStatus.pendingDelivery => AppColors.warning,
      SalesAgreementSummaryStatus.idle => AppColors.textSecondary,
      SalesAgreementSummaryStatus.cancelled =>
        AppColors.error.withValues(alpha: 0.72),
    };
  }

  void _refresh() {
    context.read<SalesAgreementDetailBloc>().add(
          const SalesAgreementDetailRefreshRequested(),
        );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  Future<void> _openAddOrder() async {
    final saved = await context.push<bool>(
      RoutePaths.salesAddOrder(widget.agreementId),
    );
    if (saved == true && mounted) _refresh();
  }

  Future<void> _openEditAgreement() async {
    final saved = await context.push<bool>(
      RoutePaths.salesEdit(widget.agreementId),
    );
    if (saved == true && mounted) _refresh();
  }

  Future<void> _openGrandInvoice({required bool generate}) async {
    await context.push(
      RoutePaths.salesGrandInvoice(
        widget.agreementId,
        generateMissing: generate,
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _confirmDelete(SalesOrder order) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deleteSalesOrderTitle,
      message: AppStrings.deleteSalesOrderMessage,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busyOrderId = order.id);
    try {
      await getIt<SalesOrderRepository>().deleteSalesOrder(order.id);
      if (!mounted) return;
      _showSnack(AppStrings.salesOrderDeleted);
      _refresh();
    } catch (_) {
      if (!mounted) return;
      _showSnack(AppStrings.salesOrderDeleteError, isError: true);
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  Future<void> _confirmCancel(SalesOrder order) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.cancelSalesOrderTitle,
      message: AppStrings.cancelSalesOrderMessage,
      confirmLabel: AppStrings.cancelOrder,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busyOrderId = order.id);
    try {
      await getIt<SalesOrderRepository>().cancelSalesOrder(order.id);
      if (!mounted) return;
      _showSnack(AppStrings.salesOrderCancelled);
      _refresh();
    } catch (_) {
      if (!mounted) return;
      _showSnack(AppStrings.salesOrderCancelError, isError: true);
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  List<TileMenuAction> _menuActionsFor(
    SalesOrder order, {
    required bool canEdit,
    required bool canDelete,
  }) {
    final status = order.status;
    final hasInvoice = order.invoiceId != null && order.invoiceId!.isNotEmpty;
    final canDispatch =
        SalesOrderDispatchStatusHelper.canScheduleDispatch(status);
    final actions = <TileMenuAction>[];
    final agreementId = order.agreementId?.trim().isNotEmpty == true
        ? order.agreementId!.trim()
        : widget.agreementId;

    if (canEdit) {
      actions.add(
        TileMenuAction(
          label: AppStrings.editSalesOrder,
          icon: Icons.edit_outlined,
          onSelected: () async {
            await context.push(
              RoutePaths.salesOrderEdit(
                agreementId: agreementId,
                salesOrderId: order.id,
              ),
            );
            if (mounted) _refresh();
          },
        ),
      );
    }

    if ((status == SalesOrderStatus.ready ||
            status == SalesOrderStatus.partiallyDispatched) &&
        !hasInvoice) {
      actions.add(
        TileMenuAction(
          label: AppStrings.generateInvoice,
          icon: Icons.receipt_long_outlined,
          onSelected: () async {
            await context.push(
              RoutePaths.salesInvoice(
                agreementId: agreementId,
                salesOrderId: order.id,
              ),
            );
            if (mounted) _refresh();
          },
        ),
      );
    }

    if (hasInvoice) {
      actions.add(
        TileMenuAction(
          label: AppStrings.viewInvoice,
          icon: Icons.receipt_long_outlined,
          onSelected: () async {
            await context.push(
              RoutePaths.salesInvoice(
                agreementId: agreementId,
                salesOrderId: order.id,
              ),
            );
            if (mounted) _refresh();
          },
        ),
      );
      if (order.balanceDue > 0 &&
          status != SalesOrderStatus.closed &&
          status != SalesOrderStatus.cancelled) {
        actions.add(
          TileMenuAction(
            label: AppStrings.recordPayment,
            icon: Icons.payments_outlined,
            onSelected: () async {
              await context.push(
                RoutePaths.salesRecordPayment(order.invoiceId!),
              );
              if (mounted) _refresh();
            },
          ),
        );
      }
    }

    if (canDispatch) {
      actions.add(
        TileMenuAction(
          label: AppStrings.dispatchStock,
          icon: Icons.local_shipping_outlined,
          onSelected: () async {
            await context.push(
              RoutePaths.deliveriesAddForOrder(order.id),
            );
            if (mounted) _refresh();
          },
        ),
      );
    }

    if (canEdit && status != SalesOrderStatus.cancelled) {
      actions.add(
        TileMenuAction(
          label: AppStrings.cancelOrder,
          icon: Icons.cancel_outlined,
          onSelected: () => _confirmCancel(order),
        ),
      );
    }

    if (canDelete) {
      actions.add(
        TileMenuAction(
          label: AppStrings.delete,
          icon: Icons.delete_outline_rounded,
          destructive: true,
          onSelected: () => _confirmDelete(order),
        ),
      );
    }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = context.userCanCreate(AppModule.sales);
    final canEdit = context.userCanEdit(AppModule.sales);
    final canDelete = context.userCanDelete(AppModule.sales);

    return BlocBuilder<SalesAgreementDetailBloc, SalesAgreementDetailState>(
      builder: (context, state) {
        if (state.status == SalesAgreementDetailStatus.loading ||
            state.status == SalesAgreementDetailStatus.initial) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(AppStrings.salesAgreementDetails),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final agreement = state.agreement;
        if (agreement == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(AppStrings.salesAgreementDetails),
            ),
            body: EmptyStateView(
              icon: Icons.error_outline,
              title: AppStrings.salesAgreementLoadError,
              subtitle: state.errorMessage,
            ),
          );
        }

        final orders = List<SalesOrder>.from(state.orders)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final previewOrders = orders.take(5).toList(growable: false);
        final statusColor = _accentFor(agreement.summaryStatus);
        final canGenerateGrand = canEdit &&
            SalesContainerSyncHelper.canGenerateGrandInvoice(
              agreement: agreement,
              orders: state.orders,
              invoices: state.invoices,
            );
        final canViewGrand =
            SalesContainerSyncHelper.canViewGrandInvoice(state.invoices);
        final showAddOrder = canCreate &&
            agreement.summaryStatus != SalesAgreementSummaryStatus.cancelled;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.salesAgreementDetails),
                Text(
                  agreement.agreementNumber,
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
                  onPressed: _openEditAgreement,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: AppStrings.editSalesAgreement,
                ),
              if (showAddOrder)
                IconButton(
                  onPressed: _openAddOrder,
                  icon: const Icon(Icons.add_shopping_cart_outlined),
                  tooltip: AppStrings.addSalesOrder,
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _AgreementHero(
                agreement: agreement,
                statusColor: statusColor,
                canGenerateGrand: canGenerateGrand,
                canViewGrand: canViewGrand,
                onGenerateGrand: () => _openGrandInvoice(generate: true),
                onViewGrand: () => _openGrandInvoice(generate: false),
              ),
              JobWorkDetailSection(
                title: AppStrings.ordersSummary,
                icon: Icons.summarize_outlined,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Column(
                    children: [
                      JobWorkDetailRow(
                        label: 'Total orders',
                        value: '${agreement.orderCount ?? orders.length}',
                      ),
                      const SizedBox(height: 6),
                      JobWorkDetailRow(
                        label: 'Active orders',
                        value: '${agreement.activeOrderCount ?? 0}',
                      ),
                    ],
                  ),
                ),
              ),
              JobWorkDetailSection(
                title: '${AppStrings.allOrders} (${orders.length})',
                icon: Icons.shopping_bag_outlined,
                action: showAddOrder
                    ? FilledButton.tonalIcon(
                        onPressed: _openAddOrder,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text(
                          AppStrings.addSalesOrder,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
                child: orders.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          AppStrings.noOrdersUnderAgreement,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Column(
                          children: [
                            for (var i = 0; i < previewOrders.length; i++) ...[
                              SalesOrderListTile(
                                order: previewOrders[i],
                                isBusy: _busyOrderId == previewOrders[i].id,
                                menuActions: _menuActionsFor(
                                  previewOrders[i],
                                  canEdit: canEdit,
                                  canDelete: canDelete,
                                ),
                                onTap: () async {
                                  await context.push(
                                    RoutePaths.salesOrderDetail(
                                      agreementId: widget.agreementId,
                                      salesOrderId: previewOrders[i].id,
                                    ),
                                  );
                                  if (mounted) _refresh();
                                },
                              ),
                            ],
                            if (orders.length > 5)
                              Center(
                                child: TextButton(
                                  onPressed: () => context.push(
                                    RoutePaths.salesAllOrders(
                                      widget.agreementId,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    '${AppStrings.showAllSales} (${orders.length})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
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

class _AgreementHero extends StatelessWidget {
  const _AgreementHero({
    required this.agreement,
    required this.statusColor,
    required this.canGenerateGrand,
    required this.canViewGrand,
    required this.onGenerateGrand,
    required this.onViewGrand,
  });

  final SalesAgreement agreement;
  final Color statusColor;
  final bool canGenerateGrand;
  final bool canViewGrand;
  final VoidCallback onGenerateGrand;
  final VoidCallback onViewGrand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    const cardShape = BorderRadius.only(
      topRight: Radius.circular(14),
      bottomRight: Radius.circular(14),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: cardShape,
          border: Border.all(color: outline),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              agreement.customerName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (canGenerateGrand || canViewGrand) ...[
                            const SizedBox(width: 8),
                            _InvoiceButton(
                              hasInvoice: !canGenerateGrand && canViewGrand,
                              onPressed: canGenerateGrand
                                  ? onGenerateGrand
                                  : onViewGrand,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        agreement.agreementNumber,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Matches Job Work detail hero invoice CTA styling.
class _InvoiceButton extends StatelessWidget {
  const _InvoiceButton({
    required this.hasInvoice,
    required this.onPressed,
  });

  final bool hasInvoice;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 7 : 12,
          vertical: isCompact ? 3 : 4,
        ),
        minimumSize: Size(0, isCompact ? 25 : 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isCompact) ...[
            Icon(
              hasInvoice
                  ? Icons.receipt_long_outlined
                  : Icons.add_circle_outline,
              size: 14,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            hasInvoice
                ? AppStrings.viewGrandInvoice
                : AppStrings.generateGrandInvoice,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 10.5 : 11,
            ),
          ),
        ],
      ),
    );
  }
}
