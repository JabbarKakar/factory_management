import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/factory_role_enums.dart';
import '../compact_status_chip.dart';

Color factoryRoleAccent(FactoryRole role) {
  return switch (role) {
    FactoryRole.owner => AppColors.primary,
    FactoryRole.factoryManager => AppColors.primary,
    FactoryRole.accountant => AppColors.success,
    FactoryRole.salesStaff => AppColors.primary,
    FactoryRole.jobWorkClerk => AppColors.warning,
    FactoryRole.supervisor => AppColors.success,
    FactoryRole.storeKeeper => AppColors.warning,
    FactoryRole.driver => AppColors.accent,
    FactoryRole.viewer => AppColors.textSecondary,
  };
}

class FactoryRoleBadge extends StatelessWidget {
  const FactoryRoleBadge({
    required this.role,
    this.compact = false,
    super.key,
  });

  final FactoryRole role;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = factoryRoleAccent(role);

    if (compact) {
      return CompactStatusChip(
        label: role.label,
        color: color,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
      ),
    );
  }
}
