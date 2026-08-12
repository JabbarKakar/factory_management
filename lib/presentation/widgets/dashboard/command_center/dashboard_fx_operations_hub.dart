import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/dashboard_analytics.dart';
import '../../../../domain/entities/dashboard_command_center.dart';
import '../../../../domain/entities/dashboard_kpis.dart';
import '../../../../domain/entities/dashboard_pending_pickup.dart';
import '../../../../domain/enums/app_module_enums.dart';
import '../../../../domain/enums/job_work_enums.dart';
import '../../../../domain/enums/notification_enums.dart';
import '../../../../domain/extensions/app_user_permissions.dart';
import '../../../routes/route_paths.dart';
import '../../payment_reminders_card.dart';
import '../../pending_pickups_card.dart';
import 'dashboard_fx_card.dart';
import 'dashboard_fx_style.dart';
import 'dashboard_fx_theme.dart';

/// Restores previous dashboard operational modules in Command Center styling.
class DashboardFxOperationsHub extends StatelessWidget {
  const DashboardFxOperationsHub({
    required this.commandCenter,
    required this.kpis,
    required this.analytics,
    required this.pendingPickups,
    required this.user,
    super.key,
  });

  final DashboardCommandCenter commandCenter;
  final DashboardKpis kpis;
  final DashboardAnalytics analytics;
  final List<DashboardPendingPickup> pendingPickups;
  final AppUser? user;

  bool _can(AppModule module) => user?.canView(module) ?? false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DashboardFxSectionLabel(
          title: 'Operations Hub',
          subtitle: 'Alerts, stock sold, production and module overview',
          icon: Icons.dashboard_customize_outlined,
        ),
        _OpsAlertStrip(kpis: kpis, user: user),
        if (user != null &&
            (_can(AppModule.sales) || _can(AppModule.jobWork))) ...[
          const SizedBox(height: DashboardFxStyle.spaceMd),
          DashboardFxCard(
            expandChild: false,
            title: 'Payment Reminders',
            subtitle: 'Due this week and overdue invoices',
            glowColor: DashboardFx.danger(context),
            child: PaymentRemindersCard(factoryId: user!.factoryId),
          ),
        ],
        if (_can(AppModule.jobWork) &&
            (pendingPickups.isNotEmpty || kpis.pendingPickupCount > 0)) ...[
          const SizedBox(height: DashboardFxStyle.spaceMd),
          PendingPickupsCard(
            pendingPickups: pendingPickups,
            totalCount: kpis.pendingPickupCount,
          ),
        ],
        const SizedBox(height: DashboardFxStyle.spaceMd),
        _ModuleOverviewGrid(kpis: kpis, user: user),
      ],
    );
  }
}

class _OpsAlertStrip extends StatelessWidget {
  const _OpsAlertStrip({required this.kpis, required this.user});

  final DashboardKpis kpis;
  final AppUser? user;

  bool _can(AppModule module) => user?.canView(module) ?? false;

  @override
  Widget build(BuildContext context) {
    final cards = <_AlertData>[
      if (_can(AppModule.sales) || _can(AppModule.jobWork))
        _AlertData(
          label: AppStrings.dueThisWeek,
          value: Formatters.currencyCompact(kpis.dueThisWeekAmount),
          caption: kpis.dueThisWeekCount > 0
              ? '${kpis.dueThisWeekCount} invoice(s)'
              : AppStrings.noDuesThisWeek,
          color: DashboardFx.primary(context),
          icon: Icons.event_available_outlined,
          alert: kpis.dueThisWeekAmount > 0,
          onTap: () => context.push(
            RoutePaths.notificationsWithFilter(NotificationFilter.dueThisWeek),
          ),
        ),
      if (_can(AppModule.sales) || _can(AppModule.jobWork))
        _AlertData(
          label: AppStrings.overduePayments,
          value: Formatters.currencyCompact(kpis.overdueAmount),
          caption: kpis.overdueCount > 0
              ? '${kpis.overdueCount} overdue'
              : 'All clear',
          color: DashboardFx.danger(context),
          icon: Icons.warning_amber_rounded,
          alert: kpis.overdueAmount > 0,
          onTap: () => context.push(
            RoutePaths.notificationsWithFilter(NotificationFilter.overdue),
          ),
        ),
      if (_can(AppModule.jobWork))
        _AlertData(
          label: AppStrings.pendingPickups,
          value: '${kpis.pendingPickupCount}',
          caption: kpis.stalePickupCount > 0
              ? '${kpis.stalePickupCount} overdue'
              : AppStrings.awaitingCustomerPickup,
          color: kpis.stalePickupCount > 0
              ? DashboardFx.danger(context)
              : DashboardFx.electric(context),
          icon: Icons.inventory_2_outlined,
          alert: kpis.stalePickupCount > 0,
          onTap: () => context.go(
            RoutePaths.jobWorkList(
              filter: JobWorkListStageFilter.pendingPickup,
            ),
          ),
        ),
      if (_can(AppModule.delivery))
        _AlertData(
          label: AppStrings.overdueDeliveries,
          value: '${kpis.overdueDeliveriesCount}',
          caption: AppStrings.overdueDeliveriesSubtitle,
          color: DashboardFx.danger(context),
          icon: Icons.local_shipping_outlined,
          alert: kpis.overdueDeliveriesCount > 0,
          onTap: () => context.push(RoutePaths.deliveries),
        ),
    ];

    if (cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        if (wide) {
          return SizedBox(
            height: 92,
            child: Row(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _AlertTile(data: cards[i])),
                ],
              ],
            ),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 92,
          ),
          itemBuilder: (context, i) => _AlertTile(data: cards[i]),
        );
      },
    );
  }
}

class _AlertData {
  const _AlertData({
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    required this.icon,
    required this.alert,
    this.onTap,
  });

  final String label;
  final String value;
  final String caption;
  final Color color;
  final IconData icon;
  final bool alert;
  final VoidCallback? onTap;
}

class _AlertTile extends StatefulWidget {
  const _AlertTile({required this.data});

  final _AlertData data;

  @override
  State<_AlertTile> createState() => _AlertTileState();
}

class _AlertTileState extends State<_AlertTile>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;
  Animation<double>? _opacity;

  @override
  void initState() {
    super.initState();
    if (widget.data.alert) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
      _opacity = Tween<double>(begin: 0.25, end: 0.6).animate(
        CurvedAnimation(parent: _pulse!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    if (_opacity != null) {
      return AnimatedBuilder(
        animation: _opacity!,
        builder: (context, child) => _buildTile(context, data, _opacity!.value),
      );
    }
    return _buildTile(context, data, 0);
  }

  Widget _buildTile(BuildContext context, _AlertData data, double borderAlpha) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: DashboardFx.cardBg(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: data.alert
                  ? data.color.withValues(alpha: borderAlpha)
                  : DashboardFx.cardBorder(context),
            ),
            boxShadow: [
              BoxShadow(
                color: data.color.withValues(
                  alpha: data.alert ? 0.12 : 0.04,
                ),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(data.icon, size: 16, color: data.color),
                    const Spacer(),
                    if (data.alert)
                      Icon(
                        Icons.priority_high_rounded,
                        size: 14,
                        color: data.color,
                      ),
                  ],
                ),
                const Spacer(),
                Text(data.label, style: DashboardFxStyle.label(context)),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardFxStyle.value(context).copyWith(
                    color: data.color,
                    fontSize: 16,
                  ),
                ),
                Text(
                  data.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardFxStyle.caption(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductionMiniCard extends StatelessWidget {
  const ProductionMiniCard({
    required this.points,
    required this.monthlyOwn,
    super.key,
  });

  final List<DailyProductionPoint> points;
  final double monthlyOwn;

  @override
  Widget build(BuildContext context) {
    final hasData = points.any((p) => p.totalSqFt > 0);
    final maxY = points
        .map((p) => p.totalSqFt)
        .fold<double>(0, (m, v) => v > m ? v : m);
    final chartMax = maxY <= 0 ? 1.0 : maxY * 1.2;
    final successColor = DashboardFx.success(context);

    return DashboardFxCard(
      title: AppStrings.productionChartTitle,
      subtitle: AppStrings.productionChartSubtitle,
      glowColor: successColor,
      expandChild: false,
      trailing: Text(
        Formatters.stockQuantity(monthlyOwn, 'sq. ft'),
        style: DashboardFxStyle.caption(context).copyWith(color: successColor),
      ),
      child: SizedBox(
        height: 140,
        child: !hasData
            ? Center(
                child: Text(
                  AppStrings.productionChartEmpty,
                  textAlign: TextAlign.center,
                  style: DashboardFxStyle.subtitle(context),
                ),
              )
            : ClipRect(
                child: BarChart(
                BarChartData(
                  maxY: chartMax,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: chartMax / 3,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: DashboardFx.cardBorder(context),
                      strokeWidth: 1,
                      dashArray: const [3, 3],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat.E().format(points[i].date),
                              style: DashboardFxStyle.caption(context),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < points.length; i++)
                      BarChartGroupData(
                        x: i,
                        barsSpace: 2,
                        barRods: [
                          BarChartRodData(
                            toY: points[i].ownProductionSqFt,
                            width: 7,
                            color: DashboardFx.electric(context),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                          BarChartRodData(
                            toY: points[i].jobWorkSqFt,
                            width: 7,
                            color: DashboardFx.primary(context),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

class _ModuleOverviewGrid extends StatelessWidget {
  const _ModuleOverviewGrid({required this.kpis, required this.user});

  final DashboardKpis kpis;
  final AppUser? user;

  bool _can(AppModule module) => user?.canView(module) ?? false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = DashboardFx.primary(context);
    final electricColor = DashboardFx.electric(context);
    final successColor = DashboardFx.success(context);
    final dangerColor = DashboardFx.danger(context);

    final items = <_OverviewItem>[
      if (_can(AppModule.jobWork))
        _OverviewItem(
          label: AppStrings.activeLoads,
          value: '${kpis.activeLoadCount}',
          caption: '${kpis.activeJobWorkCount} containers',
          icon: Icons.content_cut_rounded,
          color: primaryColor,
          onTap: () => context.go(
            RoutePaths.jobWorkList(filter: JobWorkListStageFilter.active),
          ),
        ),
      if (_can(AppModule.sales))
        _OverviewItem(
          label: AppStrings.activeSales,
          value: '${kpis.activeSalesCount}',
          caption: AppStrings.activeSalesOrders,
          icon: Icons.shopping_bag_outlined,
          color: electricColor,
          onTap: () => context.go(RoutePaths.salesList(filter: 'active')),
        ),
      if (_can(AppModule.customers))
        _OverviewItem(
          label: AppStrings.customerCount,
          value: '${kpis.customerCount}',
          caption: 'Registered',
          icon: Icons.people_outline_rounded,
          color: successColor,
          onTap: () => context.push(RoutePaths.customers),
        ),
      if (_can(AppModule.labour))
        _OverviewItem(
          label: 'Labour Today',
          value: '${kpis.presentLabourToday}/${kpis.activeLabourCount}',
          caption: kpis.unmarkedAttendanceToday > 0
              ? '${kpis.unmarkedAttendanceToday} unmarked'
              : 'Attendance',
          icon: Icons.badge_outlined,
          color: primaryColor,
          onTap: () => context.push(RoutePaths.attendance),
        ),
      if (_can(AppModule.rawMaterials) && kpis.lowStockCount > 0)
        _OverviewItem(
          label: 'Low Stock',
          value: '${kpis.lowStockCount}',
          caption: 'Materials',
          icon: Icons.inventory_outlined,
          color: dangerColor,
          onTap: () => context.push(RoutePaths.rawMaterials),
        ),
      if (_can(AppModule.qualityControl) && kpis.jobWorkPendingQcCount > 0)
        _OverviewItem(
          label: 'Pending QC',
          value: '${kpis.jobWorkPendingQcCount}',
          caption: 'Job work loads',
          icon: Icons.fact_check_outlined,
          color: primaryColor,
          onTap: () => context.push(RoutePaths.qualityChecks),
        ),
      if (_can(AppModule.expenses))
        _OverviewItem(
          label: 'Expenses MTD',
          value: Formatters.currencyCompact(kpis.expensesThisMonth),
          caption: '${kpis.expenseCountThisMonth} entries',
          icon: Icons.receipt_long_outlined,
          color: dangerColor,
          onTap: () => context.push(RoutePaths.expenses),
        ),
      if (_can(AppModule.delivery))
        _OverviewItem(
          label: 'Active Deliveries',
          value: '${kpis.activeDeliveriesCount}',
          caption: '${kpis.scheduledDeliveriesToday} today',
          icon: Icons.local_shipping_outlined,
          color: electricColor,
          onTap: () => context.push(RoutePaths.deliveries),
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardFxSectionLabel(
          title: 'Module Overview',
          subtitle: 'Quick links across factory modules',
          icon: Icons.apps_rounded,
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 1100
                ? 4
                : constraints.maxWidth >= 700
                    ? 3
                    : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: 88,
              ),
              itemBuilder: (context, i) => _OverviewTile(item: items[i]),
            );
          },
        ),
      ],
    );
  }
}

class _OverviewItem {
  const _OverviewItem({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({required this.item});

  final _OverviewItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: DashboardFx.cardBg(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DashboardFx.cardBorder(context)),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, size: 17, color: item.color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DashboardFxStyle.label(context),
                            ),
                            Text(
                              item.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DashboardFxStyle.value(context)
                                  .copyWith(fontSize: 15),
                            ),
                            Text(
                              item.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DashboardFxStyle.caption(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.8),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
