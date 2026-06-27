import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/extensions/app_user_permissions.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_actions.dart';
import '../../widgets/account_menu_button.dart';
import '../../widgets/dashboard/dashboard_surface.dart';
import '../../widgets/more/more_logout_tile.dart';
import '../../widgets/more/more_menu_tile.dart';
import '../../widgets/more/more_profile_banner.dart';
import '../../widgets/theme_mode_selector.dart';

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.more),
            Text(
              'Settings & modules',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: (Theme.of(context).appBarTheme.foregroundColor ??
                            Theme.of(context).colorScheme.onSurface)
                        .withValues(alpha: 0.78),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        actions: const [
          AccountMenuButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (user != null) ...[
            MoreProfileBanner(user: user),
            const SizedBox(height: 12),
          ],
          _MoreSection(
            title: AppStrings.appearance,
            subtitle: 'Theme and display',
            icon: Icons.palette_outlined,
            child: const ThemeModeSelector(),
          ),
          if (user != null) ...[
            ..._buildModuleSections(context, user),
            const SizedBox(height: 16),
            _MoreSection(
              title: AppStrings.account,
              subtitle: 'Session & sign out',
              icon: Icons.manage_accounts_outlined,
              wrapInCard: false,
              child: MoreLogoutTile(
                onTap: () => _confirmLogout(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildModuleSections(BuildContext context, AppUser user) {
    final sections = <Widget>[];

    void addSection({
      required String title,
      required String subtitle,
      required IconData icon,
      required List<_MoreMenuItem> items,
    }) {
      if (items.isEmpty) return;
      sections.add(const SizedBox(height: 16));
      sections.add(
        _MoreSection(
          title: title,
          subtitle: subtitle,
          icon: icon,
          child: _MoreMenuGroup(items: items),
        ),
      );
    }

    addSection(
      title: AppStrings.reports,
      subtitle: 'Analytics and exports',
      icon: Icons.assessment_outlined,
      items: [
        if (user.canView(AppModule.plReport) ||
            user.canExport(AppModule.customers))
          _MoreMenuItem(
            icon: Icons.bar_chart_rounded,
            color: AppColors.primary,
            title: AppStrings.reportsHub,
            subtitle: AppStrings.reportsHubSubtitle,
            onTap: () => context.push(RoutePaths.reportsHub),
          ),
      ],
    );

    addSection(
      title: 'Finance',
      subtitle: 'Costs and spending',
      icon: Icons.account_balance_wallet_outlined,
      items: [
        if (user.canView(AppModule.expenses))
          _MoreMenuItem(
            icon: Icons.receipt_long_outlined,
            color: AppColors.warning,
            title: AppStrings.factoryExpenses,
            subtitle: AppStrings.factoryExpensesSubtitle,
            onTap: () => context.push(RoutePaths.expenses),
          ),
      ],
    );

    addSection(
      title: 'Inventory',
      subtitle: 'Stock and materials',
      icon: Icons.inventory_2_outlined,
      items: [
        if (user.canView(AppModule.rawMaterials))
          _MoreMenuItem(
            icon: Icons.category_outlined,
            color: AppColors.primary,
            title: AppStrings.rawMaterialStock,
            subtitle: AppStrings.rawMaterialStockSubtitle,
            onTap: () => context.push(RoutePaths.rawMaterials),
          ),
        if (user.canView(AppModule.finishedGoods))
          _MoreMenuItem(
            icon: Icons.layers_outlined,
            color: AppColors.success,
            title: AppStrings.finishedGoodsInventory,
            subtitle: AppStrings.finishedGoodsSubtitle,
            onTap: () => context.push(RoutePaths.finishedGoods),
          ),
      ],
    );

    addSection(
      title: 'Production',
      subtitle: 'Manufacturing workflow',
      icon: Icons.precision_manufacturing_outlined,
      items: [
        if (user.canView(AppModule.production))
          _MoreMenuItem(
            icon: Icons.factory_outlined,
            color: AppColors.accent,
            title: AppStrings.productionBatches,
            subtitle: AppStrings.productionBatchesSubtitle,
            onTap: () => context.push(RoutePaths.production),
          ),
        if (user.canView(AppModule.qualityControl))
          _MoreMenuItem(
            icon: Icons.verified_outlined,
            color: AppColors.dueSoon,
            title: AppStrings.qualityControl,
            subtitle: AppStrings.qualityControlSubtitle,
            onTap: () => context.push(RoutePaths.qualityChecks),
          ),
      ],
    );

    addSection(
      title: 'Workforce',
      subtitle: 'Team and attendance',
      icon: Icons.groups_outlined,
      items: [
        if (user.canView(AppModule.labour))
          _MoreMenuItem(
            icon: Icons.badge_outlined,
            color: AppColors.primaryLight,
            title: AppStrings.factoryWorkers,
            subtitle: AppStrings.factoryWorkersSubtitle,
            onTap: () => context.push(RoutePaths.employees),
          ),
        if (user.canView(AppModule.labour))
          _MoreMenuItem(
            icon: Icons.fact_check_outlined,
            color: AppColors.success,
            title: AppStrings.dailyAttendance,
            subtitle: AppStrings.dailyAttendanceSubtitle,
            onTap: () => context.push(RoutePaths.attendance),
          ),
      ],
    );

    addSection(
      title: 'Supply chain',
      subtitle: 'Suppliers, equipment & delivery',
      icon: Icons.local_shipping_outlined,
      items: [
        if (user.canView(AppModule.suppliers))
          _MoreMenuItem(
            icon: Icons.storefront_outlined,
            color: AppColors.accent,
            title: AppStrings.factorySuppliers,
            subtitle: AppStrings.factorySuppliersSubtitle,
            onTap: () => context.push(RoutePaths.suppliers),
          ),
        if (user.canView(AppModule.equipment))
          _MoreMenuItem(
            icon: Icons.build_circle_outlined,
            color: AppColors.primary,
            title: AppStrings.factoryEquipment,
            subtitle: AppStrings.factoryEquipmentSubtitle,
            onTap: () => context.push(RoutePaths.equipment),
          ),
        if (user.canView(AppModule.delivery))
          _MoreMenuItem(
            icon: Icons.local_shipping_outlined,
            color: AppColors.dueSoon,
            title: AppStrings.deliveries,
            subtitle: AppStrings.deliveriesSubtitle,
            onTap: () => context.push(RoutePaths.deliveries),
          ),
      ],
    );

    if (user.canManageTeam) {
      addSection(
        title: 'Administration',
        subtitle: 'Access and permissions',
        icon: Icons.admin_panel_settings_outlined,
        items: [
          _MoreMenuItem(
            icon: Icons.shield_outlined,
            color: AppColors.error,
            title: AppStrings.teamManagement,
            subtitle: AppStrings.teamManagementSubtitle,
            onTap: () => context.push(RoutePaths.team),
          ),
        ],
      );
    }

    return sections;
  }
}

class _MoreMenuItem {
  const _MoreMenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _MoreSection extends StatelessWidget {
  const _MoreSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.wrapInCard = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final bool wrapInCard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(
          title: title,
          subtitle: subtitle,
          icon: icon,
        ),
        const SizedBox(height: 10),
        wrapInCard
            ? DashboardSurfaceCard(
                compact: true,
                borderRadius: 14,
                padding: EdgeInsets.zero,
                child: child,
              )
            : child,
      ],
    );
  }
}

class _MoreMenuGroup extends StatelessWidget {
  const _MoreMenuGroup({required this.items});

  final List<_MoreMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++)
          MoreMenuTile(
            icon: items[i].icon,
            accentColor: items[i].color,
            title: items[i].title,
            subtitle: items[i].subtitle,
            onTap: items[i].onTap,
            showDivider: i < items.length - 1,
          ),
      ],
    );
  }
}
