import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/equipment.dart';
import 'equipment_status_badge.dart';

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
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    final today = DateTime.now();
    final overdue = equipment.isMaintenanceOverdue(today: today);
    final dueSoon =
        !overdue && equipment.isMaintenanceDueSoon(today: today);
    final accent = overdue
        ? AppColors.error
        : dueSoon
            ? AppColors.warning
            : equipmentStatusAccent(equipment.status);
    const cardShape = BorderRadius.only(
      topRight: Radius.circular(14),
      bottomRight: Radius.circular(14),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: cardShape,
          child: Ink(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: cardShape,
              border: Border.all(color: outline),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 3, color: accent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  equipment.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              Text(
                                equipment.equipmentNumber,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              EquipmentStatusBadge(
                                status: equipment.status,
                                compact: true,
                              ),
                              _MetaChip(
                                icon: Icons.category_outlined,
                                label: equipment.category.label,
                              ),
                              if (equipment.location != null &&
                                  equipment.location!.trim().isNotEmpty)
                                _MetaChip(
                                  icon: Icons.location_on_outlined,
                                  label: equipment.location!.trim(),
                                ),
                            ],
                          ),
                          if (equipment.nextMaintenanceDueDate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              overdue
                                  ? 'Maintenance overdue · ${DateFormat.yMMMd().format(equipment.nextMaintenanceDueDate!)}'
                                  : dueSoon
                                      ? 'Due ${DateFormat.yMMMd().format(equipment.nextMaintenanceDueDate!)}'
                                      : 'Next: ${DateFormat.yMMMd().format(equipment.nextMaintenanceDueDate!)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: overdue
                                    ? AppColors.error
                                    : dueSoon
                                        ? AppColors.warning
                                        : muted,
                                fontSize: 11,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: muted.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
