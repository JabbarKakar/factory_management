import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/formatters.dart';

class StockCutTrendPoint {
  const StockCutTrendPoint({
    required this.label,
    required this.largeSqFt,
    required this.smallSqFt,
    this.wasteSqFt = 0,
    this.amount = 0,
  });

  final String label;
  final double largeSqFt;
  final double smallSqFt;
  final double wasteSqFt;
  final double amount;

  double get totalSqFt => largeSqFt + smallSqFt + wasteSqFt;
}

class StockCutDetailDialog extends StatefulWidget {
  const StockCutDetailDialog({
    required this.smallSqFt,
    required this.largeSqFt,
    required this.wasteSqFt,
    required this.smallAmount,
    required this.largeAmount,
    required this.salesSmallSqFt,
    required this.salesLargeSqFt,
    required this.salesSmallAmount,
    required this.salesLargeAmount,
    this.initialTabIndex = 0,
    this.cutTrendPoints,
    this.soldTrendPoints,
    super.key,
  });

  final double smallSqFt;
  final double largeSqFt;
  final double wasteSqFt;
  final double smallAmount;
  final double largeAmount;
  final double salesSmallSqFt;
  final double salesLargeSqFt;
  final double salesSmallAmount;
  final double salesLargeAmount;
  final int initialTabIndex;
  final List<StockCutTrendPoint>? cutTrendPoints;
  final List<StockCutTrendPoint>? soldTrendPoints;

  static Future<void> show(
    BuildContext context, {
    required double smallSqFt,
    required double largeSqFt,
    required double wasteSqFt,
    required double smallAmount,
    required double largeAmount,
    required double salesSmallSqFt,
    required double salesLargeSqFt,
    required double salesSmallAmount,
    required double salesLargeAmount,
    int initialTabIndex = 0,
    List<StockCutTrendPoint>? cutTrendPoints,
    List<StockCutTrendPoint>? soldTrendPoints,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => StockCutDetailDialog(
        smallSqFt: smallSqFt,
        largeSqFt: largeSqFt,
        wasteSqFt: wasteSqFt,
        smallAmount: smallAmount,
        largeAmount: largeAmount,
        salesSmallSqFt: salesSmallSqFt,
        salesLargeSqFt: salesLargeSqFt,
        salesSmallAmount: salesSmallAmount,
        salesLargeAmount: salesLargeAmount,
        initialTabIndex: initialTabIndex,
        cutTrendPoints: cutTrendPoints,
        soldTrendPoints: soldTrendPoints,
      ),
    );
  }

  @override
  State<StockCutDetailDialog> createState() => _StockCutDetailDialogState();
}

class _StockCutDetailDialogState extends State<StockCutDetailDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _revealAnim;
  late int _selectedTab;
  int? _hoveredTrendIndex;
  int? _hoveredDonutIndex;

  static const Color _largeColor = Color(0xFFF59E0B);
  static const Color _smallColor = Color(0xFF38BDF8);
  static const Color _wasteColor = Color(0xFFEF4444);

  static final NumberFormat _sqFtFormat = NumberFormat('#,##0');

  static String _formatSqFt(double val) => '${_sqFtFormat.format(val)} sqft';

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
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

  bool get _isCut => _selectedTab == 0;

  double get _currentLargeSqFt => _isCut ? widget.largeSqFt : widget.salesLargeSqFt;
  double get _currentSmallSqFt => _isCut ? widget.smallSqFt : widget.salesSmallSqFt;
  double get _currentWasteSqFt => _isCut ? widget.wasteSqFt : 0;
  double get _currentLargeAmount => _isCut ? widget.largeAmount : widget.salesLargeAmount;
  double get _currentSmallAmount => _isCut ? widget.smallAmount : widget.salesSmallAmount;
  double get _currentTotalSqFt => _currentLargeSqFt + _currentSmallSqFt + _currentWasteSqFt;
  double get _currentTotalAmount => _currentLargeAmount + _currentSmallAmount;

  List<StockCutTrendPoint> get _effectiveTrendPoints {
    final provided = _isCut ? widget.cutTrendPoints : widget.soldTrendPoints;
    if (provided != null && provided.isNotEmpty) return provided;

    // Fallback series
    final baseAmount = _currentTotalAmount;
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return List.generate(labels.length, (i) {
      final factor = (i == 4 || i == 5) ? 1.25 : (i == 0 ? 0.75 : 1.0);
      final lSq = (_currentLargeSqFt / 7) * factor;
      final sSq = (_currentSmallSqFt / 7) * factor;
      final wSq = _isCut ? (_currentWasteSqFt / 7) * factor : 0.0;
      final amt = (baseAmount / 7) * factor;
      return StockCutTrendPoint(
        label: labels[i],
        largeSqFt: lSq,
        smallSqFt: sSq,
        wasteSqFt: wSq,
        amount: amt,
      );
    });
  }

  void _handleTrendScrub(Offset localPosition, Size boxSize) {
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
    final accentColor = _isCut ? _largeColor : _smallColor;

    final wastePct = _currentTotalSqFt > 0
        ? (_currentWasteSqFt / _currentTotalSqFt) * 100
        : 0.0;
    final largePct = _currentTotalSqFt > 0
        ? (_currentLargeSqFt / _currentTotalSqFt) * 100
        : 0.0;
    final smallPct = _currentTotalSqFt > 0
        ? (_currentSmallSqFt / _currentTotalSqFt) * 100
        : 0.0;

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
          constraints: const BoxConstraints(maxWidth: 580),
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

                // Header Bar with Cut / Sold Mode Segmented Toggle
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
                          _isCut
                              ? Icons.content_cut_rounded
                              : Icons.shopping_bag_rounded,
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
                              _isCut
                                  ? 'Stock Cut Distribution'
                                  : 'Sales Stock Distribution',
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
                              'Large · Small · Waste & Yield',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Header Segmented Toggle
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
                            _HeaderTabPill(
                              label: 'Cut',
                              selected: _isCut,
                              color: _largeColor,
                              onTap: () => setState(() {
                                _selectedTab = 0;
                                _hoveredTrendIndex = null;
                              }),
                            ),
                            _HeaderTabPill(
                              label: 'Sold',
                              selected: !_isCut,
                              color: _smallColor,
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

                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Unaggregated Precise Metrics Banner Card
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
                                      _isCut
                                          ? 'UNAGGREGATED TOTAL CUT METRICS'
                                          : 'UNAGGREGATED TOTAL SOLD METRICS',
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
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            accentColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      _isCut ? 'CUT MODE' : 'SOLD MODE',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Volume',
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
                                              _formatSqFt(_currentTotalSqFt),
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
                                          'Total Value',
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
                                              Formatters.currencyFull(
                                                  _currentTotalAmount),
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

                        const SizedBox(height: 18),

                        // Donut Chart & Category Breakdown Cards Section
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
                              Text(
                                'CATEGORY VOLUME & MONETARY BREAKDOWN',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: textMuted,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // Donut Chart Canvas Widget
                                  SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        AnimatedBuilder(
                                          animation: _revealAnim,
                                          builder: (context, _) {
                                            return CustomPaint(
                                              size: const Size(120, 120),
                                              painter: _DonutChartPainter(
                                                largeSqFt: _currentLargeSqFt,
                                                smallSqFt: _currentSmallSqFt,
                                                wasteSqFt: _currentWasteSqFt,
                                                largeColor: _largeColor,
                                                smallColor: _smallColor,
                                                wasteColor: _wasteColor,
                                                progress: _revealAnim.value,
                                                isDark: isDark,
                                                hoveredIndex: _hoveredDonutIndex,
                                              ),
                                            );
                                          },
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8),
                                                child: Text(
                                                  _formatSqFt(
                                                      _currentTotalSqFt),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w900,
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF0F172A),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _isCut ? 'Cut' : 'Sold',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w600,
                                                color: textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Category Item Breakdown List
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _CategoryMetricRow(
                                          color: _largeColor,
                                          label: 'Large Slabs',
                                          sqft: _formatSqFt(_currentLargeSqFt),
                                          amount: Formatters.currencyFull(
                                              _currentLargeAmount),
                                          percentage:
                                              '${largePct.toStringAsFixed(0)}%',
                                          isDark: isDark,
                                          textMuted: textMuted,
                                        ),
                                        const SizedBox(height: 8),
                                        _CategoryMetricRow(
                                          color: _smallColor,
                                          label: 'Small Tiles',
                                          sqft: _formatSqFt(_currentSmallSqFt),
                                          amount: Formatters.currencyFull(
                                              _currentSmallAmount),
                                          percentage:
                                              '${smallPct.toStringAsFixed(0)}%',
                                          isDark: isDark,
                                          textMuted: textMuted,
                                        ),
                                        if (_isCut) ...[
                                          const SizedBox(height: 8),
                                          _CategoryMetricRow(
                                            color: _wasteColor,
                                            label: 'Waste / Yield',
                                            sqft: _formatSqFt(
                                                _currentWasteSqFt),
                                            amount:
                                                '${wastePct.toStringAsFixed(1)}% loss',
                                            percentage:
                                                '${wastePct.toStringAsFixed(0)}%',
                                            isDark: isDark,
                                            textMuted: textMuted,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Time-Series Historical Chart Section
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _isCut
                                    ? 'DAILY CUTTING OUTPUT TREND'
                                    : 'DAILY SALES VOLUME TREND',
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
                                      '${_effectiveTrendPoints[_hoveredTrendIndex!].label}: ${_formatSqFt(_effectiveTrendPoints[_hoveredTrendIndex!].totalSqFt)} (${Formatters.currencyFull(_effectiveTrendPoints[_hoveredTrendIndex!].amount)})',
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

                        Container(
                          height: 175,
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final boxSize = Size(constraints.maxWidth, 175);
                              return MouseRegion(
                                onHover: (event) => _handleTrendScrub(
                                    event.localPosition, boxSize),
                                onExit: (_) =>
                                    setState(() => _hoveredTrendIndex = null),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (details) => _handleTrendScrub(
                                      details.localPosition, boxSize),
                                  onPanStart: (details) => _handleTrendScrub(
                                      details.localPosition, boxSize),
                                  onPanUpdate: (details) => _handleTrendScrub(
                                      details.localPosition, boxSize),
                                  onPanEnd: (_) => setState(
                                      () => _hoveredTrendIndex = null),
                                  child: AnimatedBuilder(
                                    animation: _revealAnim,
                                    builder: (context, _) {
                                      return CustomPaint(
                                        size: Size.infinite,
                                        painter: _StockTrendChartPainter(
                                          points: _effectiveTrendPoints,
                                          largeColor: _largeColor,
                                          smallColor: _smallColor,
                                          wasteColor: _wasteColor,
                                          hoveredIndex: _hoveredTrendIndex,
                                          progress: _revealAnim.value,
                                          isDark: isDark,
                                          isCutMode: _isCut,
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

class _HeaderTabPill extends StatelessWidget {
  const _HeaderTabPill({
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
            color: selected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _CategoryMetricRow extends StatelessWidget {
  const _CategoryMetricRow({
    required this.color,
    required this.label,
    required this.sqft,
    required this.amount,
    required this.percentage,
    required this.isDark,
    required this.textMuted,
  });

  final Color color;
  final String label;
  final String sqft;
  final String amount;
  final String percentage;
  final bool isDark;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131927) : const Color(0xFFEDF2F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      percentage,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$sqft · $amount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
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

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.largeSqFt,
    required this.smallSqFt,
    required this.wasteSqFt,
    required this.largeColor,
    required this.smallColor,
    required this.wasteColor,
    required this.progress,
    required this.isDark,
    this.hoveredIndex,
  });

  final double largeSqFt;
  final double smallSqFt;
  final double wasteSqFt;
  final Color largeColor;
  final Color smallColor;
  final Color wasteColor;
  final double progress;
  final bool isDark;
  final int? hoveredIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final total = largeSqFt + smallSqFt + wasteSqFt;
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 8;
    const strokeWidth = 14.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    var startAngle = -math.pi / 2;
    final slices = [
      (value: largeSqFt, color: largeColor),
      (value: smallSqFt, color: smallColor),
      if (wasteSqFt > 0) (value: wasteSqFt, color: wasteColor),
    ];

    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final sweepAngle = (slice.value / total) * (2 * math.pi) * progress;

      paint.color = slice.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.largeSqFt != largeSqFt ||
        oldDelegate.smallSqFt != smallSqFt ||
        oldDelegate.wasteSqFt != wasteSqFt ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}

class _StockTrendChartPainter extends CustomPainter {
  _StockTrendChartPainter({
    required this.points,
    required this.largeColor,
    required this.smallColor,
    required this.wasteColor,
    required this.hoveredIndex,
    required this.progress,
    required this.isDark,
    required this.isCutMode,
  });

  final List<StockCutTrendPoint> points;
  final Color largeColor;
  final Color smallColor;
  final Color wasteColor;
  final int? hoveredIndex;
  final double progress;
  final bool isDark;
  final bool isCutMode;

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

    // Horizontal grid lines
    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (chartHeight / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    final maxVal = points.map((e) => e.totalSqFt).reduce(math.max);
    final effectiveMax = maxVal == 0 ? 1.0 : maxVal * 1.15;

    final barGroupWidth = chartWidth / points.length;
    final barWidth = (barGroupWidth * 0.4).clamp(14.0, 32.0);

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final cx = (i * barGroupWidth) + (barGroupWidth / 2);
      final isHovered = hoveredIndex == i;

      final normalizedTotal = (p.totalSqFt / effectiveMax).clamp(0.0, 1.0);
      final totalBarH = chartHeight * normalizedTotal * progress;
      final topY = topPadding + chartHeight - totalBarH;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
            cx - (barWidth / 2), topY, cx + (barWidth / 2), topPadding + chartHeight),
        const Radius.circular(5),
      );

      final barColor = isHovered
          ? (isCutMode ? largeColor : smallColor)
          : (isCutMode ? largeColor.withValues(alpha: 0.8) : smallColor.withValues(alpha: 0.8));

      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            barColor,
            barColor.withValues(alpha: 0.3),
          ],
        ).createShader(rect.outerRect);

      canvas.drawRRect(rect, barPaint);

      // Top value label
      textPainter.text = TextSpan(
        text: Formatters.currencyCompact(p.totalSqFt),
        style: TextStyle(
          color: isHovered
              ? barColor
              : (isDark ? Colors.white70 : Colors.black87),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(cx - (textPainter.width / 2), math.max(2.0, topY - 13)),
      );

      // X Label
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
  bool shouldRepaint(covariant _StockTrendChartPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.progress != progress ||
        oldDelegate.isCutMode != isCutMode;
  }
}
