import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/monthly_pl_report.dart';
import '../job_work/job_work_detail_row.dart';
import '../job_work/job_work_detail_section.dart';

class PlReportExpensesSection extends StatelessWidget {
  const PlReportExpensesSection({
    required this.report,
    super.key,
  });

  final MonthlyPlReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return JobWorkDetailSection(
      title: AppStrings.expenses,
      icon: Icons.receipt_long_outlined,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report.expenseLines.isEmpty)
              Text(
                AppStrings.noExpensesThisMonth,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.35,
                  color: muted,
                ),
              ),
            JobWorkDetailRows(
              rows: [
                for (final line in report.expenseLines)
                  JobWorkDetailRow(
                    label: line.label,
                    value: Formatters.currencyPkr(line.amount),
                  ),
                JobWorkDetailRow(
                  label: AppStrings.totalExpenses,
                  value: Formatters.currencyPkr(report.totalExpenses),
                  bold: true,
                  highlight: report.totalExpenses > 0,
                ),
              ],
            ),
            if (report.expenseCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${report.expenseCount} ${AppStrings.expenseEntriesThisMonth}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
