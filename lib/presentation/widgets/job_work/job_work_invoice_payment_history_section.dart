import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/payment.dart';
import '../tile_options_menu.dart';
import 'job_work_detail_section.dart';

class JobWorkInvoicePaymentHistorySection extends StatelessWidget {
  const JobWorkInvoicePaymentHistorySection({
    required this.payments,
    this.canCorrect = false,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final List<Payment> payments;
  final bool canCorrect;
  final ValueChanged<Payment>? onEdit;
  final ValueChanged<Payment>? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final totalPaid =
        payments.fold<double>(0, (sum, payment) => sum + payment.amount);

    return JobWorkDetailSection(
      title: AppStrings.paymentHistory,
      icon: Icons.payments_outlined,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: payments.isEmpty
            ? Text(
                AppStrings.noPaymentsYet,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.35,
                  color: muted,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.amountPaid,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              Formatters.currencyPkr(totalPaid),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.success,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${payments.length} ${AppStrings.paymentsRecorded}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < payments.length; i++) ...[
                    _PaymentRow(
                      payment: payments[i],
                      canCorrect: canCorrect,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                    if (i < payments.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.canCorrect,
    this.onEdit,
    this.onDelete,
  });

  final Payment payment;
  final bool canCorrect;
  final ValueChanged<Payment>? onEdit;
  final ValueChanged<Payment>? onDelete;

  List<TileMenuAction> _menuActions() {
    final actions = <TileMenuAction>[];

    if (onEdit != null) {
      actions.add(
        TileMenuAction(
          label: AppStrings.editPayment,
          icon: Icons.edit_outlined,
          onSelected: () => onEdit!(payment),
        ),
      );
    }

    if (onDelete != null) {
      actions.add(
        TileMenuAction(
          label: AppStrings.deletePayment,
          icon: Icons.delete_outline_rounded,
          onSelected: () => onDelete!(payment),
          destructive: true,
        ),
      );
    }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final dateLabel = DateFormat.yMMMd().format(payment.paymentDate);
    final menuActions = canCorrect ? _menuActions() : const <TileMenuAction>[];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dateLabel · ${payment.method.label}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.25,
                      ),
                ),
                if (payment.reference != null &&
                    payment.reference!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    payment.reference!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: muted,
                          fontSize: 10,
                          height: 1.2,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Formatters.currencyPkr(payment.amount),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.success,
                ),
          ),
          if (menuActions.isNotEmpty)
            TileOptionsButton(actions: menuActions),
        ],
      ),
    );
  }
}
