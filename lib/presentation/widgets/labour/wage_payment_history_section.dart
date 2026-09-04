import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/wage_payment.dart';
import '../job_work/job_work_detail_section.dart';

class WagePaymentHistorySection extends StatelessWidget {
  const WagePaymentHistorySection({
    required this.payments,
    super.key,
  });

  final List<WagePayment> payments;

  @override
  Widget build(BuildContext context) {
    return JobWorkDetailSection(
      title: AppStrings.wagePaymentHistory,
      icon: Icons.receipt_long_outlined,
      subtitle: payments.isEmpty
          ? null
          : '${payments.length} ${payments.length == 1 ? 'installment' : 'installments'}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: payments.isEmpty
            ? Text(
                AppStrings.noWagePayments,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      height: 1.35,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            : Column(
                children: [
                  for (var i = 0; i < payments.length; i++) ...[
                    _WagePaymentRow(payment: payments[i]),
                    if (i < payments.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
      ),
    );
  }
}

class _WagePaymentRow extends StatelessWidget {
  const _WagePaymentRow({required this.payment});

  final WagePayment payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final dateLabel = DateFormat.yMMMd().format(payment.paymentDate);
    final recorder = payment.recordedByName?.trim().isNotEmpty == true
        ? payment.recordedByName!
        : payment.recordedBy;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.payments_outlined,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      Formatters.currencyPkr(payment.amount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    payment.paymentMethod.label,
                    if (recorder.isNotEmpty) '${AppStrings.recordedBy} $recorder',
                    if (payment.notes != null && payment.notes!.isNotEmpty)
                      payment.notes!,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: muted,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
