import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/job_work_invoice_repository.dart';
import '../../data/repositories/sales_invoice_repository.dart';
import '../../data/services/notification_engine_service.dart';
import '../../data/services/payment_due_scanner_service.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/enums/notification_enums.dart';
import '../routes/route_paths.dart';

class PaymentRemindersCard extends StatelessWidget {
  const PaymentRemindersCard({required this.factoryId, super.key});

  final String factoryId;

  @override
  Widget build(BuildContext context) {
    final jobWorkInvoiceRepository = getIt<JobWorkInvoiceRepository>();
    final salesInvoiceRepository = getIt<SalesInvoiceRepository>();
    final scanner = getIt<PaymentDueScannerService>();

    return StreamBuilder<List<JobWorkInvoice>>(
      stream: jobWorkInvoiceRepository.watchOpenInvoicesForFactory(factoryId),
      builder: (context, jobWorkSnapshot) {
        return StreamBuilder<List<SalesInvoice>>(
          stream: salesInvoiceRepository.watchOpenInvoicesForFactory(factoryId),
          builder: (context, salesSnapshot) {
            final summary = scanner.summarizeAll(
              jobWorkInvoices: jobWorkSnapshot.data ?? const [],
              salesInvoices: salesSnapshot.data ?? const [],
            );

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
                            onTap: () => _openNotifications(
                              context,
                              NotificationFilter.dueThisWeek,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryTile(
                            label: AppStrings.overduePayments,
                            count: summary.overdueCount,
                            amount: summary.overdueAmount,
                            color: AppColors.overdue,
                            onTap: () => _openNotifications(
                              context,
                              NotificationFilter.overdue,
                            ),
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
      },
    );
  }

  Future<void> _openNotifications(
    BuildContext context,
    NotificationFilter filter,
  ) async {
    await getIt<NotificationEngineService>().scan(factoryId);
    if (!context.mounted) return;
    await context.push(RoutePaths.notificationsWithFilter(filter));
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.count,
    required this.amount,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final double amount;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: color),
                ],
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
        ),
      ),
    );
  }
}
