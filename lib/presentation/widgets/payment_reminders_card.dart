import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/job_work_invoice_repository.dart';
import '../../data/services/payment_due_scanner_service.dart';

class PaymentRemindersCard extends StatelessWidget {
  const PaymentRemindersCard({required this.factoryId, super.key});

  final String factoryId;

  @override
  Widget build(BuildContext context) {
    final invoiceRepository = getIt<JobWorkInvoiceRepository>();
    final scanner = getIt<PaymentDueScannerService>();

    return StreamBuilder(
      stream: invoiceRepository.watchOpenInvoicesForFactory(factoryId),
      builder: (context, snapshot) {
        final invoices = snapshot.data ?? const [];
        final summary = scanner.summarize(invoices);

        if (!summary.hasAlerts) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No payment dues or overdues this week.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.paymentReminders,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        label: AppStrings.dueThisWeek,
                        count: summary.dueThisWeekCount,
                        amount: summary.dueThisWeekAmount,
                        color: AppColors.dueSoon,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryTile(
                        label: AppStrings.overduePayments,
                        count: summary.overdueCount,
                        amount: summary.overdueAmount,
                        color: AppColors.overdue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.count,
    required this.amount,
    required this.color,
  });

  final String label;
  final int count;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            Formatters.currencyPkr(amount),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
