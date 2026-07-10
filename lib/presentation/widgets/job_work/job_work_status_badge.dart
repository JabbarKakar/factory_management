import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../compact_status_chip.dart';

class JobWorkStatusBadge extends StatelessWidget {
  const JobWorkStatusBadge({
    required this.status,
    this.compact = false,
    super.key,
  });

  final JobWorkStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(status);

    if (compact) {
      return CompactStatusChip(
        label: status.label,
        color: colors.foreground,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = CompactStatusChip.readableForeground(
      colors.foreground,
      isDark,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? foreground.withValues(alpha: 0.18)
            : colors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: foreground.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
      ),
    );
  }

  _BadgeColors _colorsFor(JobWorkStatus status) {
    return switch (status) {
      JobWorkStatus.received => const _BadgeColors(
          AppColors.textSecondary,
          Color(0xFFECEFF1),
        ),
      JobWorkStatus.agreed => const _BadgeColors(
          AppColors.primary,
          Color(0xFFE8EAF6),
        ),
      JobWorkStatus.inCutting => const _BadgeColors(
          Color(0xFF1565C0),
          Color(0xFFE3F2FD),
        ),
      JobWorkStatus.qc => const _BadgeColors(
          Color(0xFF6A1B9A),
          Color(0xFFF3E5F5),
        ),
      JobWorkStatus.ready => const _BadgeColors(
          AppColors.success,
          Color(0xFFE8F5E9),
        ),
      JobWorkStatus.invoiced ||
      JobWorkStatus.paid =>
        const _BadgeColors(AppColors.accent, Color(0xFFFFF3E0)),
      JobWorkStatus.partiallyCollected => const _BadgeColors(
          AppColors.warning,
          Color(0xFFFFF8E1),
        ),
      JobWorkStatus.collected || JobWorkStatus.closed => const _BadgeColors(
          Color(0xFF455A64),
          Color(0xFFECEFF1),
        ),
      JobWorkStatus.cancelled => const _BadgeColors(
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
