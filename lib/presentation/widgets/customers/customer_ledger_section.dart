import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/job_work_invoice_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/sales_invoice_repository.dart';
import '../../../domain/entities/job_work_invoice.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/sales_invoice.dart';
import '../settings_section.dart';

class CustomerLedgerSection extends StatelessWidget {
  const CustomerLedgerSection({required this.customerId, super.key});

  final String customerId;

  @override
  Widget build(BuildContext context) {
    final jobWorkInvoiceRepository = getIt<JobWorkInvoiceRepository>();
    final salesInvoiceRepository = getIt<SalesInvoiceRepository>();
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
              stream: jobWorkInvoiceRepository.watchInvoicesForCustomer(customerId),
              builder: (context, jobWorkSnapshot) {
                return StreamBuilder<List<SalesInvoice>>(
                  stream:
                      salesInvoiceRepository.watchInvoicesForCustomer(customerId),
                  builder: (context, salesSnapshot) {
                    return StreamBuilder<List<Payment>>(
                      stream:
                          paymentRepository.watchPaymentsForCustomer(customerId),
                      builder: (context, paymentSnapshot) {
                        final jobWorkInvoices = jobWorkSnapshot.data ?? const [];
                        final salesInvoices = salesSnapshot.data ?? const [];
                        final payments = paymentSnapshot.data ?? const [];

                        if (jobWorkInvoices.isEmpty &&
                            salesInvoices.isEmpty &&
                            payments.isEmpty) {
                          return Text(AppStrings.noLedgerActivity);
                        }

                        final entries = <_LedgerEntry>[
                          ...jobWorkInvoices.map(_entryFromJobWorkInvoice),
                          ...salesInvoices.map(_entryFromSalesInvoice),
                          ...payments.map(_entryFromPayment),
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  _LedgerEntry _entryFromJobWorkInvoice(JobWorkInvoice invoice) {
    final isSettled = invoice.dueAmount <= 0;
    return _LedgerEntry(
      date: invoice.createdAt,
      title: '${AppStrings.invoiceTypeJobWork} ${invoice.invoiceNumber}',
      subtitle: isSettled
          ? '${invoice.jobWorkNumber} · ${invoice.status.label}'
          : '${invoice.jobWorkNumber} · ${Formatters.currencyPkr(invoice.dueAmount)} ${AppStrings.ledgerAmountDue}',
      amount: isSettled ? invoice.totalAmount : invoice.dueAmount,
      kind: isSettled ? _LedgerEntryKind.settled : _LedgerEntryKind.outstanding,
    );
  }

  _LedgerEntry _entryFromSalesInvoice(SalesInvoice invoice) {
    final isSettled = invoice.dueAmount <= 0;
    return _LedgerEntry(
      date: invoice.createdAt,
      title: '${AppStrings.invoiceTypeSales} ${invoice.invoiceNumber}',
      subtitle: isSettled
          ? '${invoice.orderNumber} · ${invoice.status.label}'
          : '${invoice.orderNumber} · ${Formatters.currencyPkr(invoice.dueAmount)} ${AppStrings.ledgerAmountDue}',
      amount: isSettled ? invoice.totalAmount : invoice.dueAmount,
      kind: isSettled ? _LedgerEntryKind.settled : _LedgerEntryKind.outstanding,
    );
  }

  _LedgerEntry _entryFromPayment(Payment payment) {
    return _LedgerEntry(
      date: payment.paymentDate,
      title: AppStrings.paymentReceived,
      subtitle: '${payment.invoiceNumber} · ${payment.method.label}',
      amount: payment.amount,
      kind: _LedgerEntryKind.payment,
    );
  }
}

enum _LedgerEntryKind { outstanding, settled, payment }

class _LedgerEntry {
  const _LedgerEntry({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.kind,
  });

  final DateTime date;
  final String title;
  final String subtitle;
  final double amount;
  final _LedgerEntryKind kind;
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});

  final _LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final (amountText, amountColor) = switch (entry.kind) {
      _LedgerEntryKind.outstanding => (
          '+${Formatters.currencyPkr(entry.amount)}',
          Theme.of(context).colorScheme.error,
        ),
      _LedgerEntryKind.settled => (
          Formatters.currencyPkr(entry.amount),
          muted,
        ),
      _LedgerEntryKind.payment => (
          '-${Formatters.currencyPkr(entry.amount)}',
          Theme.of(context).colorScheme.primary,
        ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: entry.kind == _LedgerEntryKind.settled ? muted : null,
                ),
              ),
              Text(entry.subtitle, style: TextStyle(color: muted, fontSize: 12)),
            ],
          ),
        ),
        Text(
          amountText,
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
