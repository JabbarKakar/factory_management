import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/dashboard/dashboard_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/dashboard_kpis.dart';
import '../../../domain/enums/notification_enums.dart';
import '../../../domain/enums/delivery_enums.dart';
import '../../../domain/enums/equipment_enums.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../../../domain/enums/quality_enums.dart';
import '../../../domain/enums/raw_material_enums.dart';
import '../../routes/route_paths.dart';
import '../../widgets/dashboard/dashboard_production_chart_card.dart';
import '../../widgets/dashboard/dashboard_recent_activity_card.dart';
import '../../widgets/dashboard/dashboard_revenue_breakdown_card.dart';
import '../../widgets/dashboard/dashboard_revenue_chart_card.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/payment_reminders_card.dart';
import '../../widgets/pending_pickups_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboard),
        actions: const [
          NotificationBell(),
        ],
      ),
      body: BlocConsumer<DashboardBloc, DashboardState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status &&
            curr.status == DashboardStatus.failure,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.status == DashboardStatus.loading &&
              state.kpis == DashboardKpis.empty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              final factoryId = user?.factoryId;
              if (factoryId != null) {
                context
                    .read<DashboardBloc>()
                    .add(DashboardWatchStarted(factoryId));
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.status == DashboardStatus.failure) ...[
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              state.errorMessage ??
                                  AppStrings.dashboardLoadError,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome${user != null ? ', ${user.name}' : ''}',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.dashboardMvpReady,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (user != null) ...[
                  const SizedBox(height: 16),
                  PaymentRemindersCard(factoryId: user.factoryId),
                ],
                if (state.pendingPickups.isNotEmpty ||
                    state.kpis.pendingPickupCount > 0) ...[
                  const SizedBox(height: 16),
                  PendingPickupsCard(
                    pendingPickups: state.pendingPickups,
                    totalCount: state.kpis.pendingPickupCount,
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  AppStrings.analyticsSection,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                DashboardProductionChartCard(
                  points: state.analytics.productionLast7Days,
                  monthlyOwnProductionSqFt: state.kpis.productionThisMonthSqFt,
                ),
                const SizedBox(height: 12),
                DashboardRevenueChartCard(
                  points: state.analytics.revenueLast30Days,
                ),
                const SizedBox(height: 12),
                DashboardRevenueBreakdownCard(
                  slices: state.analytics.revenueBreakdownThisMonth,
                ),
                const SizedBox(height: 12),
                DashboardRecentActivityCard(
                  items: state.analytics.recentActivity,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.quickActions,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(RoutePaths.jobWorkAdd),
                      icon: const Icon(Icons.content_cut_outlined, size: 18),
                      label: const Text(AppStrings.newJobWorkOrder),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(RoutePaths.salesAdd),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: const Text(AppStrings.newSalesOrder),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(RoutePaths.expensesAdd),
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: const Text(AppStrings.addExpense),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(RoutePaths.expenses),
                      icon: const Icon(Icons.list_alt_outlined, size: 18),
                      label: const Text(AppStrings.viewExpenses),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(RoutePaths.plReport),
                      icon: const Icon(Icons.assessment_outlined, size: 18),
                      label: const Text(AppStrings.monthlyPlReport),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(RoutePaths.productionAdd),
                      icon: const Icon(
                        Icons.precision_manufacturing_outlined,
                        size: 18,
                      ),
                      label: const Text(AppStrings.recordProduction),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(RoutePaths.finishedGoods),
                      icon: const Icon(Icons.layers_outlined, size: 18),
                      label: const Text(AppStrings.finishedGoodsInventory),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(RoutePaths.attendance),
                      icon: const Icon(Icons.fact_check_outlined, size: 18),
                      label: const Text(AppStrings.markAttendance),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(RoutePaths.deliveriesAdd),
                      icon: const Icon(Icons.local_shipping_outlined, size: 18),
                      label: const Text(AppStrings.scheduleDelivery),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(RoutePaths.equipmentAdd),
                      icon: const Icon(
                        Icons.precision_manufacturing_outlined,
                        size: 18,
                      ),
                      label: const Text(AppStrings.addEquipment),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(RoutePaths.employeesAdd),
                      icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                      label: const Text(AppStrings.addEmployee),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(RoutePaths.customersAdd),
                      icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                      label: const Text(AppStrings.addCustomer),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Quick overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                _KpiGrid(kpis: state.kpis),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis});

  final DashboardKpis kpis;

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiItem(
        label: AppStrings.revenueToday,
        value: Formatters.currencyPkr(kpis.revenueToday),
        subtitle: kpis.revenueToday > 0
            ? 'Sales ${Formatters.currencyPkr(kpis.salesRevenueToday)} · JW ${Formatters.currencyPkr(kpis.jobWorkRevenueToday)}'
            : AppStrings.paymentsReceivedToday,
        icon: Icons.payments_outlined,
        color: AppColors.success,
        onTap: () => context.push(RoutePaths.notifications),
      ),
      _KpiItem(
        label: AppStrings.revenueThisMonth,
        value: Formatters.currencyPkr(kpis.revenueThisMonth),
        subtitle: AppStrings.paymentsReceivedThisMonth,
        icon: Icons.trending_up,
        color: AppColors.success,
        onTap: () => context.push(RoutePaths.plReport),
      ),
      _KpiItem(
        label: AppStrings.dueThisWeek,
        value: Formatters.currencyPkr(kpis.dueThisWeekAmount),
        subtitle: kpis.dueThisWeekCount > 0
            ? '${kpis.dueThisWeekCount} invoice(s)'
            : AppStrings.noDuesThisWeek,
        icon: Icons.schedule,
        color: AppColors.dueSoon,
        onTap: () => context.push(
          RoutePaths.notificationsWithFilter(NotificationFilter.dueThisWeek),
        ),
      ),
      _KpiItem(
        label: AppStrings.productionToday,
        value: Formatters.stockQuantity(kpis.productionTodaySqFt, 'sq. ft'),
        subtitle: kpis.productionTodaySqFt > 0
            ? 'Own ${Formatters.stockQuantity(kpis.ownProductionTodaySqFt, 'sq. ft')} · JW ${Formatters.stockQuantity(kpis.jobWorkOutputTodaySqFt, 'sq. ft')}'
            : AppStrings.productionTodaySubtitle,
        icon: Icons.precision_manufacturing_outlined,
        color: AppColors.primary,
        onTap: () => context.push(RoutePaths.production),
      ),
      _KpiItem(
        label: AppStrings.activeJobWork,
        value: '${kpis.activeJobWorkCount}',
        icon: Icons.content_cut,
        color: AppColors.primary,
        onTap: () => context.go(
          RoutePaths.jobWorkList(filter: JobWorkListStageFilter.inProgress),
        ),
      ),
      _KpiItem(
        label: AppStrings.activeSales,
        value: '${kpis.activeSalesCount}',
        subtitle: AppStrings.activeSalesOrders,
        icon: Icons.shopping_bag_outlined,
        color: AppColors.primary,
        onTap: () => context.go(RoutePaths.salesList(filter: 'inProgress')),
      ),
      _KpiItem(
        label: AppStrings.pendingPickups,
        value: '${kpis.pendingPickupCount}',
        subtitle: AppStrings.awaitingCustomerPickup,
        icon: Icons.inventory_2_outlined,
        color: AppColors.accent,
        onTap: () => context.go(
          RoutePaths.jobWorkList(filter: JobWorkListStageFilter.pendingPickup),
        ),
      ),
      _KpiItem(
        label: AppStrings.overdueTotal,
        value: Formatters.currencyPkr(kpis.overdueAmount),
        subtitle:
            kpis.overdueCount > 0 ? '${kpis.overdueCount} invoice(s)' : null,
        icon: Icons.warning_amber_rounded,
        color: AppColors.overdue,
        onTap: () => context.push(
          RoutePaths.notificationsWithFilter(NotificationFilter.overdue),
        ),
      ),
      _KpiItem(
        label: AppStrings.factoryExpenses,
        value: Formatters.currencyPkr(kpis.expensesThisMonth),
        subtitle: kpis.expenseCountThisMonth > 0
            ? '${kpis.expenseCountThisMonth} ${AppStrings.expenseEntriesThisMonth}'
            : AppStrings.expensesThisMonth,
        icon: Icons.receipt_long_outlined,
        color: AppColors.warning,
        onTap: () => context.push(RoutePaths.expenses),
      ),
      _KpiItem(
        label: AppStrings.lowStockMaterials,
        value: '${kpis.lowStockCount}',
        subtitle: kpis.lowStockCount > 0
            ? AppStrings.lowStock
            : AppStrings.rawMaterialStock,
        icon: Icons.inventory_2_outlined,
        color: kpis.lowStockCount > 0 ? AppColors.warning : AppColors.accent,
        onTap: () => context.push(
          RoutePaths.rawMaterialsList(filter: RawMaterialListFilter.lowStock),
        ),
      ),
      _KpiItem(
        label: AppStrings.pendingDeliveries,
        value: '${kpis.activeDeliveriesCount}',
        subtitle: kpis.scheduledDeliveriesToday > 0
            ? '${kpis.scheduledDeliveriesToday} ${AppStrings.scheduledDeliveriesToday}'
            : null,
        icon: Icons.local_shipping_outlined,
        color: AppColors.primary,
        onTap: () => context.go(
          RoutePaths.deliveriesList(filter: DeliveryListFilter.active),
        ),
      ),
      if (kpis.maintenanceOverdueCount > 0 ||
          kpis.maintenanceDueSoonCount > 0)
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
          onTap: () => context.go(
            RoutePaths.equipmentList(
              filter: EquipmentListFilter.maintenanceDue,
            ),
          ),
        ),
      if (kpis.jobWorkPendingQcCount > 0 || kpis.qcRejectsThisMonth > 0)
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
          onTap: () {
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
        ),
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
        onTap: () => context.push(RoutePaths.attendance),
      ),
      _KpiItem(
        label: AppStrings.customerCount,
        value: '${kpis.customerCount}',
        icon: Icons.people_outline,
        color: AppColors.accent,
        onTap: () => context.go(RoutePaths.customers),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: items
          .map(
            (item) => Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(item.icon, color: item.color, size: 22),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.value,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          if (item.subtitle != null)
                            Text(
                              item.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: item.color),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _KpiItem {
  const _KpiItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
