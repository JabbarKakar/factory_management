import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/labour_enums.dart';
import '../compact_status_chip.dart';

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
    final color = employeeStatusAccent(status);

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

Color employeeStatusAccent(EmployeeStatus status) {
  return switch (status) {
    EmployeeStatus.active => AppColors.success,
    EmployeeStatus.inactive => AppColors.textSecondary,
  };
}
