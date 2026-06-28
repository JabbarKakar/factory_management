import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class EquipmentMaintenanceBanner extends StatelessWidget {
  const EquipmentMaintenanceBanner({
    required this.overdueCount,
    required this.dueSoonCount,
    required this.onTap,
    super.key,
  });

  final int overdueCount;
  final int dueSoonCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (overdueCount == 0 && dueSoonCount == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOverdue = overdueCount > 0;
    final accent = isOverdue ? AppColors.error : AppColors.warning;
    const cardShape = BorderRadius.only(
      topRight: Radius.circular(14),
      bottomRight: Radius.circular(14),
    );

    final title = isOverdue
        ? '$overdueCount ${AppStrings.maintenanceOverdue}'
        : '$dueSoonCount ${AppStrings.maintenanceDueSoon}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: cardShape,
          child: Ink(
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: cardShape,
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ColoredBox(color: accent, child: const SizedBox(width: 3)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      child: Row(
                        children: [
                          Icon(
                            isOverdue
                                ? Icons.warning_amber_rounded
                                : Icons.build_circle_outlined,
                            color: accent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: accent,
                                height: 1.2,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: accent.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
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
