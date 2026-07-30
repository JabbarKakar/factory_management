import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../dialogs/app_dialog.dart';

/// Slim financial strip — tap to open full-digit breakdown.
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
  static const Color _invoicedLight = Color(0xFFB45309);
  static const Color _received = Color(0xFF22C55E);
  static const Color _pending = Color(0xFFEF4444);

  Future<void> _showDetails(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final invoicedColor = isDark ? _invoiced : _invoicedLight;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    final panelBg = isDark
        ? const Color(0xFF1B2230)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);

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
                                theme.colorScheme.primary
                                    .withValues(alpha: 0.22),
                                theme.colorScheme.primary
                                    .withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.28),
                            ),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.financeOverviewTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  height: 1.2,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                AppStrings.financeOverviewSubtitle,
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
                            icon: Icons.receipt_long_outlined,
                            label: AppStrings.totalInvoiced,
                            value: Formatters.currencyPkr(invoiced),
                            color: invoicedColor,
                          ),
                          Divider(
                            height: 1,
                            indent: 14,
                            endIndent: 14,
                            color: outline.withValues(alpha: 0.45),
                          ),
                          _DetailRow(
                            icon: Icons.payments_outlined,
                            label: AppStrings.totalReceived,
                            value: Formatters.currencyPkr(received),
                            color: _received,
                          ),
                          Divider(
                            height: 1,
                            indent: 14,
                            endIndent: 14,
                            color: outline.withValues(alpha: 0.45),
                          ),
                          _DetailRow(
                            icon: Icons.pending_actions_outlined,
                            label: AppStrings.totalPending,
                            value: Formatters.currencyPkr(pending),
                            color: _pending,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetails(context),
          borderRadius: BorderRadius.circular(8),
          child: Ink(
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
                      color: isDark ? _invoiced : _invoicedLight,
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
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    height: 1.15,
                    letterSpacing: -0.2,
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
