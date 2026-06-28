import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/expense_summary_report.dart';
import '../job_work/job_work_detail_row.dart';
import '../job_work/job_work_detail_section.dart';

class ExpenseSummaryCategorySection extends StatelessWidget {
  const ExpenseSummaryCategorySection({
    required this.report,
    super.key,
  });

  final ExpenseSummaryReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return JobWorkDetailSection(
      title: AppStrings.expensesByCategory,
      icon: Icons.pie_chart_outline_rounded,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: report.categoryTotals.isEmpty
            ? Text(
                AppStrings.noExpensesThisMonth,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.35,
                  color: muted,
                ),
              )
            : JobWorkDetailRows(
                rows: [
                  for (final entry in report.categoryTotals)
                    JobWorkDetailRow(
                      label: entry.$1.label,
                      value: Formatters.currencyPkr(entry.$2),
                    ),
                  JobWorkDetailRow(
                    label: AppStrings.totalExpenses,
                    value: Formatters.currencyPkr(report.totalExpenses),
                    bold: true,
                    highlight: true,
                  ),
                ],
              ),
      ),
    );
  }
}
