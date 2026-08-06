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
        const SizedBox(height: DashboardFxStyle.spaceMd),
        SizedBox(
          height: 220,
          child: _ProductionMiniCard(
            points: analytics.productionLast7Days,
            monthlyOwn: kpis.productionThisMonthSqFt,
          ),
        ),
        if (user != null &&
            (_can(AppModule.sales) || _can(AppModule.jobWork))) ...[
          const SizedBox(height: DashboardFxStyle.spaceMd),
          DashboardFxCard(
            expandChild: false,
            title: 'Payment Reminders',
            subtitle: 'Due this week and overdue invoices',
            glowColor: DashboardFx.danger,
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
          color: DashboardFx.primary,
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
          color: DashboardFx.danger,
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
              ? DashboardFx.danger
              : DashboardFx.electric,
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
          color: DashboardFx.danger,
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
        builder: (context, child) => _buildTile(data, _opacity!.value),
      );
    }
    return _buildTile(data, 0);
  }

  Widget _buildTile(_AlertData data, double borderAlpha) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: DashboardFx.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: data.alert
                  ? data.color.withValues(alpha: borderAlpha)
                  : DashboardFx.cardBorder,
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
                Text(data.label, style: DashboardFxStyle.label),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardFxStyle.value.copyWith(
                    color: data.color,
                    fontSize: 16,
                  ),
                ),
                Text(
                  data.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardFxStyle.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StockSalesDetailCard extends StatefulWidget {
  const _StockSalesDetailCard({required this.commandCenter});

  final DashboardCommandCenter commandCenter;

  @override
  State<_StockSalesDetailCard> createState() => _StockSalesDetailCardState();
}

class _StockSalesDetailCardState extends State<_StockSalesDetailCard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final cc = widget.commandCenter;
    final isCut = _tab == 0;
    final smallSq = isCut ? cc.smallStockSqFt : cc.salesSmallSqFt;
    final largeSq = isCut ? cc.largeStockSqFt : cc.salesLargeSqFt;
    final wasteSq = isCut ? cc.wasteYieldSqFt : 0.0;
    final totalSq = smallSq + largeSq + wasteSq;

    final smallAmt = isCut ? cc.smallStockAmount : cc.salesSmallAmount;
    final largeAmt = isCut ? cc.largeStockAmount : cc.salesLargeAmount;
    final totalAmt = isCut ? cc.stockCutTotalAmount : cc.salesTotalAmount;

    final wasteLossPct = totalSq > 0 ? (wasteSq / totalSq) * 100 : 0.0;

    return DashboardFxCard(
      title: isCut ? 'Stock Cut Detail' : 'Sales Sq. Ft Detail',
      subtitle: isCut
          ? 'Production cut for ${cc.period.label}'
          : 'Sold square feet for ${cc.period.label}',
      glowColor: isCut ? DashboardFx.primary : DashboardFx.electric,
      trailing: _SegTabs(
        labels: const ['Cut', 'Sold'],
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
      child: totalSq <= 0
          ? Center(
              child: Text(
                isCut
                    ? 'No stock cut in this period'
                    : 'No sales sq. ft in this period',
                style: DashboardFxStyle.subtitle,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 36,
                                sections: [
                                  PieChartSectionData(
                                    value: largeSq <= 0 ? 0.001 : largeSq,
                                    color: DashboardFx.primary,
                                    radius: 14,
                                    showTitle: false,
                                  ),
                                  PieChartSectionData(
                                    value: smallSq <= 0 ? 0.001 : smallSq,
                                    color: DashboardFx.electric,
                                    radius: 14,
                                    showTitle: false,
                                  ),
                                  if (isCut)
                                    PieChartSectionData(
                                      value: wasteSq <= 0 ? 0.001 : wasteSq,
                                      color: DashboardFx.danger,
                                      radius: 14,
                                      showTitle: false,
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _sqft(totalSq),
                                  style: DashboardFxStyle.value
                                      .copyWith(fontSize: 12),
                                ),
                                Text(
                                  isCut ? 'Cut' : 'Sold',
                                  style: DashboardFxStyle.caption,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _RowMetric(
                            color: DashboardFx.primary,
                            label: 'Large',
                            value: _sqft(largeSq),
                            amountText: Formatters.currencyCompact(largeAmt),
                          ),
                          const SizedBox(height: 6),
                          _RowMetric(
                            color: DashboardFx.electric,
                            label: 'Small',
                            value: _sqft(smallSq),
                            amountText: Formatters.currencyCompact(smallAmt),
                          ),
                          if (isCut) ...[
                            const SizedBox(height: 6),
                            _RowMetric(
                              color: DashboardFx.danger,
                              label: 'Waste/Yield',
                              value: _sqft(wasteSq),
                              badgeText: wasteSq > 0
                                  ? '${wasteLossPct.toStringAsFixed(1)}% loss'
                                  : '0% loss',
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: DashboardFx.elevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DashboardFx.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Total ${isCut ? "Cut" : "Sold"}: ',
                        style: const TextStyle(
                          color: DashboardFx.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _sqft(isCut ? (smallSq + largeSq) : totalSq),
                        style: const TextStyle(
                          color: DashboardFx.text,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Formatters.currencyCompact(totalAmt),
                        style: const TextStyle(
                          color: DashboardFx.primary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProductionMiniCard extends StatelessWidget {
  const _ProductionMiniCard({
    required this.points,
    required this.monthlyOwn,
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

    return DashboardFxCard(
      title: AppStrings.productionChartTitle,
      subtitle: AppStrings.productionChartSubtitle,
      glowColor: DashboardFx.success,
      trailing: Text(
        Formatters.stockQuantity(monthlyOwn, 'sq. ft'),
        style: DashboardFxStyle.caption.copyWith(color: DashboardFx.success),
      ),
      child: !hasData
          ? const Center(
              child: Text(
                AppStrings.productionChartEmpty,
                textAlign: TextAlign.center,
                style: DashboardFxStyle.subtitle,
              ),
            )
          : BarChart(
              BarChartData(
                maxY: chartMax,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMax / 3,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: DashboardFx.cardBorder,
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
                            style: DashboardFxStyle.caption,
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
                          color: DashboardFx.electric,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                        BarChartRodData(
                          toY: points[i].jobWorkSqFt,
                          width: 7,
                          color: DashboardFx.primary,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                      ],
                    ),
                ],
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
    final items = <_OverviewItem>[
      if (_can(AppModule.jobWork))
        _OverviewItem(
          label: AppStrings.activeLoads,
          value: '${kpis.activeLoadCount}',
          caption: '${kpis.activeJobWorkCount} containers',
          icon: Icons.content_cut_rounded,
          color: DashboardFx.primary,
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
          color: DashboardFx.electric,
          onTap: () => context.go(RoutePaths.salesList(filter: 'active')),
        ),
      if (_can(AppModule.customers))
        _OverviewItem(
          label: AppStrings.customerCount,
          value: '${kpis.customerCount}',
          caption: 'Registered',
          icon: Icons.people_outline_rounded,
          color: DashboardFx.success,
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
          color: DashboardFx.primary,
          onTap: () => context.push(RoutePaths.attendance),
        ),
      if (_can(AppModule.rawMaterials) && kpis.lowStockCount > 0)
        _OverviewItem(
          label: 'Low Stock',
          value: '${kpis.lowStockCount}',
          caption: 'Materials',
          icon: Icons.inventory_outlined,
          color: DashboardFx.danger,
          onTap: () => context.push(RoutePaths.rawMaterials),
        ),
      if (_can(AppModule.qualityControl) && kpis.jobWorkPendingQcCount > 0)
        _OverviewItem(
          label: 'Pending QC',
          value: '${kpis.jobWorkPendingQcCount}',
          caption: 'Job work loads',
          icon: Icons.fact_check_outlined,
          color: DashboardFx.primary,
          onTap: () => context.push(RoutePaths.qualityChecks),
        ),
      if (_can(AppModule.expenses))
        _OverviewItem(
          label: 'Expenses MTD',
          value: Formatters.currencyCompact(kpis.expensesThisMonth),
          caption: '${kpis.expenseCountThisMonth} entries',
          icon: Icons.receipt_long_outlined,
          color: DashboardFx.danger,
          onTap: () => context.push(RoutePaths.expenses),
        ),
      if (_can(AppModule.delivery))
        _OverviewItem(
          label: 'Active Deliveries',
          value: '${kpis.activeDeliveriesCount}',
          caption: '${kpis.scheduledDeliveriesToday} today',
          icon: Icons.local_shipping_outlined,
          color: DashboardFx.electric,
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
              color: DashboardFx.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DashboardFx.cardBorder),
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
                              style: DashboardFxStyle.label,
                            ),
                            Text(
                              item.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DashboardFxStyle.value.copyWith(fontSize: 15),
                            ),
                            Text(
                              item.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DashboardFxStyle.caption,
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

class _SegTabs extends StatelessWidget {
  const _SegTabs({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: DashboardFx.elevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardFx.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: i == index
                      ? DashboardFx.primary.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: i == index
                        ? DashboardFx.primary
                        : DashboardFx.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RowMetric extends StatelessWidget {
  const _RowMetric({
    required this.color,
    required this.label,
    required this.value,
    this.amountText,
    this.badgeText,
  });

  final Color color;
  final String label;
  final String value;
  final String? amountText;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(label, style: DashboardFxStyle.caption),
            const SizedBox(width: 5),
            Text(
              value,
              style: const TextStyle(
                color: DashboardFx.text,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
        if (amountText != null || badgeText != null) ...[
          const SizedBox(height: 1),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              amountText ?? badgeText!,
              style: TextStyle(
                color: amountText != null ? color : DashboardFx.danger,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

String _sqft(double value) {
  if (value.abs() >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value.abs() >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toStringAsFixed(0);
}
