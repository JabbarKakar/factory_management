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
import 'dashboard/dashboard_surface.dart';

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
              return DashboardSurfaceCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All clear',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'No payment dues or overdues this week.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return DashboardSurfaceCard(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardSectionHeader(
                    title: AppStrings.paymentReminders,
                    subtitle: 'Invoices needing attention',
                    icon: Icons.account_balance_wallet_outlined,
                    trailing: DashboardTextLink(
                      label: 'View all',
                      onPressed: () => _openNotifications(
                        context,
                        NotificationFilter.all,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _PaymentMetricCard(
                          label: AppStrings.dueThisWeek,
                          count: summary.dueThisWeekCount,
                          amount: summary.dueThisWeekAmount,
                          color: AppColors.dueSoon,
                          icon: Icons.event_rounded,
                          onTap: () => _openNotifications(
                            context,
                            NotificationFilter.dueThisWeek,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PaymentMetricCard(
                          label: AppStrings.overduePayments,
                          count: summary.overdueCount,
                          amount: summary.overdueAmount,
                          color: AppColors.overdue,
                          icon: Icons.error_outline_rounded,
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

class _PaymentMetricCard extends StatelessWidget {
  const _PaymentMetricCard({
    required this.label,
    required this.count,
    required this.amount,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int count;
  final double amount;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.14),
                color.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$count',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.currencyPkr(amount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
