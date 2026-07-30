import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/dashboard_kpis.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/extensions/app_user_permissions.dart';
import '../../routes/route_paths.dart';

/// Daily income, expenses, and net — single elegant row.
class DashboardDailyFinanceCard extends StatelessWidget {
  const DashboardDailyFinanceCard({
    required this.kpis,
    required this.user,
    super.key,
  });

  final DashboardKpis kpis;
  final AppUser? user;

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

  void _openIncome(BuildContext context) {
    if (user?.canView(AppModule.plReport) == true) {
      context.push(RoutePaths.plReport);
      return;
    }
    if (user?.canView(AppModule.sales) == true) {
      context.go(RoutePaths.sales);
      return;
    }
    if (user?.canView(AppModule.jobWork) == true) {
      context.go(RoutePaths.jobWork);
    }
  }

  void _openExpenses(BuildContext context) {
    context.push(RoutePaths.expenses);
  }

  void _openNet(BuildContext context) {
    if (user?.canView(AppModule.plReport) == true) {
      context.push(RoutePaths.plReport);
      return;
    }
    _openIncome(context);
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
    final net = kpis.netCashflowToday;
    final netAccent = net > 0
        ? _income
        : (net < 0 ? _expense : _netBlue);

    final cells = <Widget>[
      if (showIncome)
        _MetricCell(
          label: AppStrings.dailyIncomeShort,
          amount: kpis.revenueToday,
          accent: _income,
          changePercent: kpis.revenueDayOverDayPercent,
          risingIsPositive: true,
          onTap: () => _openIncome(context),
        ),
      if (showExpenses)
        _MetricCell(
          label: AppStrings.dailyExpensesShort,
          amount: kpis.expensesToday,
          accent: _expense,
          changePercent: kpis.expensesDayOverDayPercent,
          risingIsPositive: false,
          onTap: () => _openExpenses(context),
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
          onTap: () => _openNet(context),
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
              Text(
                AppStrings.today,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        DecoratedBox(
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
          child: IntrinsicHeight(
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
      ],
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.amount,
    required this.accent,
    required this.risingIsPositive,
    required this.onTap,
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
  final VoidCallback onTap;

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
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
        ),
      ),
    );
  }
}
