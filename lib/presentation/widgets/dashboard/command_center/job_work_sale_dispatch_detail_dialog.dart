import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/job_work_dispatch_metrics.dart';
import '../../../../domain/enums/dashboard_finance_period.dart';

class JobWorkSaleDispatchDetailDialog extends StatefulWidget {
  const JobWorkSaleDispatchDetailDialog({
    required this.jobWorkMetricsMap,
    required this.saleDispatchMetricsMap,
    this.initialPeriod = DashboardFinancePeriod.daily,
    this.initialTabIndex = 0,
    this.jobWorkTrendMap,
    this.saleDispatchTrendMap,
    super.key,
  });

  final Map<DashboardFinancePeriod, JobWorkDispatchCategoryMetrics>
      jobWorkMetricsMap;
  final Map<DashboardFinancePeriod, JobWorkDispatchCategoryMetrics>
      saleDispatchMetricsMap;
  final DashboardFinancePeriod initialPeriod;
  final int initialTabIndex; // 0: Job Work, 1: Sale Dispatch
  final Map<DashboardFinancePeriod, List<JobWorkDispatchTrendPoint>>?
      jobWorkTrendMap;
  final Map<DashboardFinancePeriod, List<JobWorkDispatchTrendPoint>>?
      saleDispatchTrendMap;

  static Future<void> show(
    BuildContext context, {
    required Map<DashboardFinancePeriod, JobWorkDispatchCategoryMetrics>
        jobWorkMetricsMap,
    required Map<DashboardFinancePeriod, JobWorkDispatchCategoryMetrics>
        saleDispatchMetricsMap,
    DashboardFinancePeriod initialPeriod = DashboardFinancePeriod.daily,
    int initialTabIndex = 0,
    Map<DashboardFinancePeriod, List<JobWorkDispatchTrendPoint>>?
        jobWorkTrendMap,
    Map<DashboardFinancePeriod, List<JobWorkDispatchTrendPoint>>?
        saleDispatchTrendMap,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => JobWorkSaleDispatchDetailDialog(
        jobWorkMetricsMap: jobWorkMetricsMap,
        saleDispatchMetricsMap: saleDispatchMetricsMap,
        initialPeriod: initialPeriod,
        initialTabIndex: initialTabIndex,
        jobWorkTrendMap: jobWorkTrendMap,
        saleDispatchTrendMap: saleDispatchTrendMap,
      ),
    );
  }

  @override
  State<JobWorkSaleDispatchDetailDialog> createState() =>
      _JobWorkSaleDispatchDetailDialogState();
}

class _JobWorkSaleDispatchDetailDialogState
    extends State<JobWorkSaleDispatchDetailDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _revealAnim;
  late int _selectedTab;
  late DashboardFinancePeriod _selectedPeriod;
  int? _hoveredTrendIndex;

  static const Color _largeColor = Color(0xFFF59E0B);
  static const Color _smallColor = Color(0xFF38BDF8);
  static const Color _jobWorkColor = Color(0xFF10B981);
  static const Color _saleColor = Color(0xFF8B5CF6);

  static String _formatPcs(int pcs) =>
      Formatters.formatStockQuantity(pcs, 'pcs');
  static String _formatSqFt(double sqft) =>
      Formatters.formatStockQuantity(sqft, 'sqft');

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _selectedPeriod = widget.initialPeriod;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _revealAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _isJobWork => _selectedTab == 0;

  JobWorkDispatchCategoryMetrics get _currentMetrics {
    final map =
        _isJobWork ? widget.jobWorkMetricsMap : widget.saleDispatchMetricsMap;
    return map[_selectedPeriod] ?? JobWorkDispatchCategoryMetrics.empty;
  }

  List<JobWorkDispatchTrendPoint> get _effectiveTrendPoints {
    final map =
        _isJobWork ? widget.jobWorkTrendMap : widget.saleDispatchTrendMap;
    final provided = map?[_selectedPeriod];
    if (provided != null && provided.isNotEmpty) return provided;

    // Default fallback trend series
    final current = _currentMetrics;
    final labels = _selectedPeriod == DashboardFinancePeriod.daily
        ? ['08:00', '11:00', '14:00', '17:00', '20:00']
        : (_selectedPeriod == DashboardFinancePeriod.weekly
            ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
            : ['W1', 'W2', 'W3', 'W4']);

    final count = labels.length;
    return List.generate(count, (i) {
      final factor = (i == count - 2 || i == count - 1) ? 1.2 : 0.9;
      final lPcs = ((current.largePieces / count) * factor).round();
      final sPcs = ((current.smallPieces / count) * factor).round();
      final lSq = (current.largeSqFt / count) * factor;
      final sSq = (current.smallSqFt / count) * factor;
      return JobWorkDispatchTrendPoint(
        label: labels[i],
        largePieces: lPcs,
        largeSqFt: lSq,
        smallPieces: sPcs,
        smallSqFt: sSq,
      );
    });
  }

  void _handleScrub(Offset localPosition, Size boxSize) {
    final points = _effectiveTrendPoints;
    if (points.isEmpty) return;
    const paddingHorizontal = 12.0;
    final width = math.max(1.0, boxSize.width - (paddingHorizontal * 2));
    final dx = (localPosition.dx - paddingHorizontal).clamp(0.0, width);
    final count = points.length;
    final step = count > 1 ? width / (count - 1) : width;
    final idx = (dx / step).round().clamp(0, count - 1);

    if (idx != _hoveredTrendIndex) {
      setState(() => _hoveredTrendIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF131927) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1A2234) : const Color(0xFFF8FAFC);
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0);
    final textMuted =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accentColor = _isJobWork ? _jobWorkColor : _saleColor;
    final metrics = _currentMetrics;

    return Dialog(
      backgroundColor: surfaceColor,
      elevation: 24,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: AnimatedBuilder(
            animation: _revealAnim,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.95 + (0.05 * _revealAnim.value),
                child: Opacity(
                  opacity: _revealAnim.value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Indicator Accent Strip
                Container(
                  height: 3.5,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor,
                        accentColor.withValues(alpha: 0.25),
                      ],
                    ),
                  ),
                ),

                // Header Bar with Job Work / Sale Dispatch Segmented Toggle
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          _isJobWork
                              ? Icons.precision_manufacturing_rounded
                              : Icons.local_shipping_rounded,
                          size: 20,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isJobWork
                                  ? 'Job Work Collection Detail'
                                  : 'Sale Dispatch Detail',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'Pieces (pcs) & Volume (sqft) breakdown',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Header Module Switcher
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PillTab(
                              label: 'Job Work',
                              selected: _isJobWork,
                              color: _jobWorkColor,
                              onTap: () => setState(() {
                                _selectedTab = 0;
                                _hoveredTrendIndex = null;
                              }),
                            ),
                            _PillTab(
                              label: 'Dispatch',
                              selected: !_isJobWork,
                              color: _saleColor,
                              onTap: () => setState(() {
                                _selectedTab = 1;
                                _hoveredTrendIndex = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: textMuted,
                        hoverColor: accentColor.withValues(alpha: 0.1),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                // Interactive Period Selector Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'PERIOD:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Wrap(
                        spacing: 6,
                        children: DashboardFinancePeriod.values.map((p) {
                          final selected = p == _selectedPeriod;
                          return ChoiceChip(
                            label: Text(p.label),
                            selected: selected,
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedPeriod = p;
                                  _hoveredTrendIndex = null;
                                });
                              }
                            },
                            showCheckmark: false,
                            selectedColor: accentColor.withValues(alpha: 0.2),
                            backgroundColor: isDark
                                ? const Color(0xFF1B2230)
                                : const Color(0xFFEDF2F7),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w600,
                              color: selected
                                  ? accentColor
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            side: BorderSide(
                              color: selected
                                  ? accentColor.withValues(alpha: 0.4)
                                  : borderColor,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 0),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primary Unaggregated Metrics Summary Banner
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _isJobWork
                                          ? 'TOTAL JOB WORK COLLECTED (${_selectedPeriod.label.toUpperCase()})'
                                          : 'TOTAL SALE DISPATCHED (${_selectedPeriod.label.toUpperCase()})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: textMuted,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            accentColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      _isJobWork
                                          ? 'JOB WORK'
                                          : 'SALE DISPATCH',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Pieces',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        SizedBox(
                                          width: double.infinity,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              _formatPcs(metrics.totalPieces),
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w900,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0F172A),
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 36,
                                    width: 1,
                                    color: borderColor,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Sq. Ft.',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        SizedBox(
                                          width: double.infinity,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              _formatSqFt(metrics.totalSqFt),
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w900,
                                                color: accentColor,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Large & Small Category Breakdown Grid
                        Row(
                          children: [
                            Expanded(
                              child: _BreakdownCard(
                                title: 'Large Stock Slabs',
                                pcsText: _formatPcs(metrics.largePieces),
                                sqftText: _formatSqFt(metrics.largeSqFt),
                                accentColor: _largeColor,
                                icon: Icons.crop_landscape_rounded,
                                isDark: isDark,
                                cardBg: cardBg,
                                borderColor: borderColor,
                                textMuted: textMuted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _BreakdownCard(
                                title: 'Small Stock Tiles',
                                pcsText: _formatPcs(metrics.smallPieces),
                                sqftText: _formatSqFt(metrics.smallSqFt),
                                accentColor: _smallColor,
                                icon: Icons.grid_view_rounded,
                                isDark: isDark,
                                cardBg: cardBg,
                                borderColor: borderColor,
                                textMuted: textMuted,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Historical Time-Series Graph Header
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _isJobWork
                                    ? 'COLLECTION TREND (LARGE VS SMALL SQFT)'
                                    : 'DISPATCH TREND (LARGE VS SMALL SQFT)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: textMuted,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            if (_hoveredTrendIndex != null &&
                                _hoveredTrendIndex! <
                                    _effectiveTrendPoints.length) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${_effectiveTrendPoints[_hoveredTrendIndex!].label}: ${_formatSqFt(_effectiveTrendPoints[_hoveredTrendIndex!].totalSqFt)} (${_effectiveTrendPoints[_hoveredTrendIndex!].totalPieces} pcs)',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Dual-Metric Stacked Bar Canvas Chart
                        Container(
                          height: 180,
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final boxSize = Size(constraints.maxWidth, 180);
                              return MouseRegion(
                                onHover: (event) => _handleScrub(
                                    event.localPosition, boxSize),
                                onExit: (_) =>
                                    setState(() => _hoveredTrendIndex = null),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (details) => _handleScrub(
                                      details.localPosition, boxSize),
                                  onPanStart: (details) => _handleScrub(
                                      details.localPosition, boxSize),
                                  onPanUpdate: (details) => _handleScrub(
                                      details.localPosition, boxSize),
                                  onPanEnd: (_) => setState(
                                      () => _hoveredTrendIndex = null),
                                  child: AnimatedBuilder(
                                    animation: _revealAnim,
                                    builder: (context, _) {
                                      return CustomPaint(
                                        size: Size.infinite,
                                        painter: _JobWorkDispatchTrendPainter(
                                          points: _effectiveTrendPoints,
                                          largeColor: _largeColor,
                                          smallColor: _smallColor,
                                          hoveredIndex: _hoveredTrendIndex,
                                          progress: _revealAnim.value,
                                          isDark: isDark,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                // Compact Footer Actions Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton.tonal(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFE2E8F0),
                          foregroundColor:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          minimumSize: const Size(80, 34),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
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

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: selected
              ? Border.all(color: color.withValues(alpha: 0.4))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? color
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.title,
    required this.pcsText,
    required this.sqftText,
    required this.accentColor,
    required this.icon,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textMuted,
  });

  final String title;
  final String pcsText;
  final String sqftText;
  final Color accentColor;
  final IconData icon;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Volume & Pieces',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$sqftText · $pcsText',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobWorkDispatchTrendPainter extends CustomPainter {
  _JobWorkDispatchTrendPainter({
    required this.points,
    required this.largeColor,
    required this.smallColor,
    required this.hoveredIndex,
    required this.progress,
    required this.isDark,
  });

  final List<JobWorkDispatchTrendPoint> points;
  final Color largeColor;
  final Color smallColor;
  final int? hoveredIndex;
  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final gridPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const topPadding = 18.0;
    const bottomPadding = 24.0;
    final chartHeight = size.height - topPadding - bottomPadding;
    final chartWidth = size.width;

    // Grid lines
    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (chartHeight / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    final maxVal = points.map((e) => e.totalSqFt).reduce(math.max);
    final effectiveMax = maxVal == 0 ? 1.0 : maxVal * 1.15;

    final barGroupWidth = chartWidth / points.length;
    final barWidth = (barGroupWidth * 0.45).clamp(16.0, 34.0);

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final cx = (i * barGroupWidth) + (barGroupWidth / 2);
      final isHovered = hoveredIndex == i;

      final normalizedLarge = (p.largeSqFt / effectiveMax).clamp(0.0, 1.0);
      final normalizedSmall = (p.smallSqFt / effectiveMax).clamp(0.0, 1.0);

      final largeBarH = chartHeight * normalizedLarge * progress;
      final smallBarH = chartHeight * normalizedSmall * progress;

      final baseBottomY = topPadding + chartHeight;
      final largeTopY = baseBottomY - largeBarH;
      final smallTopY = largeTopY - smallBarH;

      // Draw Large Stock Bar (Bottom)
      if (largeBarH > 0) {
        final largeRect = RRect.fromRectAndRadius(
          Rect.fromLTRB(
              cx - (barWidth / 2), largeTopY, cx + (barWidth / 2), baseBottomY),
          const Radius.circular(4),
        );
        final largePaint = Paint()
          ..color = isHovered ? largeColor : largeColor.withValues(alpha: 0.85);
        canvas.drawRRect(largeRect, largePaint);
      }

      // Draw Small Stock Bar (Stacked Top)
      if (smallBarH > 0) {
        final smallRect = RRect.fromRectAndRadius(
          Rect.fromLTRB(
              cx - (barWidth / 2), smallTopY, cx + (barWidth / 2), largeTopY),
          const Radius.circular(4),
        );
        final smallPaint = Paint()
          ..color = isHovered ? smallColor : smallColor.withValues(alpha: 0.85);
        canvas.drawRRect(smallRect, smallPaint);
      }

      // Top value text
      textPainter.text = TextSpan(
        text: Formatters.formatStockQuantity(p.totalSqFt, 'sqft', compact: true),
        style: TextStyle(
          color: isHovered
              ? largeColor
              : (isDark ? Colors.white70 : Colors.black87),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(cx - (textPainter.width / 2), math.max(2.0, smallTopY - 13)),
      );

      // X Axis Label
      textPainter.text = TextSpan(
        text: p.label,
        style: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          fontSize: 10,
          fontWeight: isHovered ? FontWeight.w800 : FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(cx - (textPainter.width / 2), size.height - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _JobWorkDispatchTrendPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.progress != progress;
  }
}
