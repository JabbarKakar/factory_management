import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/equipment.dart';

class EquipmentListTile extends StatelessWidget {
  const EquipmentListTile({
    required this.equipment,
    required this.onTap,
    super.key,
  });

  final Equipment equipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final overdue = equipment.isMaintenanceOverdue(today: today);
    final dueSoon = !overdue && equipment.isMaintenanceDueSoon(today: today);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: overdue
            ? AppColors.error.withValues(alpha: 0.12)
            : dueSoon
                ? AppColors.warning.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.precision_manufacturing_outlined,
          color: overdue
              ? AppColors.error
              : dueSoon
                  ? AppColors.warning
                  : Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(equipment.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(equipment.displaySubtitle),
          if (equipment.nextMaintenanceDueDate != null)
            Text(
              overdue
                  ? 'Maintenance overdue · ${DateFormat.yMMMd().format(equipment.nextMaintenanceDueDate!)}'
                  : dueSoon
                      ? 'Due ${DateFormat.yMMMd().format(equipment.nextMaintenanceDueDate!)}'
                      : 'Next: ${DateFormat.yMMMd().format(equipment.nextMaintenanceDueDate!)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: overdue
                        ? AppColors.error
                        : dueSoon
                            ? AppColors.warning
                            : AppColors.textSecondary,
                  ),
            ),
        ],
      ),
      trailing: Text(
        equipment.equipmentNumber,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
      onTap: onTap,
    );
  }
}
