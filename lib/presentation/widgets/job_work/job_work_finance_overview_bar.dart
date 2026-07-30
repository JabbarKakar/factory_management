import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';

/// Compact single-row financial rollup across visible Job Work orders.
class JobWorkFinanceOverviewBar extends StatelessWidget {
  const JobWorkFinanceOverviewBar({
    required this.invoiced,
    required this.received,
    required this.pending,
    super.key,
  });

  final double invoiced;
  final double received;
  final double pending;

  static const Color _cardBgDark = Color(0xFF121826);
  static const Color _cardBgLight = Color(0xFFF0F2F5);
  static const Color _invoiced = Color(0xFFFDD343);
  static const Color _received = Color(0xFF22C55E);
  static const Color _pending = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? _cardBgDark : _cardBgLight;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    final labelColor = theme.colorScheme.onSurfaceVariant;
    final divider = outline.withValues(alpha: isDark ? 0.55 : 0.7);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: outline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _MetricCell(
                  label: AppStrings.totalInvoiced,
                  value: invoiced,
                  color: isDark ? _invoiced : const Color(0xFFB45309),
                  labelColor: labelColor,
                ),
              ),
              Container(width: 1, height: 28, color: divider),
              Expanded(
                child: _MetricCell(
                  label: AppStrings.totalReceived,
                  value: received,
                  color: _received,
                  labelColor: labelColor,
                ),
              ),
              Container(width: 1, height: 28, color: divider),
              Expanded(
                child: _MetricCell(
                  label: AppStrings.totalPending,
                  value: pending,
                  color: _pending,
                  labelColor: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    required this.color,
    required this.labelColor,
  });

  final String label;
  final double value;
  final Color color;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: labelColor,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              Formatters.currencyPkrWhole(value),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
