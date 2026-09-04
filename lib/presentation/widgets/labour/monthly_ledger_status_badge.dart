import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/monthly_ledger.dart';
import '../../../domain/enums/labour_enums.dart';
import '../compact_status_chip.dart';

Color monthlyLedgerStatusAccent(MonthlyLedger ledger) {
  if (ledger.isClosed) return AppColors.textSecondary;
  if (ledger.isOverpaid) return AppColors.error;
  if (ledger.status == MonthlyLedgerStatus.settled ||
      ledger.remainingBalance.abs() < 0.005) {
    return AppColors.success;
  }
  return AppColors.warning;
}

String monthlyLedgerStatusLabel(MonthlyLedger ledger) {
  if (ledger.isClosed) return MonthlyLedgerStatus.closed.label;
  if (ledger.isOverpaid) return 'Overpaid';
  if (ledger.status == MonthlyLedgerStatus.settled ||
      ledger.remainingBalance.abs() < 0.005) {
    return MonthlyLedgerStatus.settled.label;
  }
  return MonthlyLedgerStatus.open.label;
}

class MonthlyLedgerStatusBadge extends StatelessWidget {
  const MonthlyLedgerStatusBadge({
    required this.ledger,
    this.compact = true,
    super.key,
  });

  final MonthlyLedger ledger;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = monthlyLedgerStatusAccent(ledger);
    final label = monthlyLedgerStatusLabel(ledger);

    if (compact) {
      return CompactStatusChip(label: label, color: color);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
      ),
    );
  }
}
