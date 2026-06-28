import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/equipment.dart';
import 'equipment_status_badge.dart';

class EquipmentDetailHero extends StatelessWidget {
  const EquipmentDetailHero({
    required this.equipment,
    required this.overdue,
    required this.dueSoon,
    this.bookValue,
    super.key,
  });

  final Equipment equipment;
  final bool overdue;
  final bool dueSoon;
  final double? bookValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: DecoratedBox(
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
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              equipment.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                height: 1.2,
                              ),
                            ),
                          ),
                          EquipmentStatusBadge(status: equipment.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        equipment.equipmentNumber,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        equipment.displaySubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                      if (overdue || dueSoon) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Text(
                            overdue
                                ? AppStrings.maintenanceOverdueMessage
                                : AppStrings.maintenanceDueSoonMessage,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                      if (bookValue != null) ...[
                        const SizedBox(height: 10),
                        Divider(
                          height: 1,
                          color: outline.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppStrings.bookValue,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Text(
                              Formatters.currencyPkr(bookValue!),
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (equipment.nextMaintenanceDueDate != null &&
                          !overdue &&
                          !dueSoon) ...[
                        const SizedBox(height: 10),
                        Divider(
                          height: 1,
                          color: outline.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppStrings.nextMaintenanceDue,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Text(
                              DateFormat.yMMMd()
                                  .format(equipment.nextMaintenanceDueDate!),
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
