import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/invoice_enums.dart';

class InvoiceStatusBadge extends StatelessWidget {
  const InvoiceStatusBadge({
    required this.status,
    this.compact = false,
    super.key,
  });

  final InvoiceStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: colors.foreground,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _BadgeColors _colorsFor(InvoiceStatus status) {
    return switch (status) {
      InvoiceStatus.paid => const _BadgeColors(
          AppColors.success,
          Colors.white,
        ),
      InvoiceStatus.partial => const _BadgeColors(
          Color(0xFF1565C0),
          Colors.white,
        ),
      InvoiceStatus.overdue => const _BadgeColors(
          AppColors.error,
          Colors.white,
        ),
      InvoiceStatus.cancelled => const _BadgeColors(
          Color(0xFF757575),
          Colors.white,
        ),
      InvoiceStatus.unpaid => const _BadgeColors(
          Color(0xFFF57C00),
          Colors.white,
        ),
    };
  }
}

class _BadgeColors {
  const _BadgeColors(this.background, this.foreground);

  final Color background;
  final Color foreground;
}
