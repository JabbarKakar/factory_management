import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../blocs/dashboard/dashboard_bloc.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/dashboard_analytics.dart';
import '../../../../domain/entities/dashboard_command_center.dart';
import '../../../../domain/entities/dashboard_kpis.dart';
import '../../../../domain/enums/app_module_enums.dart';
import '../../../../domain/enums/dashboard_finance_period.dart';
import '../../../../domain/extensions/app_user_permissions.dart';
import '../../../routes/route_paths.dart';
import 'dashboard_fx_card.dart';
import 'dashboard_fx_operations_hub.dart';
import 'dashboard_fx_style.dart';
import 'dashboard_fx_theme.dart';



/// Compact futuristic executive control center body.
class DashboardCommandCenterView extends StatefulWidget {
  const DashboardCommandCenterView({
    required this.state,
    required this.user,
    super.key,
  });

  final DashboardState state;
  final AppUser? user;

  @override
  State<DashboardCommandCenterView> createState() =>
      _DashboardCommandCenterViewState();
}

class _DashboardCommandCenterViewState
    extends State<DashboardCommandCenterView>
    with SingleTickerProviderStateMixin {
  static const _chartPeriods = [
    DashboardFinancePeriod.daily,
    DashboardFinancePeriod.weekly,
    DashboardFinancePeriod.monthly,
    DashboardFinancePeriod.sixMonths,
    DashboardFinancePeriod.yearly,
    DashboardFinancePeriod.allTime,
  ];

  late final AnimationController _entrance;

  // Staggered intervals for each section.
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _todayFade;
  late final Animation<Offset> _todaySlide;
  late final Animation<double> _kpiFade;
  late final Animation<Offset> _kpiSlide;
  late final Animation<double> _chartsFade;
  late final Animation<Offset> _chartsSlide;
  late final Animation<double> _dockFade;
  late final Animation<Offset> _dockSlide;
  late final Animation<double> _opsFade;
  late final Animation<Offset> _opsSlide;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    const slideUp = Offset(0, 0.08);
    const slideZero = Offset.zero;
    final curve = CurveTween(curve: Curves.easeOutCubic);

    Animation<double> fade(double begin, double end) =>
        Tween<double>(begin: 0, end: 1)
            .animate(CurvedAnimation(parent: _entrance, curve: Interval(begin, end)));
    Animation<Offset> slide(double begin, double end) =>
        Tween<Offset>(begin: slideUp, end: slideZero)
            .chain(curve)
            .animate(CurvedAnimation(parent: _entrance, curve: Interval(begin, end)));

    _headerFade = fade(0.0, 0.35);
    _headerSlide = slide(0.0, 0.35);
    _todayFade = fade(0.08, 0.42);
    _todaySlide = slide(0.08, 0.42);
    _kpiFade = fade(0.15, 0.50);
    _kpiSlide = slide(0.15, 0.50);
    _chartsFade = fade(0.25, 0.60);
    _chartsSlide = slide(0.25, 0.60);
    _dockFade = fade(0.35, 0.70);
    _dockSlide = slide(0.35, 0.70);
    _opsFade = fade(0.45, 0.80);
    _opsSlide = slide(0.45, 0.80);

    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final cc = widget.state.commandCenter;
    final kpis = widget.state.kpis;
    final firstName = widget.user?.name.split(' ').first;
    final greeting = firstName == null || firstName.isEmpty
        ? _greeting()
        : '${_greeting()}, $firstName';

    return LayoutBuilder(
      builder: (context, constraints) {
        final medium = constraints.maxWidth >= 760;
        final chartHeight = medium ? 440.0 : 900.0;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
          children: [
            // — Header —
            SlideTransition(
              position: _headerSlide,
              child: FadeTransition(
                opacity: _headerFade,
                child: _HeaderBar(
                  greeting: greeting,
                  period: widget.state.financePeriod,
                  periods: _chartPeriods,
                  commandCenter: cc,
                  onPeriodChanged: (p) => context
                      .read<DashboardBloc>()
                      .add(DashboardGlobalPeriodChanged(p)),
                ),
              ),
            ),
            const SizedBox(height: DashboardFxStyle.spaceMd),

            // — Today at a Glance —
            SlideTransition(
              position: _todaySlide,
              child: FadeTransition(
                opacity: _todayFade,
                child: _TodayAtAGlance(kpis: kpis),
              ),
            ),
            const SizedBox(height: DashboardFxStyle.spaceMd),

            // — KPI Row —
            SlideTransition(
              position: _kpiSlide,
              child: FadeTransition(
                opacity: _kpiFade,
                child: _KpiRow(
                  commandCenter: cc,
                  wrap: !medium,
                ),
              ),
            ),
            const SizedBox(height: DashboardFxStyle.spaceMd),

            // — Charts —
            SlideTransition(
              position: _chartsSlide,
              child: FadeTransition(
                opacity: _chartsFade,
                child: SizedBox(
                  height: chartHeight,
                  child: _ChartsGrid(
                    commandCenter: cc,
                    medium: medium,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DashboardFxStyle.spaceMd),

            // — Bottom Dock —
            SlideTransition(
              position: _dockSlide,
              child: FadeTransition(
                opacity: _dockFade,
                child: SizedBox(
                  height: 156,
                  child: _BottomDock(
                    activity: widget.state.analytics.recentActivity,
                    user: widget.user,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DashboardFxStyle.spaceLg),

            // — Operations Hub —
            SlideTransition(
              position: _opsSlide,
              child: FadeTransition(
                opacity: _opsFade,
                child: DashboardFxOperationsHub(
                  commandCenter: cc,
                  kpis: kpis,
                  analytics: widget.state.analytics,
                  pendingPickups: widget.state.pendingPickups,
                  user: widget.user,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.greeting,
    required this.period,
    required this.periods,
    required this.commandCenter,
    required this.onPeriodChanged,
  });

  final String greeting;
  final DashboardFinancePeriod period;
  final List<DashboardFinancePeriod> periods;
  final DashboardCommandCenter commandCenter;
  final ValueChanged<DashboardFinancePeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, d MMM').format(DateTime.now());

    return DashboardFxCard(
      expandChild: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      glowColor: DashboardFx.primary,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DashboardFx.primary.withValues(alpha: 0.28),
                      DashboardFx.electric.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DashboardFx.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  size: 19,
                  color: DashboardFx.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: DashboardFxStyle.title.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const _LivePulseDot(),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '$dateLabel · Live operational & financial analytics',
                            style: DashboardFxStyle.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _PeriodMenu(
                period: period,
                periods: periods,
                onChanged: onPeriodChanged,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusPill(
                  label: '${commandCenter.activeJobWorks} Active JW',
                  color: DashboardFx.electric,
                ),
                const SizedBox(width: 6),
                _StatusPill(
                  label: '${commandCenter.activeDispatches} Dispatches',
                  color: DashboardFx.primary,
                ),
                const SizedBox(width: 6),
                _StatusPill(
                  label:
                      '${_compactSqFt(commandCenter.throughputSqFt)} throughput today',
                  color: DashboardFx.success,
                ),
                const SizedBox(width: 6),
                _StatusPill(
                  label:
                      '${_compactSqFt(commandCenter.salesTotalSqFt)} sold · ${period.label}',
                  color: DashboardFx.violet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodMenu extends StatelessWidget {
  const _PeriodMenu({
    required this.period,
    required this.periods,
    required this.onChanged,
  });

  final DashboardFinancePeriod period;
  final List<DashboardFinancePeriod> periods;
  final ValueChanged<DashboardFinancePeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DashboardFinancePeriod>(
      initialValue: period,
      onSelected: onChanged,
      offset: const Offset(0, 36),
      color: DashboardFx.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: DashboardFx.primary.withValues(alpha: 0.25)),
      ),
      itemBuilder: (context) => [
        for (final option in periods)
          PopupMenuItem(
            value: option,
            child: Text(
              option.label,
              style: TextStyle(
                fontWeight:
                    option == period ? FontWeight.w800 : FontWeight.w600,
                color: option == period ? DashboardFx.primary : DashboardFx.text,
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: DashboardFx.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: DashboardFx.primary.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              period.label,
              style: const TextStyle(
                color: DashboardFx.primary,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: DashboardFx.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatefulWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: widget.color.withValues(alpha: 0.35)),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.color,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.commandCenter,
    this.wrap = false,
  });

  final DashboardCommandCenter commandCenter;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCard(
        label: 'Income Collected',
        value: Formatters.currencyCompact(commandCenter.income),
        change: commandCenter.incomeChangePercent,
        accent: DashboardFx.success,
        sparkline: commandCenter.incomeSparkline,
        area: true,
      ),
      _KpiCard(
        label: 'Op. Expenses',
        value: Formatters.currencyCompact(commandCenter.expenses),
        change: commandCenter.expensesChangePercent,
        accent: DashboardFx.danger,
        sparkline: commandCenter.expenseSparkline,
        area: false,
        caption: commandCenter.expenseRatioPercent == null
            ? null
            : '${commandCenter.expenseRatioPercent!.toStringAsFixed(0)}% of income',
      ),
      _KpiCard(
        label: 'Net Margin',
        value: Formatters.currencyCompact(commandCenter.net),
        change: null,
        accent: commandCenter.net >= 0
            ? DashboardFx.success
            : DashboardFx.danger,
        sparkline: commandCenter.cashflowSeries.map((e) => e.net).toList(),
        area: true,
        caption: commandCenter.net >= 0 ? 'Profit' : 'Loss',
      ),
      _KpiCard(
        label: 'Receivables',
        value: Formatters.currencyCompact(commandCenter.outstanding),
        change: null,
        accent: DashboardFx.primary,
        sparkline: const [],
        area: true,
        caption: commandCenter.outstandingCount > 0
            ? '${commandCenter.outstandingCount} open'
            : 'Clear',
        badge: commandCenter.outstanding > 0 ? 'URGENT' : null,
      ),
    ];

    if (wrap) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.55,
        children: cards,
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}

class _KpiCard extends StatefulWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.sparkline,
    required this.area,
    this.change,
    this.caption,
    this.badge,
  });

  final String label;
  final String value;
  final Color accent;
  final List<double> sparkline;
  final bool area;
  final double? change;
  final String? caption;
  final String? badge;

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _counter;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _counter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progress = CurvedAnimation(parent: _counter, curve: Curves.easeOutCubic);
    _counter.forward();
  }

  @override
  void dispose() {
    _counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final changeText = widget.change == null
        ? null
        : '${widget.change! >= 0 ? '+' : ''}${widget.change!.toStringAsFixed(1)}%';

    return DashboardFxCard(
      expandChild: false,
      glowColor: widget.accent,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DashboardFx.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                ),
              ),
              if (widget.badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DashboardFx.danger.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.badge!,
                    style: const TextStyle(
                      color: DashboardFx.danger,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _progress,
            builder: (context, _) {
              return _AnimatedValueText(
                fullValue: widget.value,
                progress: _progress.value,
                accent: widget.accent,
              );
            },
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (changeText != null)
                Text(
                  changeText,
                  style: TextStyle(
                    color: (widget.change ?? 0) >= 0
                        ? DashboardFx.success
                        : DashboardFx.danger,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                )
              else if (widget.caption != null)
                Text(
                  widget.caption!,
                  style: const TextStyle(
                    color: DashboardFx.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              const Spacer(),
              if (widget.sparkline.length >= 2)
                SizedBox(
                  width: 56,
                  height: 22,
                  child: _MiniSparkline(
                    values: widget.sparkline,
                    color: widget.accent,
                    area: widget.area,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  const _MiniSparkline({
    required this.values,
    required this.color,
    required this.area,
  });

  final List<double> values;
  final Color color;
  final bool area;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    double minY = values.fold<double>(values.first, (m, v) => v < m ? v : m);
    double maxY = values.fold<double>(values.first, (m, v) => v > m ? v : m);

    if (minY == maxY) {
      if (minY == 0) {
        minY = -1;
        maxY = 1;
      } else if (minY > 0) {
        minY = 0;
        maxY = maxY * 1.2;
      } else {
        minY = minY * 1.2;
        maxY = 0;
      }
    } else {
      final rangePadding = (maxY - minY) * 0.15;
      minY -= rangePadding;
      maxY += rangePadding;
    }

    if (area) {
      final spots = [
        for (var i = 0; i < values.length; i++)
          FlSpot(i.toDouble(), values[i]),
      ];
      return ClipRect(
        child: LineChart(
          LineChartData(
            clipData: const FlClipData.all(),
            minX: 0,
            maxX: (values.length - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: color,
                barWidth: 1.6,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withValues(alpha: 0.22),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRect(
      child: BarChart(
        BarChartData(
          minY: minY < 0 ? minY : 0,
          maxY: maxY <= 0 ? 1 : maxY,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    width: 3,
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ChartsGrid extends StatefulWidget {
  const _ChartsGrid({
    required this.commandCenter,
    required this.medium,
  });

  final DashboardCommandCenter commandCenter;
  final bool medium;

  @override
  State<_ChartsGrid> createState() => _ChartsGridState();
}

class _ChartsGridState extends State<_ChartsGrid> {
  int _panelATab = 0;
  int _panelBTab = 0;

  @override
  Widget build(BuildContext context) {
    final cc = widget.commandCenter;
    final a = DashboardFxCard(
      title: _panelATab == 0
          ? 'Revenue & Cashflow'
          : 'Sales vs Job Work',
      subtitle: _panelATab == 0
          ? 'Income received vs expenses · ${cc.period.label}'
          : 'Comparative revenue · ${cc.period.label}',
      glowColor: DashboardFx.electric,
      trailing: _MiniTabs(
        labels: const ['Cashflow', 'Sales/JW'],
        index: _panelATab,
        onChanged: (i) => setState(() => _panelATab = i),
      ),
      child: _panelATab == 0
          ? _CashflowAreaChart(series: cc.cashflowSeries)
          : _SalesJwBarChart(series: cc.salesVsJobWorkSeries),
    );

    final stockIsCut = _panelBTab == 0;
    final b = DashboardFxCard(
      title: stockIsCut ? 'Stock Cut' : 'Sales Sq. Ft',
      subtitle: stockIsCut
          ? 'Large · Small · Waste & yield'
          : 'Large · Small sold stock',
      glowColor: stockIsCut ? DashboardFx.primary : DashboardFx.violet,
      trailing: _MiniTabs(
        labels: const ['Cut', 'Sold'],
        index: _panelBTab,
        onChanged: (i) => setState(() => _panelBTab = i),
      ),
      child: _StockDonut(
        small: stockIsCut ? cc.smallStockSqFt : cc.salesSmallSqFt,
        large: stockIsCut ? cc.largeStockSqFt : cc.salesLargeSqFt,
        waste: stockIsCut ? cc.wasteYieldSqFt : 0,
        smallAmount: stockIsCut ? cc.smallStockAmount : cc.salesSmallAmount,
        largeAmount: stockIsCut ? cc.largeStockAmount : cc.salesLargeAmount,
        totalAmount: stockIsCut ? cc.stockCutTotalAmount : cc.salesTotalAmount,
        showWaste: stockIsCut,
        centerLabel: stockIsCut ? 'Cut' : 'Sold',
      ),
    );

    final c = DashboardFxCard(
      title: 'Sales vs Job Work',
      subtitle: 'Grouped revenue by period bucket',
      glowColor: DashboardFx.success,
      child: Column(
        children: [
          Expanded(child: _SalesJwBarChart(series: cc.salesVsJobWorkSeries)),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: DashboardFx.electric, label: 'Sales'),
              SizedBox(width: 14),
              _LegendDot(color: DashboardFx.primary, label: 'Job Work'),
            ],
          ),
        ],
      ),
    );

    final d = DashboardFxCard(
      title: 'Collection Efficiency',
      subtitle: 'Paid vs pending receivables',
      glowColor: DashboardFx.primary,
      child: _CollectionGauge(
        ratio: cc.collectionRatio,
        collected: cc.collectedInPeriod,
        pending: cc.outstanding,
      ),
    );

    if (widget.medium) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 3, child: a),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: b),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 3, child: c),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: d),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(child: a),
        const SizedBox(height: 10),
        Expanded(child: b),
        const SizedBox(height: 10),
        Expanded(child: c),
        const SizedBox(height: 10),
        Expanded(child: d),
      ],
    );
  }
}

class _MiniTabs extends StatelessWidget {
  const _MiniTabs({
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
                duration: const Duration(milliseconds: 180),
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

class _CashflowAreaChart extends StatelessWidget {
  const _CashflowAreaChart({required this.series});

  final List<DashboardCashflowPoint> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty ||
        !series.any((p) => p.income > 0 || p.expenses > 0)) {
      return const _EmptyHint('No cashflow in this period');
    }

    final maxY = series
        .map((p) => p.income > p.expenses ? p.income : p.expenses)
        .fold<double>(0, (m, v) => v > m ? v : m);
    final chartMax = maxY <= 0 ? 1.0 : maxY * 1.2;
    final maxX = series.length <= 1 ? 1.0 : (series.length - 1).toDouble();

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: chartMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: chartMax / 4,
          getDrawingHorizontalLine: (v) => FlLine(
            color: DashboardFx.cardBorder,
            strokeWidth: 1,
            dashArray: const [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _compact(value),
                  style: const TextStyle(
                    color: DashboardFx.muted,
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (series.length / 5).clamp(1, 8).toDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= series.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    series[i].label ?? DateFormat.Md().format(series[i].date),
                    style: const TextStyle(
                      color: DashboardFx.muted,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final i = spot.x.round().clamp(0, series.length - 1);
              final point = series[i];
              final isIncome = spot.barIndex == 0;
              final label = isIncome ? 'Income' : 'Expenses';
              final amount = isIncome ? point.income : point.expenses;
              final prev = i > 0
                  ? (isIncome
                      ? series[i - 1].income
                      : series[i - 1].expenses)
                  : null;
              final growth = prev == null || prev == 0
                  ? ''
                  : ' (${(((amount - prev) / prev) * 100).toStringAsFixed(0)}%)';
              return LineTooltipItem(
                '$label\n${Formatters.currencyPkr(amount)}$growth',
                TextStyle(
                  color: isIncome ? DashboardFx.success : DashboardFx.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < series.length; i++)
                FlSpot(i.toDouble(), series[i].income),
            ],
            isCurved: true,
            preventCurveOverShooting: true,
            color: DashboardFx.success,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: DashboardFx.success.withValues(alpha: 0.14),
            ),
          ),
          LineChartBarData(
            spots: [
              for (var i = 0; i < series.length; i++)
                FlSpot(i.toDouble(), series[i].expenses),
            ],
            isCurved: true,
            preventCurveOverShooting: true,
            color: DashboardFx.danger,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: DashboardFx.danger.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesJwBarChart extends StatelessWidget {
  const _SalesJwBarChart({required this.series});

  final List<DashboardRevenueComparePoint> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty || !series.any((p) => p.total > 0)) {
      return const _EmptyHint('No sales / job work revenue in this period');
    }

    final maxY = series
        .map((p) => p.total)
        .fold<double>(0, (m, v) => v > m ? v : m);
    final chartMax = maxY <= 0 ? 1.0 : maxY * 1.2;
    final dense = series.length > 14;

    return ClipRect(
      child: BarChart(
        BarChartData(
          maxY: chartMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: chartMax / 4,
          getDrawingHorizontalLine: (v) => FlLine(
            color: DashboardFx.cardBorder,
            strokeWidth: 1,
            dashArray: const [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _compact(value),
                  style: const TextStyle(
                    color: DashboardFx.muted,
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: dense ? (series.length / 5).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= series.length) {
                  return const SizedBox.shrink();
                }
                if (dense && i % ((series.length / 5).ceil()) != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    series[i].label ?? DateFormat.Md().format(series[i].date),
                    style: const TextStyle(
                      color: DashboardFx.muted,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gI, rod, rI) {
              final label = rI == 0 ? 'Sales' : 'Job Work';
              return BarTooltipItem(
                '$label\n${Formatters.currencyPkr(rod.toY)}',
                TextStyle(
                  color: rI == 0 ? DashboardFx.electric : DashboardFx.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < series.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 2,
              barRods: [
                BarChartRodData(
                  toY: series[i].salesAmount,
                  width: dense ? 4 : 8,
                  color: DashboardFx.electric,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                ),
                BarChartRodData(
                  toY: series[i].jobWorkAmount,
                  width: dense ? 4 : 8,
                  color: DashboardFx.primary,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}
}

class _StockDonut extends StatelessWidget {
  const _StockDonut({
    required this.small,
    required this.large,
    required this.waste,
    required this.smallAmount,
    required this.largeAmount,
    required this.totalAmount,
    this.showWaste = true,
    this.centerLabel = 'Processed',
  });

  final double small;
  final double large;
  final double waste;
  final double smallAmount;
  final double largeAmount;
  final double totalAmount;
  final bool showWaste;
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    final totalSq = small + large + (showWaste ? waste : 0);
    if (totalSq <= 0) {
      return _EmptyHint(
        showWaste
            ? 'No stock processed in this period'
            : 'No sales sq. ft in this period',
      );
    }

    final wasteLossPct = totalSq > 0 ? (waste / totalSq) * 100 : 0.0;

    return Column(
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
                            value: large <= 0 ? 0.001 : large,
                            color: DashboardFx.primary,
                            radius: 14,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: small <= 0 ? 0.001 : small,
                            color: DashboardFx.electric,
                            radius: 14,
                            showTitle: false,
                          ),
                          if (showWaste)
                            PieChartSectionData(
                              value: waste <= 0 ? 0.001 : waste,
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
                          _compactSqFt(totalSq),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          centerLabel,
                          style: const TextStyle(
                            color: DashboardFx.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailedLegend(
                        color: DashboardFx.primary,
                        label: 'Large',
                        sqft: _compactSqFt(large),
                        amount: Formatters.currencyCompact(largeAmount),
                      ),
                      const SizedBox(height: 5),
                      _DetailedLegend(
                        color: DashboardFx.electric,
                        label: 'Small',
                        sqft: _compactSqFt(small),
                        amount: Formatters.currencyCompact(smallAmount),
                      ),
                      if (showWaste) ...[
                        const SizedBox(height: 5),
                        _DetailedLegend(
                          color: DashboardFx.danger,
                          label: 'Waste/Yield',
                          sqft: _compactSqFt(waste),
                          badge: waste > 0
                              ? '${wasteLossPct.toStringAsFixed(1)}% loss'
                              : '0% loss',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: DashboardFx.elevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DashboardFx.cardBorder),
          ),
          child: Row(
            children: [
              Text(
                'Total ${showWaste ? "Cut" : "Sold"}: ',
                style: const TextStyle(
                  color: DashboardFx.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _compactSqFt(showWaste ? (small + large) : totalSq),
                style: const TextStyle(
                  color: DashboardFx.text,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                Formatters.currencyCompact(totalAmount),
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
    );
  }
}

class _DetailedLegend extends StatelessWidget {
  const _DetailedLegend({
    required this.color,
    required this.label,
    required this.sqft,
    this.amount,
    this.badge,
  });

  final Color color;
  final String label;
  final String sqft;
  final String? amount;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: const TextStyle(
            color: DashboardFx.muted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          sqft,
          style: const TextStyle(
            color: DashboardFx.text,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (amount != null || badge != null) ...[
          Text(
            ' · ',
            style: TextStyle(
              color: DashboardFx.muted.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          Text(
            amount ?? badge!,
            style: TextStyle(
              color: amount != null ? color : DashboardFx.danger,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _CollectionGauge extends StatefulWidget {
  const _CollectionGauge({
    required this.ratio,
    required this.collected,
    required this.pending,
  });

  final double ratio;
  final double collected;
  final double pending;

  @override
  State<_CollectionGauge> createState() => _CollectionGaugeState();
}

class _CollectionGaugeState extends State<_CollectionGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _sweep;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _sweep = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.ratio * 100).clamp(0.0, 100.0);

    return Column(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _sweep,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(160),
                    painter: _ArcGaugePainter(
                      ratio: widget.ratio * _sweep.value,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(pct * _sweep.value).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: DashboardFx.primary,
                        ),
                      ),
                      const Text(
                        'Collected',
                        style: TextStyle(
                          color: DashboardFx.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _Legend(
                color: DashboardFx.success,
                label: 'Paid',
                value: Formatters.currencyCompact(widget.collected),
              ),
            ),
            Expanded(
              child: _Legend(
                color: DashboardFx.danger,
                label: 'Pending',
                value: Formatters.currencyCompact(widget.pending),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({
    required this.activity,
    required this.user,
  });

  final List<RecentActivityItem> activity;
  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final actions = <({String label, IconData icon, VoidCallback? onTap})>[
      if (user?.canView(AppModule.jobWork) == true)
        (
          label: 'Create Job Work',
          icon: Icons.add_business_outlined,
          onTap: () => context.push(RoutePaths.jobWorkAdd),
        ),
      if (user?.canView(AppModule.sales) == true)
        (
          label: 'New Sales Order',
          icon: Icons.shopping_bag_outlined,
          onTap: () => context.push(RoutePaths.salesAdd),
        ),
      if (user?.canView(AppModule.sales) == true ||
          user?.canView(AppModule.jobWork) == true)
        (
          label: 'Record Payment',
          icon: Icons.payments_outlined,
          onTap: () => context.push(RoutePaths.notifications),
        ),
    ];

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: DashboardFxCard(
            title: 'Live Activity',
            subtitle: 'Recent payments',
            glowColor: DashboardFx.electric,
            child: activity.isEmpty
                ? const _EmptyHint(AppStrings.recentActivityEmpty)
                : ListView.separated(
                    itemCount: activity.take(5).length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 10,
                      color: DashboardFx.cardBorder,
                    ),
                    itemBuilder: (context, index) {
                      final item = activity[index];
                      return IntrinsicHeight(
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              decoration: BoxDecoration(
                                color: DashboardFx.success,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _relativeTime(item.timestamp),
                                    style: const TextStyle(
                                      color: DashboardFx.muted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (item.amount != null)
                              Text(
                                Formatters.currencyCompact(item.amount!),
                                style: const TextStyle(
                                  color: DashboardFx.success,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: DashboardFxCard(
            title: 'Quick Actions',
            subtitle: 'Fast shortcuts',
            glowColor: DashboardFx.primary,
            child: Column(
              children: [
                for (final action in actions)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: DashboardFx.elevated,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: action.onTap,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                Icon(
                                  action.icon,
                                  size: 16,
                                  color: DashboardFx.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    action.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12,
                                  color: DashboardFx.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (actions.isEmpty)
                  const Expanded(
                    child: _EmptyHint('No quick actions for your role'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: DashboardFxStyle.caption),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: DashboardFx.muted,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: DashboardFx.muted,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _compact(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
  return value.toStringAsFixed(0);
}

String _compactSqFt(double value) {
  if (value.abs() >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M sqft';
  }
  if (value.abs() >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K sqft';
  }
  return '${value.toStringAsFixed(0)} sqft';
}

String _relativeTime(DateTime timestamp) {
  final diff = DateTime.now().difference(timestamp);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat.MMMd().format(timestamp);
}

// ─── Task 4: "Today at a Glance" summary row ───────────────────────────

class _TodayAtAGlance extends StatelessWidget {
  const _TodayAtAGlance({required this.kpis});

  final DashboardKpis kpis;

  @override
  Widget build(BuildContext context) {
    final net = kpis.netCashflowToday;
    final items = [
      _GlanceItem(
        icon: Icons.trending_up_rounded,
        label: 'Revenue',
        value: Formatters.currencyCompact(kpis.revenueToday),
        color: DashboardFx.success,
      ),
      _GlanceItem(
        icon: Icons.trending_down_rounded,
        label: 'Expenses',
        value: Formatters.currencyCompact(kpis.expensesToday),
        color: DashboardFx.danger,
      ),
      _GlanceItem(
        icon: net >= 0
            ? Icons.account_balance_wallet_outlined
            : Icons.warning_amber_rounded,
        label: 'Net',
        value: Formatters.currencyCompact(net),
        color: net >= 0 ? DashboardFx.primary : DashboardFx.danger,
      ),
      _GlanceItem(
        icon: Icons.local_shipping_outlined,
        label: 'Dispatched',
        value: '${kpis.dispatchedTodayPieces} pcs',
        color: DashboardFx.electric,
      ),
    ];

    return DashboardFxCard(
      expandChild: false,
      glowColor: DashboardFx.primary,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) ...[
              Container(
                width: 1,
                height: 28,
                color: DashboardFx.cardBorder,
              ),
            ],
            Expanded(child: items[i]),
          ],
        ],
      ),
    );
  }
}

class _GlanceItem extends StatelessWidget {
  const _GlanceItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: -0.3,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: DashboardFx.muted,
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

// ─── Task 3: Live pulse dot ─────────────────────────────────────────────

class _LivePulseDot extends StatefulWidget {
  const _LivePulseDot();

  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final scale = 1.0 + (_pulse.value * 0.4);
        final opacity = 1.0 - (_pulse.value * 0.5);
        return SizedBox(
          width: 12,
          height: 12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        DashboardFx.success.withValues(alpha: 0.3 * opacity),
                  ),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: DashboardFx.success,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Task 5: Animated value text for KPI count-up ───────────────────────

class _AnimatedValueText extends StatelessWidget {
  const _AnimatedValueText({
    required this.fullValue,
    required this.progress,
    required this.accent,
  });

  final String fullValue;
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    // Extract numeric portion and display partially animated.
    // For compact values like "₨1.2M", we animate the numeric part.
    final numeric = RegExp(r'[\d.]+').firstMatch(fullValue);
    if (numeric == null || progress >= 1.0) {
      return _buildText(progress >= 1.0 ? fullValue : '');
    }

    final numStr = numeric.group(0)!;
    final numVal = double.tryParse(numStr) ?? 0;
    final animated = numVal * progress;

    // Preserve decimal places from original string.
    final decimals = numStr.contains('.')
        ? numStr.length - numStr.indexOf('.') - 1
        : 0;
    final animStr = animated.toStringAsFixed(decimals);

    final result = fullValue.replaceFirst(numStr, animStr);
    return _buildText(result);
  }

  Widget _buildText(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: accent,
        fontWeight: FontWeight.w800,
        fontSize: 18,
        letterSpacing: -0.5,
      ),
    );
  }
}

// ─── Task 7: Semi-circular arc gauge painter ────────────────────────────

class _ArcGaugePainter extends CustomPainter {
  _ArcGaugePainter({required this.ratio});

  final double ratio;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.6);
    final radius = size.width * 0.42;
    const strokeWidth = 12.0;
    const startAngle = math.pi * 0.8; // ~144° from 3 o'clock
    const sweepTotal = math.pi * 1.4; // 252° arc

    // Background track.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = DashboardFx.cardBorder,
    );

    // Gradient foreground arc.
    final sweepAngle = sweepTotal * ratio.clamp(0.0, 1.0);
    if (sweepAngle > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: startAngle,
            endAngle: startAngle + sweepTotal,
            colors: const [
              DashboardFx.danger,
              DashboardFx.primary,
              DashboardFx.success,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(rect),
      );

      // Needle dot at the tip.
      final needleAngle = startAngle + sweepAngle;
      final needlePos = Offset(
        center.dx + radius * math.cos(needleAngle),
        center.dy + radius * math.sin(needleAngle),
      );
      canvas.drawCircle(
        needlePos,
        5,
        Paint()..color = DashboardFx.text,
      );
      canvas.drawCircle(
        needlePos,
        3,
        Paint()..color = DashboardFx.primary,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcGaugePainter oldDelegate) =>
      oldDelegate.ratio != ratio;
}
