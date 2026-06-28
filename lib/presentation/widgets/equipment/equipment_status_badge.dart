import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/equipment_enums.dart';
import '../compact_status_chip.dart';

Color equipmentStatusAccent(EquipmentStatus status) {
  return switch (status) {
    EquipmentStatus.running => AppColors.success,
    EquipmentStatus.underMaintenance => AppColors.warning,
    EquipmentStatus.broken => AppColors.error,
    EquipmentStatus.retired => AppColors.textSecondary,
  };
}

class EquipmentStatusBadge extends StatelessWidget {
  const EquipmentStatusBadge({
    required this.status,
    this.compact = false,
    super.key,
  });

  final EquipmentStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = equipmentStatusAccent(status);

    if (compact) {
      return CompactStatusChip(
        label: status.label,
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
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
      ),
    );
  }
}
