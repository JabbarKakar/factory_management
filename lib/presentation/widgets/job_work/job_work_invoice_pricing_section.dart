import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/job_work_invoice.dart';
import '../../../domain/entities/payment.dart';
import 'job_work_detail_row.dart';
import 'job_work_detail_section.dart';

class JobWorkInvoicePricingSection extends StatelessWidget {
  const JobWorkInvoicePricingSection({
    required this.invoice,
    super.key,
  });

  final JobWorkInvoice invoice;

  @override
  Widget build(BuildContext context) {
    return JobWorkDetailSection(
      title: AppStrings.pricingAgreement,
      icon: Icons.payments_outlined,
      child: JobWorkDetailRows(
        rows: [
          JobWorkDetailRow(
            label: AppStrings.invoiceTotal,
            value: Formatters.currencyPkr(invoice.totalAmount),
          ),
          JobWorkDetailRow(
            label: AppStrings.amountPaid,
            value: Formatters.currencyPkr(invoice.paidAmount),
          ),
          JobWorkDetailRow(
            label: AppStrings.amountDue,
            value: Formatters.currencyPkr(invoice.dueAmount),
            bold: true,
            highlight: invoice.dueAmount > 0,
          ),
          if (invoice.dueDate != null)
            JobWorkDetailRow(
              label: AppStrings.paymentDueDate,
              value: DateFormat.yMMMd().format(invoice.dueDate!),
            ),
        ],
      ),
    );
  }
}

class JobWorkInvoicePaymentHistorySection extends StatelessWidget {
  const JobWorkInvoicePaymentHistorySection({
    required this.payments,
    super.key,
  });

  final List<Payment> payments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return JobWorkDetailSection(
      title: AppStrings.paymentHistory,
      icon: Icons.history_rounded,
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
                children: [
                  for (var i = 0; i < payments.length; i++) ...[
                    _PaymentRow(payment: payments[i]),
                    if (i < payments.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final dateLabel = DateFormat.yMMMd().format(payment.paymentDate);

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
                Text(
                  '${payment.method.label} · $dateLabel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.25,
                      ),
                ),
                if (payment.reference != null &&
                    payment.reference!.isNotEmpty) ...[
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
        ],
      ),
    );
  }
}
