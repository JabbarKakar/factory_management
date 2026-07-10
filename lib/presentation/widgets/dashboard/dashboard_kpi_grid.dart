import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/dashboard_kpis.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/delivery_enums.dart';
import '../../../domain/enums/equipment_enums.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../../../domain/enums/notification_enums.dart';
import '../../../domain/enums/quality_enums.dart';
import '../../../domain/enums/raw_material_enums.dart';
import '../../../domain/enums/sales_enums.dart';
import '../../../domain/extensions/app_user_permissions.dart';
import '../../routes/route_paths.dart';
import 'dashboard_surface.dart';

class DashboardKpiGrid extends StatelessWidget {
  const DashboardKpiGrid({required this.kpis, required this.user, super.key});

  final DashboardKpis kpis;
  final AppUser? user;

  bool _canView(AppModule module) => user?.canView(module) ?? false;

  VoidCallback? _tap(VoidCallback action, AppModule module) {
    return _canView(module) ? action : null;
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(context);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(
          title: 'Quick overview',
          subtitle: 'Key metrics at a glance',
          icon: Icons.insights_rounded,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount =
                _responsiveCrossAxisCount(constraints.maxWidth);
            final tileHeight = _kpiTileHeight(context, items);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: tileHeight,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  _KpiTile(item: items[index]),
            );
          },
        ),
      ],
    );
  }

  /// Mobile: 2 per row. Tablet/desktop: more columns from available width.
  int _responsiveCrossAxisCount(double width) {
    if (width < 600) return 2;
    if (width < 900) return 3;
    if (width < 1200) return 4;
    if (width < 1600) return 5;

    const spacing = 8.0;
    const minTileWidth = 150.0;
    final computed =
        ((width + spacing) / (minTileWidth + spacing)).floor();
    return computed.clamp(6, 10);
  }

  double _kpiTileHeight(BuildContext context, List<_KpiItem> items) {
    final textScale =
        MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.2);
    final hasSubtitle = items.any((item) => item.subtitle != null);
    final base = hasSubtitle ? 108.0 : 92.0;
    return base * textScale;
  }

  List<_KpiItem> _buildItems(BuildContext context) {
    return <_KpiItem>[
      if (_canView(AppModule.sales) || _canView(AppModule.jobWork))
        _KpiItem(
          label: AppStrings.revenueToday,
          value: Formatters.currencyPkr(kpis.revenueToday),
          subtitle: kpis.revenueToday > 0
              ? 'Sales ${Formatters.currencyPkr(kpis.salesRevenueToday)} · JW ${Formatters.currencyPkr(kpis.jobWorkRevenueToday)}'
              : AppStrings.paymentsReceivedToday,
          icon: Icons.payments_outlined,
          color: AppColors.success,
          onTap: _tap(
            () => context.push(RoutePaths.notifications),
            AppModule.notifications,
          ),
        ),
      if (_canView(AppModule.plReport))
        _KpiItem(
          label: AppStrings.revenueThisMonth,
          value: Formatters.currencyPkr(kpis.revenueThisMonth),
          subtitle: AppStrings.paymentsReceivedThisMonth,
          icon: Icons.trending_up_rounded,
          color: AppColors.success,
          onTap: _tap(() => context.push(RoutePaths.plReport), AppModule.plReport),
        ),
      if (_canView(AppModule.notifications))
        _KpiItem(
          label: AppStrings.dueThisWeek,
          value: Formatters.currencyPkr(kpis.dueThisWeekAmount),
          subtitle: kpis.dueThisWeekCount > 0
              ? '${kpis.dueThisWeekCount} invoice(s)'
              : AppStrings.noDuesThisWeek,
          icon: Icons.schedule_rounded,
          color: AppColors.dueSoon,
          onTap: _tap(
            () => context.push(
              RoutePaths.notificationsWithFilter(NotificationFilter.dueThisWeek),
            ),
            AppModule.notifications,
          ),
        ),
      if (_canView(AppModule.production) || _canView(AppModule.jobWork))
        _KpiItem(
          label: AppStrings.productionToday,
          value: Formatters.stockQuantity(kpis.productionTodaySqFt, 'sq. ft'),
          subtitle: kpis.productionTodaySqFt > 0
              ? 'Own ${Formatters.stockQuantity(kpis.ownProductionTodaySqFt, 'sq. ft')} · JW ${Formatters.stockQuantity(kpis.jobWorkOutputTodaySqFt, 'sq. ft')}'
              : AppStrings.productionTodaySubtitle,
          icon: Icons.precision_manufacturing_outlined,
          color: AppColors.primary,
          onTap: _tap(
            () => context.push(RoutePaths.production),
            AppModule.production,
          ),
        ),
      if (_canView(AppModule.jobWork))
        _KpiItem(
          label: AppStrings.activeJobWork,
          value: '${kpis.activeJobWorkCount}',
          icon: Icons.content_cut_rounded,
          color: AppColors.primary,
          onTap: _tap(
            () => context.go(
              RoutePaths.jobWorkList(filter: JobWorkListStageFilter.inProgress),
            ),
            AppModule.jobWork,
          ),
        ),
      if (_canView(AppModule.sales))
        _KpiItem(
          label: AppStrings.activeSales,
          value: '${kpis.activeSalesCount}',
          subtitle: AppStrings.activeSalesOrders,
          icon: Icons.shopping_bag_outlined,
          color: AppColors.primary,
          onTap: _tap(
            () => context.go(RoutePaths.salesList(filter: 'inProgress')),
            AppModule.sales,
          ),
        ),
      if (_canView(AppModule.sales) && kpis.partiallyDispatchedOrdersCount > 0)
        _KpiItem(
          label: AppStrings.partiallyDispatchedOrders,
          value: '${kpis.partiallyDispatchedOrdersCount}',
          subtitle: AppStrings.partiallyDispatchedOrdersSubtitle,
          icon: Icons.local_shipping_outlined,
          color: const Color(0xFF0277BD),
          onTap: _tap(
            () => context.go(
              RoutePaths.salesList(filter: SalesListFilter.partiallyDispatched.name),
            ),
            AppModule.sales,
          ),
        ),
      if (_canView(AppModule.sales) && kpis.readyForDispatchCount > 0)
        _KpiItem(
          label: AppStrings.readyForDispatch,
          value: '${kpis.readyForDispatchCount}',
          subtitle: AppStrings.readyForDispatchSubtitle,
          icon: Icons.inventory_2_outlined,
          color: AppColors.success,
          onTap: _tap(
            () => context.go(
              RoutePaths.salesList(filter: SalesListFilter.ready.name),
            ),
            AppModule.sales,
          ),
        ),
      if (_canView(AppModule.jobWork))
        _KpiItem(
          label: AppStrings.pendingPickups,
          value: '${kpis.pendingPickupCount}',
          subtitle: AppStrings.pendingPickupsSubtitle,
          icon: Icons.inventory_2_outlined,
          color: AppColors.accent,
          onTap: _tap(
            () => context.go(
              RoutePaths.jobWorkList(filter: JobWorkListStageFilter.pendingPickup),
            ),
            AppModule.jobWork,
          ),
        ),
      if (_canView(AppModule.jobWork) && kpis.partiallyCollectedOrdersCount > 0)
        _KpiItem(
          label: AppStrings.partiallyCollectedOrders,
          value: '${kpis.partiallyCollectedOrdersCount}',
          subtitle: AppStrings.partiallyCollectedOrdersSubtitle,
          icon: Icons.handshake_outlined,
          color: AppColors.warning,
          onTap: _tap(
            () => context.go(
              RoutePaths.jobWorkList(
                filter: JobWorkListStageFilter.partiallyCollected,
              ),
            ),
            AppModule.jobWork,
          ),
        ),
      if (_canView(AppModule.jobWork) && kpis.stalePickupCount > 0)
        _KpiItem(
          label: AppStrings.pickupOverdue,
          value: '${kpis.stalePickupCount}',
          subtitle: AppStrings.pendingPickupsSubtitle,
          icon: Icons.schedule_outlined,
          color: AppColors.overdue,
          onTap: _tap(
            () => context.go(
              RoutePaths.jobWorkList(filter: JobWorkListStageFilter.pendingPickup),
            ),
            AppModule.jobWork,
          ),
        ),
      if (_canView(AppModule.notifications))
        _KpiItem(
          label: AppStrings.overdueTotal,
          value: Formatters.currencyPkr(kpis.overdueAmount),
          subtitle:
              kpis.overdueCount > 0 ? '${kpis.overdueCount} invoice(s)' : null,
          icon: Icons.warning_amber_rounded,
          color: AppColors.overdue,
          onTap: _tap(
            () => context.push(
              RoutePaths.notificationsWithFilter(NotificationFilter.overdue),
            ),
            AppModule.notifications,
          ),
        ),
      if (_canView(AppModule.expenses))
        _KpiItem(
          label: AppStrings.factoryExpenses,
          value: Formatters.currencyPkr(kpis.expensesThisMonth),
          subtitle: kpis.expenseCountThisMonth > 0
              ? '${kpis.expenseCountThisMonth} ${AppStrings.expenseEntriesThisMonth}'
              : AppStrings.expensesThisMonth,
          icon: Icons.receipt_long_outlined,
          color: AppColors.warning,
          onTap: _tap(() => context.push(RoutePaths.expenses), AppModule.expenses),
        ),
      if (_canView(AppModule.rawMaterials))
        _KpiItem(
          label: AppStrings.lowStockMaterials,
          value: '${kpis.lowStockCount}',
          subtitle: kpis.lowStockCount > 0
              ? AppStrings.lowStock
              : AppStrings.rawMaterialStock,
          icon: Icons.inventory_2_outlined,
          color: kpis.lowStockCount > 0 ? AppColors.warning : AppColors.accent,
          onTap: _tap(
            () => context.push(
              RoutePaths.rawMaterialsList(filter: RawMaterialListFilter.lowStock),
            ),
            AppModule.rawMaterials,
          ),
        ),
      if (_canView(AppModule.delivery))
        _KpiItem(
          label: AppStrings.pendingDeliveries,
          value: '${kpis.activeDeliveriesCount}',
          subtitle: kpis.scheduledDeliveriesToday > 0
              ? '${kpis.scheduledDeliveriesToday} ${AppStrings.scheduledDeliveriesToday}'
              : null,
          icon: Icons.local_shipping_outlined,
          color: AppColors.primary,
          onTap: _tap(
            () => context.go(
              RoutePaths.deliveriesList(filter: DeliveryListFilter.active),
            ),
            AppModule.delivery,
          ),
        ),
      if (_canView(AppModule.delivery) && kpis.overdueDeliveriesCount > 0)
        _KpiItem(
          label: AppStrings.overdueDeliveries,
          value: '${kpis.overdueDeliveriesCount}',
          subtitle: AppStrings.overdueDeliveriesSubtitle,
          icon: Icons.warning_amber_rounded,
          color: AppColors.overdue,
          onTap: _tap(
            () => context.go(
              RoutePaths.deliveriesList(filter: DeliveryListFilter.overdue),
            ),
            AppModule.delivery,
          ),
        ),
      if (_canView(AppModule.delivery) &&
          (kpis.dispatchedTodayPieces > 0 || kpis.dispatchedTodaySquareFeet > 0))
        _KpiItem(
          label: AppStrings.dispatchedToday,
          value: '${kpis.dispatchedTodayPieces} pcs',
          subtitle:
              '${kpis.dispatchedTodaySquareFeet.toStringAsFixed(2)} sq. ft · '
              '${AppStrings.dispatchedTodaySubtitle}',
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.success,
          onTap: _tap(
            () => context.go(
              RoutePaths.deliveriesList(filter: DeliveryListFilter.delivered),
            ),
            AppModule.delivery,
          ),
        ),
      if (_canView(AppModule.equipment) &&
          (kpis.maintenanceOverdueCount > 0 ||
              kpis.maintenanceDueSoonCount > 0))
        _KpiItem(
          label: AppStrings.maintenanceDueKpi,
          value: kpis.maintenanceOverdueCount > 0
              ? '${kpis.maintenanceOverdueCount}'
              : '${kpis.maintenanceDueSoonCount}',
          subtitle: kpis.maintenanceOverdueCount > 0
              ? AppStrings.maintenanceOverdue
              : AppStrings.maintenanceDueSoon,
          icon: Icons.build_circle_outlined,
          color: kpis.maintenanceOverdueCount > 0
              ? AppColors.overdue
              : AppColors.warning,
          onTap: _tap(
            () => context.go(
              RoutePaths.equipmentList(
                filter: EquipmentListFilter.maintenanceDue,
              ),
            ),
            AppModule.equipment,
          ),
        ),
      if (_canView(AppModule.qualityControl) &&
          (kpis.jobWorkPendingQcCount > 0 || kpis.qcRejectsThisMonth > 0))
        _KpiItem(
          label: AppStrings.qcAttentionKpi,
          value: kpis.jobWorkPendingQcCount > 0
              ? '${kpis.jobWorkPendingQcCount}'
              : '${kpis.qcRejectsThisMonth}',
          subtitle: kpis.jobWorkPendingQcCount > 0
              ? AppStrings.jobWorkAwaitingQc
              : AppStrings.qcRejectsThisMonth,
          icon: Icons.verified_outlined,
          color: kpis.jobWorkPendingQcCount > 0
              ? AppColors.warning
              : AppColors.overdue,
          onTap: _tap(
            () {
              if (kpis.jobWorkPendingQcCount > 0) {
                context.go(
                  RoutePaths.jobWorkList(filter: JobWorkListStageFilter.atQc),
                );
              } else {
                context.push(
                  RoutePaths.qualityChecksList(filter: QcListFilter.reject),
                );
              }
            },
            AppModule.qualityControl,
          ),
        ),
      if (_canView(AppModule.labour))
        _KpiItem(
          label: AppStrings.presentLabourToday,
          value: kpis.activeLabourCount > 0
              ? '${kpis.presentLabourToday} / ${kpis.activeLabourCount}'
              : '0',
          subtitle: kpis.unmarkedAttendanceToday > 0
              ? '${kpis.unmarkedAttendanceToday} ${AppStrings.attendanceUnmarked.toLowerCase()}'
              : AppStrings.labourAttendanceToday,
          icon: Icons.groups_outlined,
          color: kpis.unmarkedAttendanceToday > 0
              ? AppColors.warning
              : AppColors.success,
          onTap: _tap(() => context.push(RoutePaths.attendance), AppModule.labour),
        ),
      if (_canView(AppModule.customers))
        _KpiItem(
          label: AppStrings.customerCount,
          value: '${kpis.customerCount}',
          icon: Icons.people_outline_rounded,
          color: AppColors.accent,
          onTap: _tap(() => context.go(RoutePaths.customers), AppModule.customers),
        ),
    ];
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.item});

  final _KpiItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardSurfaceCard(
      compact: true,
      borderRadius: 12,
      padding: const EdgeInsets.all(8),
      onTap: item.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, size: 14, color: item.color),
              ),
              const Spacer(),
              if (item.onTap != null)
                Icon(
                  Icons.north_east_rounded,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              fontSize: 14,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: 10,
              height: 1.1,
            ),
          ),
          if (item.subtitle != null)
            Text(
              item.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: item.color,
                fontWeight: FontWeight.w600,
                fontSize: 9,
                height: 1.1,
              ),
            ),
        ],
      ),
    );
  }
}

class _KpiItem {
  const _KpiItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}
