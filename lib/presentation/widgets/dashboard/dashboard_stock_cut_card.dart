import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/dashboard_stock_cut_metrics.dart';
import '../../../domain/enums/dashboard_finance_period.dart';
import '../dialogs/app_dialog.dart';

/// Period-aware small / large / total stock cut (sq. ft) — mirrors Cashflow card.
class DashboardStockCutCard extends StatelessWidget {
  const DashboardStockCutCard({
    required this.metrics,
    required this.period,
    required this.onPeriodChanged,
    super.key,
  });

  final DashboardStockCutMetrics metrics;
  final DashboardFinancePeriod period;
  final ValueChanged<DashboardFinancePeriod> onPeriodChanged;

  static const Color _panelDark = Color(0xFF121826);
  static const Color _panelLight = Color(0xFFF3F5F8);
  static const Color _small = Color(0xFF38BDF8);
  static const Color _large = Color(0xFFF59E0B);
  static const Color _total = Color(0xFF22C55E);

  static final NumberFormat _sqFtFormat = NumberFormat('#,##0.##');

  static String formatSqFt(double value) => '${_sqFtFormat.format(value)} sq ft';

  static String formatSqFtCompact(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M sq ft';
    }
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K sq ft';
    }
    return formatSqFt(value);
  }

  Future<void> _showDetails(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    final panelBg = isDark
        ? const Color(0xFF1B2230)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final vsLabel = period.vsPreviousLabel;

    return AppDialog.show(
      context,
      child: Builder(
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: theme.colorScheme.surface,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: outline),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _small.withValues(alpha: 0.28),
                                _large.withValues(alpha: 0.12),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _small.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            Icons.content_cut_outlined,
                            size: 20,
                            color: isDark ? _small : const Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${AppStrings.stockCutTitle} · ${period.label}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  height: 1.2,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                AppStrings.stockCutSubtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: panelBg,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: outline.withValues(alpha: 0.55)),
                      ),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.grid_view_outlined,
                            label: AppStrings.smallStock,
                            value: formatSqFt(metrics.smallSqFt),
                            color: _small,
                            caption: _changeCaption(
                              metrics.smallChangePercent,
                              vsLabel,
                            ),
                          ),
                          Divider(
                            height: 1,
                            indent: 14,
                            endIndent: 14,
                            color: outline.withValues(alpha: 0.45),
                          ),
                          _DetailRow(
                            icon: Icons.crop_landscape_outlined,
                            label: AppStrings.largeStock,
                            value: formatSqFt(metrics.largeSqFt),
                            color: _large,
                            caption: _changeCaption(
                              metrics.largeChangePercent,
                              vsLabel,
                            ),
                          ),
                          Divider(
                            height: 1,
                            indent: 14,
                            endIndent: 14,
                            color: outline.withValues(alpha: 0.45),
                          ),
                          _DetailRow(
                            icon: Icons.summarize_outlined,
                            label: AppStrings.stockCutTotal,
                            value: formatSqFt(metrics.totalSqFt),
                            color: _total,
                            caption: AppStrings.stockCutTotalSubtitle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(AppStrings.close),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _changeCaption(double? change, String vsLabel) {
    if (period == DashboardFinancePeriod.allTime) {
      return AppStrings.stockCutAllTimeCaption;
    }
    if (change == null) return '${AppStrings.vsYesterdayNa} $vsLabel';
    return AppStrings.vsPeriodPercent(
      '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}',
      vsLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final panelBg = isDark ? _panelDark : _panelLight;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.32 : 0.4);

    final cells = <Widget>[
      _MetricCell(
        label: AppStrings.smallStock,
        valueText: formatSqFtCompact(metrics.smallSqFt),
        accent: _small,
        changePercent: period == DashboardFinancePeriod.allTime
            ? null
            : metrics.smallChangePercent,
      ),
      _MetricCell(
        label: AppStrings.largeStock,
        valueText: formatSqFtCompact(metrics.largeSqFt),
        accent: _large,
        changePercent: period == DashboardFinancePeriod.allTime
            ? null
            : metrics.largeChangePercent,
      ),
      _MetricCell(
        label: AppStrings.stockCutTotalShort,
        valueText: formatSqFtCompact(metrics.totalSqFt),
        accent: _total,
        changePercent: period == DashboardFinancePeriod.allTime
            ? null
            : metrics.totalChangePercent,
        footnote: AppStrings.stockCutTotalSubtitle,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _small.withValues(alpha: isDark ? 0.28 : 0.18),
                      _large.withValues(alpha: isDark ? 0.18 : 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.content_cut_outlined,
                  size: 15,
                  color: isDark ? _small : const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.stockCutTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    letterSpacing: -0.2,
                    height: 1.15,
                  ),
                ),
              ),
              _PeriodSelector(
                period: period,
                isDark: isDark,
                onChanged: onPeriodChanged,
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showDetails(context),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                color: panelBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: outline),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: IntrinsicHeight(
                  key: ValueKey(period),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < cells.length; i++) ...[
                        if (i > 0)
                          VerticalDivider(
                            width: 1,
                            thickness: 1,
                            indent: 12,
                            endIndent: 12,
                            color: outline.withValues(alpha: 0.85),
                          ),
                        Expanded(child: cells[i]),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.period,
    required this.isDark,
    required this.onChanged,
  });

  final DashboardFinancePeriod period;
  final bool isDark;
  final ValueChanged<DashboardFinancePeriod> onChanged;

  static const Color _inputDark = Color(0xFF151F33);
  static const Color _accentGold = Color(0xFFFDD343);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isDark ? _inputDark : theme.colorScheme.surfaceContainerHighest;
    final border = isDark
        ? _accentGold.withValues(alpha: 0.35)
        : theme.colorScheme.outline.withValues(alpha: 0.45);
    final fg = isDark ? _accentGold : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<DashboardFinancePeriod>(
        tooltip: AppStrings.selectPeriod,
        initialValue: period,
        onSelected: onChanged,
        offset: const Offset(0, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark
                ? _accentGold.withValues(alpha: 0.2)
                : theme.colorScheme.outline.withValues(alpha: 0.35),
          ),
        ),
        color: isDark ? _inputDark : theme.colorScheme.surface,
        itemBuilder: (context) {
          return [
            for (final option in DashboardFinancePeriod.values)
              PopupMenuItem<DashboardFinancePeriod>(
                value: option,
                child: Row(
                  children: [
                    Icon(
                      option == period
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 16,
                      color: option == period
                          ? (isDark ? _accentGold : theme.colorScheme.primary)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      option.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight:
                            option == period ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12.5,
                        color: option == period
                            ? (isDark ? _accentGold : theme.colorScheme.primary)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
          ];
        },
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  period.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.valueText,
    required this.accent,
    this.changePercent,
    this.footnote,
  });

  final String label;
  final String valueText;
  final Color accent;
  final double? changePercent;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final change = changePercent;

    final trendColor = () {
      if (change == null || change == 0) return muted;
      return change > 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    }();

    final trendIcon = change == null
        ? null
        : (change == 0
            ? Icons.remove_rounded
            : (change > 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded));

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 3,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.45),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: muted,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.2,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valueText,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                letterSpacing: -0.3,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 5),
          if (trendIcon != null && change != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(trendIcon, size: 12, color: trendColor),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    change == 0
                        ? '0%'
                        : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(0)}%',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: trendColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 9.5,
                      height: 1,
                    ),
                  ),
                ),
              ],
            )
          else if (footnote != null)
            Text(
              footnote!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: muted,
                fontWeight: FontWeight.w600,
                fontSize: 9,
                height: 1.1,
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: muted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
