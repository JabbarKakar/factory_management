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
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 6.0;
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
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(action.icon, color: action.color, size: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    fontSize: 10,
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

  void add({
    required bool visible,
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    if (!visible) return;
    actions.add(
      _QuickAction(
        label: label,
        icon: icon,
        color: color,
        onTap: onTap,
      ),
    );
  }

  add(
    visible: user.canCreate(AppModule.jobWork),
    onTap: () => context.push(RoutePaths.jobWorkAdd),
    icon: Icons.content_cut_rounded,
    label: AppStrings.newJobWorkOrder,
    color: AppColors.primary,
  );
  add(
    visible: user.canCreate(AppModule.sales),
    onTap: () => context.push(RoutePaths.salesAdd),
    icon: Icons.shopping_bag_outlined,
    label: AppStrings.newSalesOrder,
    color: AppColors.accent,
  );
  add(
    visible: user.canCreate(AppModule.customers),
    onTap: () => context.push(RoutePaths.customersAdd),
    icon: Icons.person_add_outlined,
    label: AppStrings.addCustomer,
    color: AppColors.success,
  );

  return actions;
}
