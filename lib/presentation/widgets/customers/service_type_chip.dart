import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/customer_enums.dart';

class ServiceTypeChip extends StatelessWidget {
  const ServiceTypeChip({
    required this.serviceType,
    this.compact = false,
    super.key,
  });

  final CustomerServiceType serviceType;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = _colorsFor(serviceType, isDark);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconFor(serviceType),
              size: 10,
              color: colors.foreground,
            ),
            const SizedBox(width: 3),
            Text(
              serviceType.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w600,
                fontSize: 9,
                height: 1.1,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.foreground.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _iconFor(serviceType),
            size: 13,
            color: colors.foreground,
          ),
          const SizedBox(width: 5),
          Text(
            serviceType.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  _ChipColors _colorsFor(CustomerServiceType type, bool isDark) {
    final base = switch (type) {
      CustomerServiceType.buyer => AppColors.primary,
      CustomerServiceType.jobWork => AppColors.accent,
      CustomerServiceType.both => const Color(0xFF00695C),
      CustomerServiceType.other => const Color(0xFF6A1B9A),
    };

    if (isDark) {
      final hsl = HSLColor.fromColor(base);
      final foreground = hsl.lightness < 0.55
          ? hsl
              .withLightness((hsl.lightness + 0.42).clamp(0.0, 0.82))
              .toColor()
          : base;
      return _ChipColors(
        foreground,
        foreground.withValues(alpha: 0.22),
      );
    }

    return switch (type) {
      CustomerServiceType.buyer => _ChipColors(
          AppColors.primary,
          AppColors.primary.withValues(alpha: 0.1),
        ),
      CustomerServiceType.jobWork => _ChipColors(
          AppColors.accent,
          AppColors.accent.withValues(alpha: 0.14),
        ),
      CustomerServiceType.both => const _ChipColors(
          Color(0xFF00695C),
          Color(0xFFE0F2F1),
        ),
      CustomerServiceType.other => const _ChipColors(
          Color(0xFF6A1B9A),
          Color(0xFFF3E5F5),
        ),
    };
  }

  IconData _iconFor(CustomerServiceType type) {
    return switch (type) {
      CustomerServiceType.buyer => Icons.shopping_bag_outlined,
      CustomerServiceType.jobWork => Icons.content_cut_outlined,
      CustomerServiceType.both => Icons.swap_horiz_rounded,
      CustomerServiceType.other => Icons.more_horiz_rounded,
    };
  }
}

class _ChipColors {
  const _ChipColors(this.foreground, this.background);

  final Color foreground;
  final Color background;
}
