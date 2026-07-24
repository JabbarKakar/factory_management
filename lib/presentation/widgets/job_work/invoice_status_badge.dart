import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/invoice_enums.dart';
import '../compact_status_chip.dart';

Color invoiceStatusAccent(InvoiceStatus status) {
  return switch (status) {
    InvoiceStatus.paid => AppColors.success,
    InvoiceStatus.partial => AppColors.warning,
    InvoiceStatus.overdue => AppColors.error,
    InvoiceStatus.cancelled => AppColors.textSecondary,
    InvoiceStatus.unpaid => AppColors.warning,
  };
}

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
    final color = invoiceStatusAccent(status);

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
