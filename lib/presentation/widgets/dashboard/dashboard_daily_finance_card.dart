import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/dashboard_cashflow_metrics.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/dashboard_finance_period.dart';
import '../../../domain/extensions/app_user_permissions.dart';
import '../dialogs/app_dialog.dart';

/// Period-aware income / expenses / net row — tap for full-digit breakdown.
class DashboardDailyFinanceCard extends StatelessWidget {
  const DashboardDailyFinanceCard({
    required this.metrics,
    required this.period,
    required this.user,
    required this.onPeriodChanged,
    super.key,
  });

  final DashboardCashflowMetrics metrics;
  final DashboardFinancePeriod period;
  final AppUser? user;
  final ValueChanged<DashboardFinancePeriod> onPeriodChanged;

  static const Color _panelDark = Color(0xFF121826);
  static const Color _panelLight = Color(0xFFF3F5F8);
  static const Color _income = Color(0xFF22C55E);
  static const Color _expense = Color(0xFFEF4444);
  static const Color _netBlue = Color(0xFF38BDF8);

  bool get _canViewIncome =>
      user?.canView(AppModule.sales) == true ||
      user?.canView(AppModule.jobWork) == true ||
      user?.canView(AppModule.plReport) == true;

  bool get _canViewExpenses => user?.canView(AppModule.expenses) == true;

  Future<void> _showDetails(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    final panelBg = isDark
        ? const Color(0xFF1B2230)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);

    final showIncome = _canViewIncome;
    final showExpenses = _canViewExpenses;
    final net = metrics.net;
    final netAccent = net > 0
        ? _income
        : (net < 0 ? _expense : _netBlue);
    final netSign = net > 0 ? '+' : '';
    final vsLabel = period.vsPreviousLabel;

    final detailRows = <Widget>[
      if (showIncome)
        _DetailRow(
          icon: Icons.south_west_rounded,
          label: AppStrings.dailyIncomeReceived,
          value: Formatters.currencyPkr(metrics.income),
          color: _income,
          caption: _changeCaption(metrics.incomeChangePercent, vsLabel),
        ),
      if (showIncome && showExpenses)
        Divider(
          height: 1,
          indent: 14,
          endIndent: 14,
          color: outline.withValues(alpha: 0.45),
        ),
      if (showExpenses)
        _DetailRow(
          icon: Icons.north_east_rounded,
          label: AppStrings.dailyExpenses,
          value: Formatters.currencyPkr(metrics.expenses),
          color: _expense,
          caption: _changeCaption(metrics.expensesChangePercent, vsLabel),
        ),
      if (showIncome && showExpenses) ...[
        Divider(
          height: 1,
          indent: 14,
          endIndent: 14,
          color: outline.withValues(alpha: 0.45),
        ),
        _DetailRow(
          icon: Icons.account_balance_outlined,
          label: AppStrings.dailyNet,
          value: '$netSign${Formatters.currencyPkr(net)}',
          color: netAccent,
          caption: AppStrings.dailyNetSubtitle,
        ),
      ],
    ];

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
                                _netBlue.withValues(alpha: 0.28),
                                _income.withValues(alpha: 0.12),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _netBlue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            Icons.bolt_rounded,
                            size: 20,
                            color: isDark ? _netBlue : const Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${AppStrings.dailyFinanceTitle} · ${period.label}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  height: 1.2,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                AppStrings.dailyFinanceSubtitle,
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
                      child: Column(children: detailRows),
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
    if (change == null) return '${AppStrings.vsYesterdayNa} $vsLabel';
    return AppStrings.vsPeriodPercent(
      '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}',
      vsLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showIncome = _canViewIncome;
    final showExpenses = _canViewExpenses;
    if (!showIncome && !showExpenses) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final panelBg = isDark ? _panelDark : _panelLight;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.32 : 0.4);
    final net = metrics.net;
    final netAccent = net > 0
        ? _income
        : (net < 0 ? _expense : _netBlue);

    final cells = <Widget>[
      if (showIncome)
        _MetricCell(
          label: AppStrings.dailyIncomeShort,
          amount: metrics.income,
          accent: _income,
          changePercent: metrics.incomeChangePercent,
          risingIsPositive: true,
        ),
      if (showExpenses)
        _MetricCell(
          label: AppStrings.dailyExpensesShort,
          amount: metrics.expenses,
          accent: _expense,
          changePercent: metrics.expensesChangePercent,
          risingIsPositive: false,
        ),
      if (showIncome && showExpenses)
        _MetricCell(
          label: AppStrings.dailyNetShort,
          amount: net,
          accent: netAccent,
          changePercent: null,
          risingIsPositive: true,
          showSignedAmount: true,
          footnote: AppStrings.dailyNetSubtitle,
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
                      _netBlue.withValues(alpha: isDark ? 0.28 : 0.18),
                      _income.withValues(alpha: isDark ? 0.18 : 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  size: 15,
                  color: isDark ? _netBlue : const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.dailyFinanceTitle,
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
    required this.amount,
    required this.accent,
    required this.risingIsPositive,
    this.changePercent,
    this.showSignedAmount = false,
    this.footnote,
  });

  final String label;
  final double amount;
  final Color accent;
  final double? changePercent;
  final bool risingIsPositive;
  final bool showSignedAmount;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final change = changePercent;

    final trendColor = () {
      if (change == null || change == 0) return muted;
      if (risingIsPositive) {
        return change > 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
      }
      return change > 0 ? const Color(0xFFEF4444) : const Color(0xFF22C55E);
    }();

    final trendIcon = change == null
        ? null
        : (change == 0
            ? Icons.remove_rounded
            : (change > 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded));

    final amountText = showSignedAmount && amount > 0
        ? '+${Formatters.currencyCompact(amount)}'
        : Formatters.currencyCompact(amount);

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
              amountText,
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
                color: muted.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
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
    this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? caption;

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
                if (caption != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    caption!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 10.5,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
