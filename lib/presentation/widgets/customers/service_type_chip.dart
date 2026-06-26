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
    final colors = _colorsFor(serviceType);

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
        serviceType.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  _ChipColors _colorsFor(CustomerServiceType type) {
    return switch (type) {
      CustomerServiceType.buyer => const _ChipColors(
          AppColors.primary,
          Color(0xFFE8EAF6),
        ),
      CustomerServiceType.jobWork => const _ChipColors(
          AppColors.accent,
          Color(0xFFFFF3E0),
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
}

class _ChipColors {
  const _ChipColors(this.foreground, this.background);

  final Color foreground;
  final Color background;
}
