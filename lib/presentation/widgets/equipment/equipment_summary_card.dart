import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/equipment_enums.dart';

class EquipmentSummaryCard extends StatelessWidget {
  const EquipmentSummaryCard({
    required this.totalCount,
    required this.runningCount,
    required this.maintenanceDueCount,
    super.key,
  });

  final int totalCount;
  final int runningCount;
  final int maintenanceDueCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    const accent = AppColors.primary;
    const cardShape = BorderRadius.only(
      topRight: Radius.circular(14),
      bottomRight: Radius.circular(14),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
              const ColoredBox(color: accent, child: SizedBox(width: 3)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.precision_manufacturing_outlined,
                          color: accent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              EquipmentStatus.running.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$runningCount',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: accent,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: outline.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppStrings.factoryEquipment,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$totalCount',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          if (maintenanceDueCount > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '$maintenanceDueCount ${AppStrings.maintenanceDueKpi.toLowerCase()}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
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
