import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/extensions/app_user_permissions.dart';
import '../../routes/route_paths.dart';
import 'dashboard_surface.dart';

class DashboardQuickActionsGrid extends StatelessWidget {
  const DashboardQuickActionsGrid({required this.user, super.key});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final actions = _actionsFor(context, user);
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: AppStrings.quickActions,
          subtitle: 'Shortcuts to common tasks',
          icon: Icons.bolt_rounded,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            const columns = 3;
            final tileWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: actions
                  .map(
                    (action) => SizedBox(
                      width: tileWidth,
                      child: _QuickActionTile(action: action),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(action.icon, color: action.color, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.25,
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

List<_QuickAction> _actionsFor(BuildContext context, AppUser? user) {
  if (user == null) return const [];

  final actions = <_QuickAction>[];
  final palette = [
    AppColors.primary,
    AppColors.accent,
    AppColors.success,
    const Color(0xFF6366F1),
    const Color(0xFF0EA5E9),
    AppColors.warning,
  ];
  var colorIndex = 0;

  Color nextColor() => palette[colorIndex++ % palette.length];

  void add({
    required bool visible,
    required VoidCallback onTap,
    required IconData icon,
    required String label,
  }) {
    if (!visible) return;
    actions.add(
      _QuickAction(
        label: label,
        icon: icon,
        color: nextColor(),
        onTap: onTap,
      ),
    );
  }

  add(
    visible: user.canCreate(AppModule.jobWork),
    onTap: () => context.push(RoutePaths.jobWorkAdd),
    icon: Icons.content_cut_rounded,
    label: AppStrings.newJobWorkOrder,
  );
  add(
    visible: user.canCreate(AppModule.sales),
    onTap: () => context.push(RoutePaths.salesAdd),
    icon: Icons.shopping_bag_outlined,
    label: AppStrings.newSalesOrder,
  );
  add(
    visible: user.canCreate(AppModule.expenses),
    onTap: () => context.push(RoutePaths.expensesAdd),
    icon: Icons.receipt_long_outlined,
    label: AppStrings.addExpense,
  );
  add(
    visible: user.canView(AppModule.expenses),
    onTap: () => context.push(RoutePaths.expenses),
    icon: Icons.list_alt_rounded,
    label: AppStrings.viewExpenses,
  );
  add(
    visible: user.canView(AppModule.plReport),
    onTap: () => context.push(RoutePaths.plReport),
    icon: Icons.assessment_outlined,
    label: AppStrings.monthlyPlReport,
  );
  add(
    visible: user.canCreate(AppModule.production),
    onTap: () => context.push(RoutePaths.productionAdd),
    icon: Icons.precision_manufacturing_outlined,
    label: AppStrings.recordProduction,
  );
  add(
    visible: user.canView(AppModule.finishedGoods),
    onTap: () => context.push(RoutePaths.finishedGoods),
    icon: Icons.layers_outlined,
    label: AppStrings.finishedGoodsInventory,
  );
  add(
    visible: user.canCreate(AppModule.labour),
    onTap: () => context.push(RoutePaths.attendance),
    icon: Icons.fact_check_outlined,
    label: AppStrings.markAttendance,
  );
  add(
    visible: user.canCreate(AppModule.delivery),
    onTap: () => context.push(RoutePaths.deliveriesAdd),
    icon: Icons.local_shipping_outlined,
    label: AppStrings.scheduleDelivery,
  );
  add(
    visible: user.canCreate(AppModule.equipment),
    onTap: () => context.push(RoutePaths.equipmentAdd),
    icon: Icons.build_circle_outlined,
    label: AppStrings.addEquipment,
  );
  add(
    visible: user.canCreate(AppModule.labour),
    onTap: () => context.push(RoutePaths.employeesAdd),
    icon: Icons.person_add_alt_1_outlined,
    label: AppStrings.addEmployee,
  );
  add(
    visible: user.canCreate(AppModule.customers),
    onTap: () => context.push(RoutePaths.customersAdd),
    icon: Icons.person_add_outlined,
    label: AppStrings.addCustomer,
  );

  return actions;
}
