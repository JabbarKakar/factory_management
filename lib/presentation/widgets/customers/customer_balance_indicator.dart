import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/customer_enums.dart';
import '../compact_status_chip.dart';

class CustomerBalanceIndicator extends StatelessWidget {
  const CustomerBalanceIndicator({
    required this.status,
    this.showLabel = true,
    this.compact = false,
    super.key,
  });

  final CustomerBalanceStatus status;
  final bool showLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);

    if (compact && showLabel) {
      return CompactStatusChip(label: status.label, color: color);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 6 : 10,
          height: compact ? 6 : 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        if (showLabel) ...[
          SizedBox(width: compact ? 4 : 6),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 9 : null,
                  height: compact ? 1.1 : null,
                ),
          ),
        ],
      ],
    );
  }

  Color _colorFor(CustomerBalanceStatus status) {
    return switch (status) {
      CustomerBalanceStatus.paidUp => AppColors.success,
      CustomerBalanceStatus.dueSoon => AppColors.dueSoon,
      CustomerBalanceStatus.dueToday => AppColors.warning,
      CustomerBalanceStatus.overdue => AppColors.overdue,
      CustomerBalanceStatus.outstanding => AppColors.textSecondary,
    };
  }
}
