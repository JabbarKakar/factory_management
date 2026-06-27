import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/extensions/app_user_permissions.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_actions.dart';
import '../../widgets/account_menu_button.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/theme_mode_selector.dart';
import '../../widgets/user_profile_card.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    await AuthActions.confirmLogout(context);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.more),
        actions: const [
          AccountMenuButton(),
        ],
      ),
      body: ListView(
        children: [
          if (user != null) UserProfileCard(user: user),
          SettingsSection(
            title: AppStrings.appearance,
            child: const ThemeModeSelector(),
          ),
          if (user != null && user.canView(AppModule.plReport))
            SettingsSection(
              title: AppStrings.reports,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.assessment_outlined),
                    title: const Text(AppStrings.monthlyPlReport),
                    subtitle: const Text(AppStrings.plReportSubtitle),
                    onTap: () => context.push(RoutePaths.plReport),
                  ),
                ],
              ),
            ),
          SettingsSection(
            title: AppStrings.general,
            child: Column(
              children: [
                if (user != null && user.canView(AppModule.expenses)) ...[
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text(AppStrings.factoryExpenses),
                    subtitle: const Text(AppStrings.factoryExpensesSubtitle),
                    onTap: () => context.push(RoutePaths.expenses),
                  ),
                  const Divider(height: 1),
                ],
                if (user != null && user.canView(AppModule.suppliers)) ...[
                  ListTile(
                    leading: const Icon(Icons.local_shipping_outlined),
                    title: const Text(AppStrings.factorySuppliers),
                    subtitle: const Text(AppStrings.factorySuppliersSubtitle),
                    onTap: () => context.push(RoutePaths.suppliers),
                  ),
                  const Divider(height: 1),
                ],
                if (user != null && user.canView(AppModule.rawMaterials)) ...[
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: const Text(AppStrings.rawMaterialStock),
                    subtitle: const Text(AppStrings.rawMaterialStockSubtitle),
                    onTap: () => context.push(RoutePaths.rawMaterials),
                  ),
                  const Divider(height: 1),
                ],
                if (user != null && user.canView(AppModule.production)) ...[
                  ListTile(
                    leading: const Icon(Icons.precision_manufacturing_outlined),
                    title: const Text(AppStrings.productionBatches),
                    subtitle: const Text(AppStrings.productionBatchesSubtitle),
                    onTap: () => context.push(RoutePaths.production),
                  ),
                  const Divider(height: 1),
                ],
                if (user != null && user.canView(AppModule.finishedGoods)) ...[
                  ListTile(
                    leading: const Icon(Icons.layers_outlined),
                    title: const Text(AppStrings.finishedGoodsInventory),
                    subtitle: const Text(AppStrings.finishedGoodsSubtitle),
                    onTap: () => context.push(RoutePaths.finishedGoods),
                  ),
                  const Divider(height: 1),
                ],
                if (user != null && user.canView(AppModule.labour)) ...[
                  ListTile(
                    leading: const Icon(Icons.groups_outlined),
                    title: const Text(AppStrings.factoryWorkers),
                    subtitle: const Text(AppStrings.factoryWorkersSubtitle),
                    onTap: () => context.push(RoutePaths.employees),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.fact_check_outlined),
                    title: const Text(AppStrings.dailyAttendance),
                    subtitle: const Text(AppStrings.dailyAttendanceSubtitle),
                    onTap: () => context.push(RoutePaths.attendance),
                  ),
                  const Divider(height: 1),
                ],
                if (user != null && user.canView(AppModule.equipment)) ...[
                  ListTile(
                    leading: const Icon(Icons.precision_manufacturing_outlined),
                    title: const Text(AppStrings.factoryEquipment),
                    subtitle: const Text(AppStrings.factoryEquipmentSubtitle),
                    onTap: () => context.push(RoutePaths.equipment),
                  ),
                  const Divider(height: 1),
                ],
                if (user != null && user.canView(AppModule.qualityControl)) ...[
                  ListTile(
                    leading: const Icon(Icons.verified_outlined),
                    title: const Text(AppStrings.qualityControl),
                    subtitle: const Text(AppStrings.qualityControlSubtitle),
                    onTap: () => context.push(RoutePaths.qualityChecks),
                  ),
                  const Divider(height: 1),
                ],
                if (user != null && user.canView(AppModule.delivery)) ...[
                  ListTile(
                    leading: const Icon(Icons.local_shipping_outlined),
                    title: const Text(AppStrings.deliveries),
                    subtitle: const Text(AppStrings.deliveriesSubtitle),
                    onTap: () => context.push(RoutePaths.deliveries),
                  ),
                  const Divider(height: 1),
                ],
                if (user != null && user.canManageTeam)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: const Text(AppStrings.teamManagement),
                    subtitle: const Text(AppStrings.teamManagementSubtitle),
                    onTap: () => context.push(RoutePaths.team),
                  ),
              ],
            ),
          ),
          SettingsSection(
            title: AppStrings.account,
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text(
                AppStrings.logout,
                style: TextStyle(color: AppColors.error),
              ),
              subtitle: const Text(AppStrings.logoutSubtitle),
              onTap: () => _confirmLogout(context),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
