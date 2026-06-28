import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/customer_picker_sheet.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_detail_section.dart';
import '../../widgets/more/more_menu_tile.dart';

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final canViewPl = context.userCanView(AppModule.plReport);
    final canExportCustomers = context.userCanExport(AppModule.customers);
    final canExportExpenses = context.userCanExport(AppModule.expenses);
    final hasAnyReport = canViewPl || canExportCustomers || canExportExpenses;
    final financialCount =
        (canViewPl ? 1 : 0) + (canExportExpenses ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.reportsHub),
            Text(
              AppStrings.reportsHubSubtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: (Theme.of(context).appBarTheme.foregroundColor ??
                            Theme.of(context).colorScheme.onSurface)
                        .withValues(alpha: 0.78),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        children: [
          if (!hasAnyReport)
            const EmptyStateView(
              icon: Icons.lock_outline,
              title: AppStrings.accessDeniedMessage,
            )
          else ...[
            if (financialCount > 0)
              JobWorkDetailSection(
                title: 'Finance',
                icon: Icons.account_balance_wallet_outlined,
                child: _ReportMenuGroup(
                  items: [
                    if (canViewPl)
                      _ReportMenuItem(
                        icon: Icons.assessment_outlined,
                        accentColor: AppColors.primary,
                        title: AppStrings.monthlyPlReport,
                        subtitle: AppStrings.plReportSubtitle,
                        onTap: () => context.push(RoutePaths.plReport),
                      ),
                    if (canExportExpenses)
                      _ReportMenuItem(
                        icon: Icons.receipt_outlined,
                        accentColor: AppColors.warning,
                        title: AppStrings.expenseSummaryReport,
                        subtitle: AppStrings.expenseSummarySubtitle,
                        onTap: () => context.push(RoutePaths.expenseSummary),
                      ),
                  ],
                ),
              ),
            if (canExportCustomers) ...[
              if (financialCount > 0) const SizedBox(height: 10),
              JobWorkDetailSection(
                title: AppStrings.customers,
                icon: Icons.people_outline,
                child: _ReportMenuGroup(
                  items: [
                    _ReportMenuItem(
                      icon: Icons.receipt_long_outlined,
                      accentColor: AppColors.success,
                      title: AppStrings.customerStatement,
                      subtitle: AppStrings.customerStatementSubtitle,
                      onTap: () => showCustomerPickerSheet(context),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppStrings.reportsComingSoon,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportMenuItem {
  const _ReportMenuItem({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _ReportMenuGroup extends StatelessWidget {
  const _ReportMenuGroup({required this.items});

  final List<_ReportMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++)
          MoreMenuTile(
            icon: items[i].icon,
            accentColor: items[i].accentColor,
            title: items[i].title,
            subtitle: items[i].subtitle,
            onTap: items[i].onTap,
            showDivider: i < items.length - 1,
          ),
      ],
    );
  }
}
