import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/job_work_dispatch_metrics.dart';
import '../../../../domain/enums/dashboard_finance_period.dart';
import 'dashboard_fx_card.dart';
import 'dashboard_fx_theme.dart';
import 'job_work_sale_dispatch_detail_dialog.dart';

/// Single card with a "Collection / Dispatch" header toggle.
/// Formats physical inventory quantities (sqft / pcs) without currency symbols.
/// Relies on the global period from the parent.
class DashboardJobWorkDispatchSection extends StatefulWidget {
  const DashboardJobWorkDispatchSection({
    required this.jobWorkMetrics,
    required this.saleDispatchMetrics,
    required this.period,
    this.jobWorkMetricsMap = const {},
    this.saleDispatchMetricsMap = const {},
    this.jobWorkTrendMap,
    this.saleDispatchTrendMap,
    super.key,
  });

  /// Current-period metrics (pre-resolved by parent).
  final JobWorkDispatchCategoryMetrics jobWorkMetrics;
  final JobWorkDispatchCategoryMetrics saleDispatchMetrics;
  final DashboardFinancePeriod period;

  /// Full maps needed by the drill-down dialog for period switching.
  final Map<DashboardFinancePeriod, JobWorkDispatchCategoryMetrics>
      jobWorkMetricsMap;
  final Map<DashboardFinancePeriod, JobWorkDispatchCategoryMetrics>
      saleDispatchMetricsMap;
  final Map<DashboardFinancePeriod, List<JobWorkDispatchTrendPoint>>?
      jobWorkTrendMap;
  final Map<DashboardFinancePeriod, List<JobWorkDispatchTrendPoint>>?
      saleDispatchTrendMap;

  @override
  State<DashboardJobWorkDispatchSection> createState() =>
      _DashboardJobWorkDispatchSectionState();
}

class _DashboardJobWorkDispatchSectionState
    extends State<DashboardJobWorkDispatchSection> {
  int _tab = 0; // 0 = Collection, 1 = Dispatch

  bool get _isCollection => _tab == 0;

  JobWorkDispatchCategoryMetrics get _activeMetrics =>
      _isCollection ? widget.jobWorkMetrics : widget.saleDispatchMetrics;

  static const Color _collectionColor = Color(0xFF10B981);
  static const Color _dispatchColor = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final accentColor = _isCollection ? _collectionColor : _dispatchColor;

    return DashboardFxCard(
      title: _isCollection ? 'Job Work Collection' : 'Sale Dispatch',
      subtitle: _isCollection
          ? 'Large · Small collected'
          : 'Large · Small dispatched',
      glowColor: accentColor,
      expandChild: false,
      trailing: _MiniToggle(
        labels: const ['Collection', 'Dispatch'],
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openDialog(context),
          child: _DonutBody(
            metrics: _activeMetrics,
            accentColor: accentColor,
            centerLabel: _isCollection ? 'Collected' : 'Dispatched',
          ),
        ),
      ),
    );
  }

  void _openDialog(BuildContext context) {
    JobWorkSaleDispatchDetailDialog.show(
      context,
      jobWorkMetricsMap: widget.jobWorkMetricsMap,
      saleDispatchMetricsMap: widget.saleDispatchMetricsMap,
      initialPeriod: widget.period,
      initialTabIndex: _tab,
      jobWorkTrendMap: widget.jobWorkTrendMap,
      saleDispatchTrendMap: widget.saleDispatchTrendMap,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Mini toggle pills (identical style to Stock Cut's Cut/Sold tabs)
// ────────────────────────────────────────────────────────────────────────────

class _MiniToggle extends StatelessWidget {
  const _MiniToggle({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final primaryColor = DashboardFx.primary(context);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: DashboardFx.elevated(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardFx.cardBorder(context)),
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
                      ? primaryColor.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: i == index
                        ? primaryColor
                        : DashboardFx.muted(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Donut + Legend + Summary bar (mirrors Stock Cut visual pattern)
// ────────────────────────────────────────────────────────────────────────────

class _DonutBody extends StatelessWidget {
  const _DonutBody({
    required this.metrics,
    required this.accentColor,
    required this.centerLabel,
  });

  final JobWorkDispatchCategoryMetrics metrics;
  final Color accentColor;
  final String centerLabel;

  static const Color _largeColor = Color(0xFFF59E0B);
  static const Color _smallColor = Color(0xFF38BDF8);

  String _pcsLabel(int pcs) =>
      Formatters.formatStockQuantity(pcs, 'pcs', compact: true);
  String _sqftLabel(double sqft) =>
      Formatters.formatStockQuantity(sqft, 'sqft', compact: true);

  @override
  Widget build(BuildContext context) {
    final totalSq = metrics.totalSqFt;
    final totalPcs = metrics.totalPieces;
    final textColor = DashboardFx.text(context);
    final mutedColor = DashboardFx.muted(context);

    if (totalSq <= 0 && totalPcs <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No data in this period',
            style: TextStyle(
              color: mutedColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Donut + Legend Row
        SizedBox(
          height: 110,
          child: Row(
            children: [
              // Pie donut
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 32,
                        sections: [
                          PieChartSectionData(
                            value: metrics.largeSqFt <= 0
                                ? 0.001
                                : metrics.largeSqFt,
                            color: _largeColor,
                            radius: 12,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: metrics.smallSqFt <= 0
                                ? 0.001
                                : metrics.smallSqFt,
                            color: _smallColor,
                            radius: 12,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _sqftLabel(totalSq),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          centerLabel,
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Legend indicators
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LegendRow(
                        color: _largeColor,
                        label: 'Large',
                        primary: _sqftLabel(metrics.largeSqFt),
                        secondary: _pcsLabel(metrics.largePieces),
                      ),
                      const SizedBox(height: 5),
                      _LegendRow(
                        color: _smallColor,
                        label: 'Small',
                        primary: _sqftLabel(metrics.smallSqFt),
                        secondary: _pcsLabel(metrics.smallPieces),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Summary footer bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: DashboardFx.elevated(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DashboardFx.cardBorder(context)),
          ),
          child: Row(
            children: [
              Text(
                'Total: ',
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _sqftLabel(totalSq),
                style: TextStyle(
                  color: textColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _pcsLabel(totalPcs),
                style: TextStyle(
                  color: accentColor,
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

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.primary,
    required this.secondary,
  });

  final Color color;
  final String label;
  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    final mutedColor = DashboardFx.muted(context);
    final textColor = DashboardFx.text(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: TextStyle(
            color: mutedColor,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          primary,
          style: TextStyle(
            color: textColor,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          secondary,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
