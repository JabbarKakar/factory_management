import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/dashboard_analytics.dart';

class DashboardRevenueChartCard extends StatelessWidget {
  const DashboardRevenueChartCard({
    required this.points,
    super.key,
  });

  final List<DailyRevenuePoint> points;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.revenueChartTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.revenueChartSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            if (!points.any((point) => point.totalAmount > 0))
              _EmptyChartHint(message: AppStrings.revenueChartEmpty)
            else ...[
              SizedBox(
                height: 220,
                child: LineChart(_buildChartData(context)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: const [
                  _LegendDot(
                    color: AppColors.primary,
                    label: AppStrings.salesRevenueSeries,
                  ),
                  _LegendDot(
                    color: AppColors.accent,
                    label: AppStrings.jobWorkRevenueSeries,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData(BuildContext context) {
    final salesSpots = <FlSpot>[];
    final jobWorkSpots = <FlSpot>[];
    for (var index = 0; index < points.length; index++) {
      final x = index.toDouble();
      salesSpots.add(FlSpot(x, points[index].salesAmount));
      jobWorkSpots.add(FlSpot(x, points[index].jobWorkAmount));
    }

    final maxY = points
        .map((point) => point.totalAmount)
        .fold<double>(0, (max, value) => value > max ? value : max);
    final chartMaxY = maxY <= 0 ? 10000.0 : maxY * 1.15;

    return LineChartData(
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: 0,
      maxY: chartMaxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: chartMaxY / 4,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 52,
            getTitlesWidget: (value, meta) {
              if (value == meta.max || value == meta.min) {
                return const SizedBox.shrink();
              }
              return Text(
                _compactCurrency(value),
                style: Theme.of(context).textTheme.labelSmall,
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 5,
            getTitlesWidget: (value, meta) {
              final index = value.round();
              if (index < 0 || index >= points.length || index % 5 != 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  DateFormat.Md().format(points[index].date),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.round();
              if (index < 0 || index >= points.length) return null;
              final point = points[index];
              final isSales = spot.barIndex == 0;
              final label = isSales
                  ? AppStrings.salesRevenueSeries
                  : AppStrings.jobWorkRevenueSeries;
              final amount =
                  isSales ? point.salesAmount : point.jobWorkAmount;
              return LineTooltipItem(
                '${DateFormat.yMMMd().format(point.date)}\n$label: ${Formatters.currencyPkr(amount)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: salesSpots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: jobWorkSpots,
          isCurved: true,
          color: AppColors.accent,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }

  String _compactCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
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
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _EmptyChartHint extends StatelessWidget {
  const _EmptyChartHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ),
    );
  }
}
