import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/supplier_statement.dart';
import '../../../domain/enums/customer_enums.dart';
import '../customers/customer_balance_indicator.dart';
import 'supplier_type_chip.dart';

class SupplierStatementDetailHero extends StatelessWidget {
  const SupplierStatementDetailHero({
    required this.statement,
    super.key,
  });

  final SupplierStatement statement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    final accent = _accentFor(statement.balanceStatus);
    final dateFormat = DateFormat.yMMMd();
    const cardShape = BorderRadius.only(
      topRight: Radius.circular(14),
      bottomRight: Radius.circular(14),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: cardShape,
          border: Border.all(color: outline),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statement.supplier.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    SupplierTypeChip(
                                      supplierType:
                                          statement.supplier.supplierType,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      statement.supplier.supplierNumber,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          CustomerBalanceIndicator(
                            status: statement.balanceStatus,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (statement.supplier.phone.isNotEmpty)
                        Text(
                          statement.supplier.phone,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${dateFormat.format(statement.fromDate)} – ${dateFormat.format(statement.toDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: outline.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _KpiMetric(
                              label: AppStrings.openingBalance,
                              value: Formatters.currencyPkr(statement.openingBalance),
                            ),
                          ),
                          Expanded(
                            child: _KpiMetric(
                              label: AppStrings.totalPurchases,
                              value: Formatters.currencyPkr(statement.totalPurchases),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _KpiMetric(
                              label: AppStrings.totalHistoryPaid,
                              value: Formatters.currencyPkr(statement.totalPaid),
                              color: AppColors.success,
                            ),
                          ),
                          Expanded(
                            child: _KpiMetric(
                              label: AppStrings.remainingPayable,
                              value: Formatters.currencyPkr(statement.remainingBalanceDue),
                              color: accent,
                              isLarge: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _accentFor(CustomerBalanceStatus status) {
    return switch (status) {
      CustomerBalanceStatus.paidUp => AppColors.success,
      CustomerBalanceStatus.dueSoon => AppColors.dueSoon,
      CustomerBalanceStatus.dueToday => AppColors.warning,
      CustomerBalanceStatus.overdue => AppColors.overdue,
      CustomerBalanceStatus.outstanding => AppColors.textSecondary,
      CustomerBalanceStatus.inCredit => AppColors.primary,
    };
  }
}

class _KpiMetric extends StatelessWidget {
  const _KpiMetric({
    required this.label,
    required this.value,
    this.color,
    this.isLarge = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: isLarge ? 14 : 12,
            color: color ?? theme.colorScheme.onSurface,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}
