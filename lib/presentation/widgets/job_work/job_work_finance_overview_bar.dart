import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../dialogs/app_dialog.dart';

/// Slim financial strip — tap to open full-digit breakdown.
class JobWorkFinanceOverviewBar extends StatelessWidget {
  const JobWorkFinanceOverviewBar({
    required this.invoiced,
    required this.received,
    required this.pending,
    this.credit = 0,
    super.key,
  });

  final double invoiced;
  final double received;
  final double pending;
  final double credit;

  bool get _hasCredit => credit > 0.005;

  static const Color _cardBgDark = Color(0xFF121826);
  static const Color _cardBgLight = Color(0xFFF0F2F5);
  static const Color _invoiced = Color(0xFFFDD343);
  static const Color _invoicedLight = Color(0xFFB45309);
  static const Color _received = AppColors.success;
  static const Color _pending = AppColors.error;

  Future<void> _showDetails(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AppDialog.show(
      context,
      child: _FinanceOverviewDialog(
        invoiced: invoiced,
        received: received,
        pending: pending,
        credit: credit,
        invoicedColor: isDark ? _invoiced : _invoicedLight,
        receivedColor: _received,
        pendingColor: _pending,
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
                  if (_hasCredit) ...[
                    Container(width: 1, height: 22, color: divider),
                    Expanded(
                      child: _MetricCell(
                        label: AppStrings.creditShort,
                        value: credit,
                        color: _received,
                        muted: muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FinanceOverviewDialog extends StatelessWidget {
  const _FinanceOverviewDialog({
    required this.invoiced,
    required this.received,
    required this.pending,
    required this.credit,
    required this.invoicedColor,
    required this.receivedColor,
    required this.pendingColor,
  });

  final double invoiced;
  final double received;
  final double pending;
  final double credit;
  final Color invoicedColor;
  final Color receivedColor;
  final Color pendingColor;

  bool get _hasCredit => credit > 0.005;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    final panelBg = isDark
        ? AppColors.surfaceDarkMuted.withValues(alpha: 0.55)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);

    final rows = <_LedgerRow>[
      _LedgerRow(
        icon: Icons.receipt_long_outlined,
        label: AppStrings.totalInvoiced,
        value: invoiced,
        color: invoicedColor,
      ),
      _LedgerRow(
        icon: Icons.payments_outlined,
        label: AppStrings.totalReceived,
        value: received,
        color: receivedColor,
      ),
      _LedgerRow(
        icon: Icons.pending_actions_outlined,
        label: AppStrings.totalPending,
        value: pending,
        color: pendingColor,
      ),
      if (_hasCredit)
        _LedgerRow(
          icon: Icons.savings_outlined,
          label: AppStrings.totalCredit,
          value: credit,
          color: receivedColor,
        ),
    ];

    return AppDialog(
      title: AppStrings.financeOverviewTitle,
      message: AppStrings.financeOverviewSubtitle,
      icon: Icons.account_balance_wallet_outlined,
      maxWidth: 360,
      content: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: panelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: outline.withValues(alpha: 0.55)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                rows[i],
                if (i < rows.length - 1)
                  Divider(
                    height: 1,
                    indent: 48,
                    endIndent: 12,
                    color: outline.withValues(alpha: 0.4),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        AppDialogActions.confirm(
          context,
          label: AppStrings.close,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: muted,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Formatters.currencyPkr(value),
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              height: 1.15,
              letterSpacing: -0.2,
            ),
          ),
        ],
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
