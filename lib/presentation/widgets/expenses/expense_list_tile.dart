import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/enums/expense_enums.dart';
import 'expense_category_chip.dart';
import 'record_expense_payment_dialog.dart';

class ExpenseListTile extends StatelessWidget {
  const ExpenseListTile({
    required this.expense,
    required this.onTap,
    this.onPaymentRecorded,
    super.key,
  });

  final Expense expense;
  final VoidCallback onTap;
  final VoidCallback? onPaymentRecorded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);

    final statusColor = switch (expense.paymentStatus) {
      ExpensePaymentStatus.paid => AppColors.success,
      ExpensePaymentStatus.partiallyPaid => AppColors.warning,
      ExpensePaymentStatus.unpaid => theme.colorScheme.error,
    };

    const cardShape = BorderRadius.only(
      topRight: Radius.circular(14),
      bottomRight: Radius.circular(14),
    );
    final dateLabel = DateFormat.yMMMd().format(expense.expenseDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: cardShape,
          child: Ink(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: cardShape,
              border: Border.all(color: outline),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 3, color: statusColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  expense.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              Text(
                                Formatters.currencyPkr(expense.amount),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ExpenseCategoryChip(
                                category: expense.category,
                                compact: true,
                              ),
                              _StatusBadge(
                                status: expense.paymentStatus,
                                color: statusColor,
                              ),
                              _MetaChip(
                                icon: Icons.calendar_today_outlined,
                                label: dateLabel,
                              ),
                              if (expense.payeeName != null &&
                                  expense.payeeName!.isNotEmpty)
                                _MetaChip(
                                  icon: Icons.person_outline,
                                  label: expense.payeeName!,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_outlined,
                                size: 14,
                                color: muted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  expense.effectiveDueAmount > 0.005
                                      ? '${expense.expenseNumber} · Paid: ${Formatters.currencyPkr(expense.paidAmount)} · Due: ${Formatters.currencyPkr(expense.effectiveDueAmount)}'
                                      : '${expense.expenseNumber} · ${expense.paymentMethod.label}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: expense.effectiveDueAmount > 0.005
                                        ? statusColor
                                        : muted,
                                    fontWeight:
                                        expense.effectiveDueAmount > 0.005
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              if (expense.effectiveDueAmount > 0.005)
                                InkWell(
                                  onTap: () {
                                    RecordExpensePaymentDialog.show(
                                      context,
                                      expense: expense,
                                      onPaymentRecorded: onPaymentRecorded,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.payments_outlined,
                                          size: 12,
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Pay',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: theme.colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: muted.withValues(alpha: 0.7),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.color,
  });

  final ExpensePaymentStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
