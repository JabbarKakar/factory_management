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

  static const double _wideBreakpoint = 900;
  static const double _mobileBreakpoint = 600;

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

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isWide = width >= _wideBreakpoint;
                final isMobile = width < _mobileBreakpoint;

                if (!summary.hasAlerts) {
                  return _AllClearState(isMobile: isMobile);
                }

                final dueCard = _PaymentMetricCard(
                  label: AppStrings.dueThisWeek,
                  count: summary.dueThisWeekCount,
                  amount: summary.dueThisWeekAmount,
                  color: AppColors.dueSoon,
                  icon: Icons.event_rounded,
                  dense: isMobile,
                  horizontal: isWide,
                  onTap: () => _openNotifications(
                    context,
                    NotificationFilter.dueThisWeek,
                  ),
                );

                final overdueCard = _PaymentMetricCard(
                  label: AppStrings.overduePayments,
                  count: summary.overdueCount,
                  amount: summary.overdueAmount,
                  color: AppColors.overdue,
                  icon: Icons.error_outline_rounded,
                  dense: isMobile,
                  horizontal: isWide,
                  onTap: () => _openNotifications(
                    context,
                    NotificationFilter.overdue,
                  ),
                );

                final metrics = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: dueCard),
                    SizedBox(width: isMobile ? 6 : 8),
                    Expanded(child: overdueCard),
                  ],
                );

                return DashboardSurfaceCard(
                  compact: true,
                  borderRadius: 14,
                  padding: EdgeInsets.all(isMobile ? 10 : (isWide ? 16 : 12)),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _PaymentRemindersHeader(
                                isMobile: false,
                                onViewAll: () => _openNotifications(
                                  context,
                                  NotificationFilter.all,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(flex: 6, child: metrics),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PaymentRemindersHeader(
                              isMobile: isMobile,
                              onViewAll: () => _openNotifications(
                                context,
                                NotificationFilter.all,
                              ),
                            ),
                            SizedBox(height: isMobile ? 8 : 10),
                            metrics,
                          ],
                        ),
                );
              },
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

class _PaymentRemindersHeader extends StatelessWidget {
  const _PaymentRemindersHeader({
    required this.isMobile,
    required this.onViewAll,
  });

  final bool isMobile;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    if (!isMobile) {
      return DashboardSectionHeader(
        title: AppStrings.paymentReminders,
        subtitle: 'Invoices needing attention',
        icon: Icons.account_balance_wallet_outlined,
        trailing: DashboardTextLink(
          label: 'View all',
          onPressed: onViewAll,
        ),
      );
    }

    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.account_balance_wallet_outlined,
            size: 15,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppStrings.paymentReminders,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        DashboardTextLink(label: 'View all', onPressed: onViewAll),
      ],
    );
  }
}

class _AllClearState extends StatelessWidget {
  const _AllClearState({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const iconSize = 32.0;

    return DashboardSurfaceCard(
      compact: true,
      borderRadius: 14,
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      child: Row(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: AppColors.success,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All clear',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'No payment dues or overdues this week.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    this.dense = false,
    this.horizontal = false,
  });

  final String label;
  final int count;
  final double amount;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final bool dense;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelSize = horizontal ? 11.0 : (dense ? 9.0 : 10.0);
    final countSize = horizontal ? 20.0 : (dense ? 15.0 : 17.0);
    final amountSize = horizontal ? 11.0 : (dense ? 9.0 : 10.0);
    final padding = horizontal ? 12.0 : (dense ? 7.0 : 9.0);
    final iconSize = horizontal ? 16.0 : (dense ? 13.0 : 14.0);

    final labelWidget = Text(
      label,
      maxLines: dense ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: labelSize,
        height: 1.1,
      ),
    );

    final countWidget = Text(
      '$count',
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        fontSize: countSize,
        height: 1,
      ),
    );

    final amountWidget = Text(
      Formatters.currencyPkr(amount),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
        fontSize: amountSize,
        height: 1.1,
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
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
            padding: EdgeInsets.all(padding),
            child: horizontal
                ? Row(
                    children: [
                      Icon(icon, size: iconSize, color: color),
                      const SizedBox(width: 8),
                      Expanded(child: labelWidget),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          countWidget,
                          amountWidget,
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: iconSize, color: color),
                          const SizedBox(width: 4),
                          Expanded(child: labelWidget),
                        ],
                      ),
                      SizedBox(height: dense ? 4 : 6),
                      countWidget,
                      amountWidget,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
