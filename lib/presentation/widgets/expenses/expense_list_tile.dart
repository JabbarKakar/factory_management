import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/expense.dart';
import 'expense_category_chip.dart';

class ExpenseListTile extends StatelessWidget {
  const ExpenseListTile({
    required this.expense,
    required this.onTap,
    super.key,
  });

  final Expense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      expense.description,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Text(
                    Formatters.currencyPkr(expense.amount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ExpenseCategoryChip(category: expense.category, compact: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat.yMMMd().format(expense.expenseDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                    ),
                  ),
                ],
              ),
              if (expense.payeeName != null && expense.payeeName!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  expense.payeeName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: muted,
                      ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '${expense.expenseNumber} · ${expense.paymentMethod.label}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: muted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
