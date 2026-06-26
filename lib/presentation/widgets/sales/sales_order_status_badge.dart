import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/sales_enums.dart';

class SalesOrderStatusBadge extends StatelessWidget {
  const SalesOrderStatusBadge({
    required this.status,
    this.compact = false,
    super.key,
  });

  final SalesOrderStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.foreground.withValues(alpha: 0.25)),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  _BadgeColors _colorsFor(SalesOrderStatus status) {
    return switch (status) {
      SalesOrderStatus.received => const _BadgeColors(
          AppColors.textSecondary,
          Color(0xFFECEFF1),
        ),
      SalesOrderStatus.ready => const _BadgeColors(
          AppColors.success,
          Color(0xFFE8F5E9),
        ),
      SalesOrderStatus.invoiced ||
      SalesOrderStatus.paid =>
        const _BadgeColors(AppColors.accent, Color(0xFFFFF3E0)),
      SalesOrderStatus.closed => const _BadgeColors(
          Color(0xFF455A64),
          Color(0xFFECEFF1),
        ),
      SalesOrderStatus.cancelled => const _BadgeColors(
          AppColors.error,
          Color(0xFFFFEBEE),
        ),
    };
  }
}

class _BadgeColors {
  const _BadgeColors(this.foreground, this.background);

  final Color foreground;
  final Color background;
}
