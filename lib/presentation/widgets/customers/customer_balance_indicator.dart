import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/customer_enums.dart';

class CustomerBalanceIndicator extends StatelessWidget {
  const CustomerBalanceIndicator({
    required this.status,
    this.showLabel = true,
    super.key,
  });

  final CustomerBalanceStatus status;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
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
