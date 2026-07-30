import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';

/// Slim financial strip — label over compact amount, stays readable for large totals.
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
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.3 : 0.4);
    final muted = theme.colorScheme.onSurfaceVariant;
    final divider = outline.withValues(alpha: 0.65);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: outline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(
                child: _MetricCell(
                  label: AppStrings.invoicedShort,
                  value: invoiced,
                  color: isDark ? _invoiced : const Color(0xFFB45309),
                  muted: muted,
                ),
              ),
              Container(width: 1, height: 22, color: divider),
              Expanded(
                child: _MetricCell(
                  label: AppStrings.receivedShort,
                  value: received,
                  color: _received,
                  muted: muted,
                ),
              ),
              Container(width: 1, height: 22, color: divider),
              Expanded(
                child: _MetricCell(
                  label: AppStrings.pendingShort,
                  value: pending,
                  color: _pending,
                  muted: muted,
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
    required this.muted,
  });

  final String label;
  final double value;
  final Color color;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: Formatters.currencyPkr(value),
      waitDuration: const Duration(milliseconds: 400),
      child: Padding(
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
                color: muted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                Formatters.currencyCompact(value),
                maxLines: 1,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
