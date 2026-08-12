import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';

enum FinancialMetricType {
  income,
  expenses,
  netMargin,
  receivables,
}

class FinancialTrendPoint {
  const FinancialTrendPoint({
    required this.label,
    required this.value,
    this.secondaryValue,
    this.subLabel,
  });

  final String label;
  final double value;
  final double? secondaryValue;
  final String? subLabel;
}

class FinancialBreakdownItem {
  const FinancialBreakdownItem({
    required this.label,
    required this.amount,
    this.percentage,
    this.color,
    this.icon,
  });

  final String label;
  final double amount;
  final String? percentage;
  final Color? color;
  final IconData? icon;
}

class FinancialDetailDialog extends StatefulWidget {
  const FinancialDetailDialog({
    required this.title,
    required this.preciseAmount,
    required this.accentColor,
    required this.metricType,
    required this.trendPoints,
    this.caption,
    this.changePercent,
    this.badgeText,
    this.breakdownItems,
    this.timeFrameLabel,
    this.onViewReport,
    super.key,
  });

  final String title;
  final double preciseAmount;
  final Color accentColor;
  final FinancialMetricType metricType;
  final List<FinancialTrendPoint> trendPoints;
  final String? caption;
  final double? changePercent;
  final String? badgeText;
  final List<FinancialBreakdownItem>? breakdownItems;
  final String? timeFrameLabel;
  final VoidCallback? onViewReport;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required double preciseAmount,
    required Color accentColor,
    required FinancialMetricType metricType,
    required List<FinancialTrendPoint> trendPoints,
    String? caption,
    double? changePercent,
    String? badgeText,
    List<FinancialBreakdownItem>? breakdownItems,
    String? timeFrameLabel,
    VoidCallback? onViewReport,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => FinancialDetailDialog(
        title: title,
        preciseAmount: preciseAmount,
        accentColor: accentColor,
        metricType: metricType,
        trendPoints: trendPoints,
        caption: caption,
        changePercent: changePercent,
        badgeText: badgeText,
        breakdownItems: breakdownItems,
        timeFrameLabel: timeFrameLabel,
        onViewReport: onViewReport,
      ),
    );
  }

  @override
  State<FinancialDetailDialog> createState() => _FinancialDetailDialogState();
}

class _FinancialDetailDialogState extends State<FinancialDetailDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _revealAnim;
  int? _hoveredPointIndex;

  @override
  void initState() {
    super.initState();
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

  void _handlePointerScrub(Offset localPosition, Size boxSize) {
    if (widget.trendPoints.isEmpty) return;
    const paddingHorizontal = 12.0;
    final width = math.max(1.0, boxSize.width - (paddingHorizontal * 2));
    final dx = (localPosition.dx - paddingHorizontal).clamp(0.0, width);
    final count = widget.trendPoints.length;

    int idx;
    if (widget.metricType == FinancialMetricType.receivables) {
      idx = (dx / (width / count)).floor().clamp(0, count - 1);
    } else {
      final step = count > 1 ? width / (count - 1) : width;
      idx = (dx / step).round().clamp(0, count - 1);
    }

    if (idx != _hoveredPointIndex) {
      setState(() => _hoveredPointIndex = idx);
    }
  }

  IconData get _metricIcon {
    switch (widget.metricType) {
      case FinancialMetricType.income:
        return Icons.trending_up_rounded;
      case FinancialMetricType.expenses:
        return Icons.receipt_long_rounded;
      case FinancialMetricType.netMargin:
        return Icons.account_balance_wallet_rounded;
      case FinancialMetricType.receivables:
        return Icons.pending_actions_rounded;
    }
  }

  String get _defaultTimeFrame {
    if (widget.timeFrameLabel != null) return widget.timeFrameLabel!;
    switch (widget.metricType) {
      case FinancialMetricType.receivables:
        return 'Aging Breakdown (0 - 90+ Days)';
      default:
        return '6-Month Historical Trend';
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

    final isReceivables =
        widget.metricType == FinancialMetricType.receivables;

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
                // Glowing Top Indicator Strip
                Container(
                  height: 3.5,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.accentColor,
                        widget.accentColor.withValues(alpha: 0.25),
                      ],
                    ),
                  ),
                ),

              // Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: widget.accentColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _metricIcon,
                        size: 20,
                        color: widget.accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
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
                            _defaultTimeFrame,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: textMuted,
                      hoverColor: widget.accentColor.withValues(alpha: 0.1),
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
                      // Precise Value Banner Card
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
                                    'UNAGGREGATED PRECISE AMOUNT',
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
                                if (widget.changePercent != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (widget.changePercent! >= 0
                                              ? const Color(0xFF22C55E)
                                              : const Color(0xFFEF4444))
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: (widget.changePercent! >= 0
                                                ? const Color(0xFF22C55E)
                                                : const Color(0xFFEF4444))
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          widget.changePercent! >= 0
                                              ? Icons.arrow_upward_rounded
                                              : Icons.arrow_downward_rounded,
                                          size: 11,
                                          color: widget.changePercent! >= 0
                                              ? const Color(0xFF22C55E)
                                              : const Color(0xFFEF4444),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${widget.changePercent! >= 0 ? '+' : ''}${widget.changePercent!.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: widget.changePercent! >= 0
                                                ? const Color(0xFF22C55E)
                                                : const Color(0xFFEF4444),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (widget.caption != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: widget.accentColor
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: widget.accentColor
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      widget.caption!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: widget.accentColor,
                                      ),
                                    ),
                                  ),
                                ],
                                if (widget.badgeText != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFEF4444)
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      widget.badgeText!,
                                      style: const TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFEF4444),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: SelectableText(
                                  Formatters.currencyFull(
                                      widget.preciseAmount),
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: widget.accentColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Interactive Graph Section
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isReceivables
                                  ? 'AGE BREAKDOWN DISTRIBUTION'
                                  : 'HISTORICAL PERFORMANCE TREND',
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
                          if (_hoveredPointIndex != null &&
                              _hoveredPointIndex! < widget.trendPoints.length) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: widget.accentColor
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${widget.trendPoints[_hoveredPointIndex!].label}: ${Formatters.currencyFull(widget.trendPoints[_hoveredPointIndex!].value)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: widget.accentColor,
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
                              onHover: (event) => _handlePointerScrub(
                                  event.localPosition, boxSize),
                              onExit: (_) =>
                                  setState(() => _hoveredPointIndex = null),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (details) => _handlePointerScrub(
                                    details.localPosition, boxSize),
                                onPanStart: (details) => _handlePointerScrub(
                                    details.localPosition, boxSize),
                                onPanUpdate: (details) => _handlePointerScrub(
                                    details.localPosition, boxSize),
                                onPanEnd: (_) =>
                                    setState(() => _hoveredPointIndex = null),
                                child: AnimatedBuilder(
                                  animation: _revealAnim,
                                  builder: (context, _) {
                                    return CustomPaint(
                                      size: Size.infinite,
                                      painter: _FinancialChartPainter(
                                        points: widget.trendPoints,
                                        accentColor: widget.accentColor,
                                        isBarChart: isReceivables,
                                        hoveredIndex: _hoveredPointIndex,
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

                      // Breakdown & Sub-metrics Grid
                      if (widget.breakdownItems != null &&
                          widget.breakdownItems!.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          'KEY COMPONENT BREAKDOWN',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: textMuted,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisExtent: 78,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: widget.breakdownItems!.length,
                          itemBuilder: (context, index) {
                            final item = widget.breakdownItems![index];
                            final itemColor = item.color ?? widget.accentColor;
                            return Container(
                              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: borderColor,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      if (item.icon != null) ...[
                                        Icon(item.icon,
                                            size: 14, color: itemColor),
                                        const SizedBox(width: 6),
                                      ],
                                      Expanded(
                                        child: Text(
                                          item.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: textMuted,
                                          ),
                                        ),
                                      ),
                                      if (item.percentage != null) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: itemColor
                                                .withValues(alpha: 0.14),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: Text(
                                            item.percentage!,
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: itemColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        Formatters.currencyFull(item.amount),
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, thickness: 1),

              // Action Buttons Row
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

class _FinancialChartPainter extends CustomPainter {
  _FinancialChartPainter({
    required this.points,
    required this.accentColor,
    required this.isBarChart,
    required this.hoveredIndex,
    required this.progress,
    required this.isDark,
  });

  final List<FinancialTrendPoint> points;
  final Color accentColor;
  final bool isBarChart;
  final int? hoveredIndex;
  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final axisPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const topPadding = 20.0;
    const bottomPadding = 28.0;
    final chartHeight = size.height - topPadding - bottomPadding;
    final chartWidth = size.width;

    // Grid lines
    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (chartHeight / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    final maxVal = points.map((e) => e.value).reduce(math.max);
    final minVal = points.map((e) => e.value).reduce(math.min);
    final effectiveMax = maxVal == 0 ? 1.0 : maxVal * 1.15;
    final effectiveMin = minVal < 0 ? minVal * 1.15 : 0.0;
    final valRange = (effectiveMax - effectiveMin) == 0
        ? 1.0
        : (effectiveMax - effectiveMin);

    if (isBarChart) {
      _paintBarChart(
        canvas,
        size,
        chartWidth,
        chartHeight,
        topPadding,
        bottomPadding,
        effectiveMin,
        valRange,
      );
    } else {
      _paintLineChart(
        canvas,
        size,
        chartWidth,
        chartHeight,
        topPadding,
        bottomPadding,
        effectiveMin,
        valRange,
      );
    }

    // X-Axis Baseline
    final baselineY = topPadding +
        chartHeight -
        ((0 - effectiveMin) / valRange) * chartHeight;
    canvas.drawLine(
      Offset(0, baselineY.clamp(topPadding, size.height - bottomPadding)),
      Offset(
          chartWidth, baselineY.clamp(topPadding, size.height - bottomPadding)),
      axisPaint,
    );
  }

  void _paintBarChart(
    Canvas canvas,
    Size size,
    double width,
    double height,
    double topPadding,
    double bottomPadding,
    double minVal,
    double range,
  ) {
    final barGroupWidth = width / points.length;
    final barWidth = (barGroupWidth * 0.45).clamp(16.0, 36.0);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final cx = (i * barGroupWidth) + (barGroupWidth / 2);
      final normalized = ((point.value - minVal) / range).clamp(0.0, 1.0);
      final barH = height * normalized * progress;
      final topY = topPadding + height - barH;

      final isHovered = hoveredIndex == i;
      final barColor = isHovered
          ? accentColor
          : (point.value > 200000 && accentColor == const Color(0xFFF59E0B)
              ? const Color(0xFFEF4444)
              : accentColor);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
            cx - (barWidth / 2), topY, cx + (barWidth / 2), topPadding + height),
        const Radius.circular(6),
      );

      // Gradient bar paint
      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            barColor,
            barColor.withValues(alpha: 0.35),
          ],
        ).createShader(rect.outerRect);

      canvas.drawRRect(rect, barPaint);

      // Label on top of bar
      textPainter.text = TextSpan(
        text: Formatters.currencyCompact(point.value),
        style: TextStyle(
          color: isHovered
              ? barColor
              : (isDark ? Colors.white70 : Colors.black87),
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(cx - (textPainter.width / 2), math.max(2.0, topY - 14)),
      );

      // X Label
      textPainter.text = TextSpan(
        text: point.label,
        style: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(cx - (textPainter.width / 2), size.height - 20),
      );
    }
  }

  void _paintLineChart(
    Canvas canvas,
    Size size,
    double width,
    double height,
    double topPadding,
    double bottomPadding,
    double minVal,
    double range,
  ) {
    final step = points.length > 1 ? width / (points.length - 1) : width;
    final path = Path();
    final fillPath = Path();

    final offsets = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final normalized = ((points[i].value - minVal) / range).clamp(0.0, 1.0);
      final x = i * step;
      final y = topPadding + height - (height * normalized * progress);
      offsets.add(Offset(x, y));
    }

    if (offsets.length >= 2) {
      path.moveTo(offsets[0].dx, offsets[0].dy);
      fillPath.moveTo(offsets[0].dx, topPadding + height);
      fillPath.lineTo(offsets[0].dx, offsets[0].dy);

      for (int i = 0; i < offsets.length - 1; i++) {
        final p0 = offsets[i];
        final p1 = offsets[i + 1];
        final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY1 = p0.dy;
        final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY2 = p1.dy;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
        fillPath.cubicTo(
            controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
      }

      fillPath.lineTo(offsets.last.dx, topPadding + height);
      fillPath.close();

      // Draw Gradient Area Fill
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor.withValues(alpha: 0.28),
            accentColor.withValues(alpha: 0.0),
          ],
        ).createShader(
            Rect.fromLTRB(0, topPadding, width, topPadding + height));

      canvas.drawPath(fillPath, fillPaint);

      // Draw Curved Line
      final linePaint = Paint()
        ..color = accentColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, linePaint);
    }

    // Draw Points & Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < offsets.length; i++) {
      final off = offsets[i];
      final isHovered = hoveredIndex == i;

      final pointPaint = Paint()
        ..color = isHovered ? Colors.white : accentColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(off, isHovered ? 5.5 : 3.5, pointPaint);

      if (isHovered) {
        final ringPaint = Paint()
          ..color = accentColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(off, 7.5, ringPaint);
      }

      // X Label
      textPainter.text = TextSpan(
        text: points[i].label,
        style: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          fontSize: 10,
          fontWeight: isHovered ? FontWeight.w800 : FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(off.dx - (textPainter.width / 2), size.height - 20),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FinancialChartPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor;
  }
}
