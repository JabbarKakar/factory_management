import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/sales/sales_agreement_detail_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/services/sales_container_sync_helper.dart';
import '../../../domain/entities/sales_agreement.dart';
import '../../../domain/entities/sales_order.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/sales_agreement_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/compact_status_chip.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_detail_row.dart';
import '../../widgets/job_work/job_work_detail_section.dart';
import '../../widgets/sales/sales_order_list_tile.dart';

class SalesAgreementDetailScreen extends StatelessWidget {
  const SalesAgreementDetailScreen({
    required this.agreementId,
    super.key,
  });

  final String agreementId;

  Color _accentFor(SalesAgreementSummaryStatus status) {
    return switch (status) {
      SalesAgreementSummaryStatus.active => AppColors.primary,
      SalesAgreementSummaryStatus.pendingDelivery => AppColors.warning,
      SalesAgreementSummaryStatus.idle => AppColors.textSecondary,
      SalesAgreementSummaryStatus.cancelled =>
        AppColors.error.withValues(alpha: 0.72),
    };
  }

  Future<void> _openAddOrder(BuildContext context) async {
    final saved = await context.push<bool>(
      RoutePaths.salesAddOrder(agreementId),
    );
    if (saved == true && context.mounted) {
      context.read<SalesAgreementDetailBloc>().add(
            const SalesAgreementDetailRefreshRequested(),
          );
    }
  }

  Future<void> _openEditAgreement(BuildContext context) async {
    final saved = await context.push<bool>(
      RoutePaths.salesEdit(agreementId),
    );
    if (saved == true && context.mounted) {
      context.read<SalesAgreementDetailBloc>().add(
            const SalesAgreementDetailRefreshRequested(),
          );
    }
  }

  Future<void> _openGrandInvoice(
    BuildContext context, {
    required bool generate,
  }) async {
    await context.push(
      RoutePaths.salesGrandInvoice(
        agreementId,
        generateMissing: generate,
      ),
    );
    if (context.mounted) {
      context.read<SalesAgreementDetailBloc>().add(
            const SalesAgreementDetailRefreshRequested(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = context.userCanCreate(AppModule.sales);
    final canEdit = context.userCanEdit(AppModule.sales);

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
                  onPressed: () => _openEditAgreement(context),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: AppStrings.editSalesAgreement,
                ),
              if (showAddOrder)
                IconButton(
                  onPressed: () => _openAddOrder(context),
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
                onGenerateGrand: () =>
                    _openGrandInvoice(context, generate: true),
                onViewGrand: () =>
                    _openGrandInvoice(context, generate: false),
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
                title: AppStrings.allOrders,
                icon: Icons.shopping_bag_outlined,
                action: showAddOrder
                    ? TextButton.icon(
                        onPressed: () => _openAddOrder(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(AppStrings.addSalesOrder),
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
                            for (var i = 0; i < orders.length; i++) ...[
                              SalesOrderListTile(
                                order: orders[i],
                                onTap: () => context.push(
                                  RoutePaths.salesOrderDetail(
                                    agreementId: agreementId,
                                    salesOrderId: orders[i].id,
                                  ),
                                ),
                              ),
                              if (i < orders.length - 1)
                                const SizedBox(height: 0),
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
                          CompactStatusChip(
                            label: agreement.summaryStatus.label,
                            color: statusColor,
                          ),
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
                      if (canGenerateGrand || canViewGrand) ...[
                        const SizedBox(height: 10),
                        Divider(
                          height: 1,
                          color: outline.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 10),
                        if (canGenerateGrand)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: onGenerateGrand,
                              icon: const Icon(Icons.receipt_long_outlined),
                              label: const Text(AppStrings.generateGrandInvoice),
                            ),
                          )
                        else if (canViewGrand)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: onViewGrand,
                              icon: const Icon(Icons.receipt_long_outlined),
                              label: const Text(AppStrings.viewGrandInvoice),
                            ),
                          ),
                      ],
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
