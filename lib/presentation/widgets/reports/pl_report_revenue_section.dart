import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/monthly_pl_report.dart';
import '../job_work/job_work_detail_row.dart';
import '../job_work/job_work_detail_section.dart';

class PlReportRevenueSection extends StatelessWidget {
  const PlReportRevenueSection({
    required this.report,
    super.key,
  });

  final MonthlyPlReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return JobWorkDetailSection(
      title: AppStrings.revenue,
      icon: Icons.payments_outlined,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JobWorkDetailRows(
              rows: [
                JobWorkDetailRow(
                  label: AppStrings.salesRevenue,
                  value: Formatters.currencyPkr(report.salesRevenue),
                ),
                JobWorkDetailRow(
                  label: AppStrings.jobWorkRevenue,
                  value: Formatters.currencyPkr(report.jobWorkRevenue),
                ),
                JobWorkDetailRow(
                  label: AppStrings.totalRevenue,
                  value: Formatters.currencyPkr(report.totalRevenue),
                  bold: true,
                  highlight: report.totalRevenue > 0,
                ),
              ],
            ),
            if (report.paymentCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${report.paymentCount} ${AppStrings.paymentsRecorded}',
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
