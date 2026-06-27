import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/labour_enums.dart';

class EmployeeStatusBadge extends StatelessWidget {
  const EmployeeStatusBadge({
    required this.status,
    this.compact = false,
    super.key,
  });

  final EmployeeStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isActive = status == EmployeeStatus.active;
    final color = isActive ? AppColors.success : AppColors.textSecondary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
