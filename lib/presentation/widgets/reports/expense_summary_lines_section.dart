import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/expense_summary_report.dart';
import '../expenses/expense_category_chip.dart';
import '../job_work/job_work_detail_section.dart';

class ExpenseSummaryLinesSection extends StatelessWidget {
  const ExpenseSummaryLinesSection({
    required this.report,
    super.key,
  });

  final ExpenseSummaryReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return JobWorkDetailSection(
      title: AppStrings.expenseDetails,
      icon: Icons.list_alt_rounded,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: report.lines.isEmpty
            ? Text(
                AppStrings.noExpensesThisMonth,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.35,
                  color: muted,
                ),
              )
            : Column(
                children: [
                  for (var i = 0; i < report.lines.length; i++) ...[
                    _ExpenseSummaryLineRow(line: report.lines[i]),
                    if (i < report.lines.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ExpenseSummaryLineRow extends StatelessWidget {
  const _ExpenseSummaryLineRow({required this.line});

  final ExpenseSummaryLine line;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    const accent = AppColors.warning;
    final dateLabel = DateFormat.yMMMd().format(line.expense.expenseDate);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 16,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.expense.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ExpenseCategoryChip(category: line.category, compact: true),
                    Text(
                      dateLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: muted,
                            fontSize: 10,
                            height: 1.2,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Formatters.currencyPkr(line.amount),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: accent,
                ),
          ),
        ],
      ),
    );
  }
}
