import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../compact_status_chip.dart';

class LowStockBadge extends StatelessWidget {
  const LowStockBadge({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return const CompactStatusChip(
        label: AppStrings.lowStock,
        color: AppColors.warning,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        AppStrings.lowStock,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
