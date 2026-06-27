import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/settings_section.dart';

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final canViewPl = context.userCanView(AppModule.plReport);
    final canExportCustomers = context.userCanExport(AppModule.customers);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reportsHub),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              AppStrings.reportsHubSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          if (canViewPl)
            SettingsSection(
              title: AppStrings.reports,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.assessment_outlined),
                    title: const Text(AppStrings.monthlyPlReport),
                    subtitle: const Text(AppStrings.plReportSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RoutePaths.plReport),
                  ),
                ],
              ),
            ),
          if (canExportCustomers)
            SettingsSection(
              title: AppStrings.customers,
              child: ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text(AppStrings.customerStatement),
                subtitle: const Text(AppStrings.customerStatementSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(RoutePaths.customers),
              ),
            ),
          if (!canViewPl && !canExportCustomers)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(AppStrings.accessDeniedMessage),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppStrings.reportsComingSoon,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
