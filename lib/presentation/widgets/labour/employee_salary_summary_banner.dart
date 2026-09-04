import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/employee.dart';
import '../../../domain/entities/monthly_ledger.dart';
import '../../../domain/enums/labour_enums.dart';
import '../dashboard/dashboard_surface.dart';
import 'monthly_ledger_status_badge.dart';

class EmployeeSalarySummaryBanner extends StatelessWidget {
  const EmployeeSalarySummaryBanner({
    required this.employee,
    this.ledger,
    this.monthKey,
    this.onRecordPayment,
    this.onViewHistory,
    this.onCloseCycle,
    this.onReopenCycle,
    this.onRefreshPayable,
    this.isBusy = false,
    super.key,
  });

  final Employee employee;
  final MonthlyLedger? ledger;
  final String? monthKey;
  final VoidCallback? onRecordPayment;
  final VoidCallback? onViewHistory;
  final VoidCallback? onCloseCycle;
  final VoidCallback? onReopenCycle;
  final VoidCallback? onRefreshPayable;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payable = ledger?.totalPayable ?? employee.rateAmount;
    final paid = ledger?.totalPaid ?? 0;
    final remaining = ledger?.remainingBalance ?? payable;
    final remainingColor = remaining < -0.005
        ? AppColors.error
        : remaining > 0.005
            ? AppColors.warning
            : AppColors.success;
    final key = monthKey ?? ledger?.monthKey;
    final title = key == null
        ? AppStrings.salaryThisMonth
        : '${AppStrings.salaryThisMonth} · ${DateKeys.monthLabel(key)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DashboardSurfaceCard(
        compact: true,
        borderRadius: 14,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                if (ledger != null) MonthlyLedgerStatusBadge(ledger: ledger!),
                if (onRefreshPayable != null &&
                    employee.salaryType == SalaryType.dailyRate &&
                    ledger?.isClosed != true) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: AppStrings.refreshWagePayable,
                    onPressed: isBusy ? null : onRefreshPayable,
                    icon: const Icon(Icons.refresh, size: 18),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SalaryMetricCard(
                    label: AppStrings.totalSalaryDue,
                    value: Formatters.currencyPkr(payable),
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SalaryMetricCard(
                    label: AppStrings.totalPaidToDate,
                    value: Formatters.currencyPkr(paid),
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SalaryMetricCard(
                    label: remaining < -0.005
                        ? AppStrings.overpaidBalance
                        : AppStrings.remainingBalance,
                    value: Formatters.currencyPkr(remaining.abs()),
                    color: remainingColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onRecordPayment != null)
                  FilledButton.icon(
                    onPressed: isBusy ? null : onRecordPayment,
                    icon: const Icon(Icons.payments_outlined, size: 16),
                    label: const Text(
                      AppStrings.recordWagePayment,
                      style: TextStyle(fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                if (onViewHistory != null)
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onViewHistory,
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text(
                      AppStrings.monthlyLedgers,
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                if (onCloseCycle != null)
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onCloseCycle,
                    icon: const Icon(Icons.lock_outline, size: 16),
                    label: const Text(
                      AppStrings.closeMonthCycle,
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                if (onReopenCycle != null)
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onReopenCycle,
                    icon: const Icon(Icons.lock_open_outlined, size: 16),
                    label: const Text(
                      AppStrings.reopenMonthCycle,
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SalaryMetricCard extends StatelessWidget {
  const _SalaryMetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
