import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/job_work_invoice_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../domain/entities/job_work_invoice.dart';
import '../../../domain/entities/payment.dart';
import '../settings_section.dart';

class CustomerLedgerSection extends StatelessWidget {
  const CustomerLedgerSection({required this.customerId, super.key});

  final String customerId;

  @override
  Widget build(BuildContext context) {
    final invoiceRepository = getIt<JobWorkInvoiceRepository>();
    final paymentRepository = getIt<PaymentRepository>();

    return SettingsSection(
      title: AppStrings.accountLedger,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.ledgerOpeningBalanceNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<JobWorkInvoice>>(
              stream: invoiceRepository.watchInvoicesForCustomer(customerId),
              builder: (context, invoiceSnapshot) {
                return StreamBuilder<List<Payment>>(
                  stream: paymentRepository.watchPaymentsForCustomer(customerId),
                  builder: (context, paymentSnapshot) {
                    final invoices = invoiceSnapshot.data ?? const [];
                    final payments = paymentSnapshot.data ?? const [];

                    if (invoices.isEmpty && payments.isEmpty) {
                      return Text(AppStrings.noLedgerActivity);
                    }

                    final entries = <_LedgerEntry>[
                      ...invoices.map(
                        (invoice) => _LedgerEntry(
                          date: invoice.createdAt,
                          title:
                              '${AppStrings.invoiceTypeJobWork} ${invoice.invoiceNumber}',
                          subtitle: invoice.jobWorkNumber,
                          amount: invoice.dueAmount > 0
                              ? invoice.dueAmount
                              : invoice.totalAmount,
                          isCredit: true,
                        ),
                      ),
                      ...payments.map(
                        (payment) => _LedgerEntry(
                          date: payment.paymentDate,
                          title: AppStrings.paymentReceived,
                          subtitle:
                              '${payment.invoiceNumber} · ${payment.method.label}',
                          amount: payment.amount,
                          isCredit: false,
                        ),
                      ),
                    ]..sort((a, b) => b.date.compareTo(a.date));

                    return Column(
                      children: [
                        for (final entry in entries.take(10)) ...[
                          _LedgerRow(entry: entry),
                          const SizedBox(height: 8),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerEntry {
  const _LedgerEntry({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
  });

  final DateTime date;
  final String title;
  final String subtitle;
  final double amount;
  final bool isCredit;
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});

  final _LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final amountColor = entry.isCredit
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(entry.subtitle, style: TextStyle(color: muted, fontSize: 12)),
            ],
          ),
        ),
        Text(
          '${entry.isCredit ? '+' : '-'}${Formatters.currencyPkr(entry.amount)}',
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
