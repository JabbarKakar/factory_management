import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/job_work_invoice_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/sales_invoice_repository.dart';
import '../../../domain/entities/job_work_invoice.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/sales_invoice.dart';
import '../../../domain/enums/invoice_enums.dart';
import '../payment_reminder_action_bar.dart';
import '../settings_section.dart';

class CustomerLedgerSection extends StatelessWidget {
  const CustomerLedgerSection({
    required this.customerId,
    required this.customerName,
    super.key,
  });

  final String customerId;
  final String customerName;

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
            const SizedBox(height: 16),
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

                        final visible = entries.take(10).toList();

                        return Column(
                          children: [
                            for (var i = 0; i < visible.length; i++) ...[
                              _LedgerRow(
                                entry: visible[i],
                                customerId: customerId,
                                customerName: customerName,
                              ),
                              if (i < visible.length - 1)
                                const SizedBox(height: 12),
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
      reference: invoice.jobWorkNumber,
      subtitle: isSettled
          ? invoice.status.label
          : '${Formatters.currencyPkr(invoice.dueAmount)} ${AppStrings.ledgerAmountDue}',
      amount: isSettled ? invoice.totalAmount : invoice.dueAmount,
      kind: isSettled ? _LedgerEntryKind.settled : _LedgerEntryKind.outstanding,
      invoiceId: isSettled ? null : invoice.id,
      invoiceNumber: isSettled ? null : invoice.invoiceNumber,
      invoiceType: isSettled ? null : InvoiceType.jobWork,
      dueDate: invoice.dueDate,
      isOverdue: invoice.status == InvoiceStatus.overdue,
    );
  }

  _LedgerEntry _entryFromSalesInvoice(SalesInvoice invoice) {
    final isSettled = invoice.dueAmount <= 0;
    return _LedgerEntry(
      date: invoice.createdAt,
      title: '${AppStrings.invoiceTypeSales} ${invoice.invoiceNumber}',
      reference: invoice.orderNumber,
      subtitle: isSettled
          ? invoice.status.label
          : '${Formatters.currencyPkr(invoice.dueAmount)} ${AppStrings.ledgerAmountDue}',
      amount: isSettled ? invoice.totalAmount : invoice.dueAmount,
      kind: isSettled ? _LedgerEntryKind.settled : _LedgerEntryKind.outstanding,
      invoiceId: isSettled ? null : invoice.id,
      invoiceNumber: isSettled ? null : invoice.invoiceNumber,
      invoiceType: isSettled ? null : InvoiceType.sales,
      dueDate: invoice.dueDate,
      isOverdue: invoice.status == InvoiceStatus.overdue,
    );
  }

  _LedgerEntry _entryFromPayment(Payment payment) {
    return _LedgerEntry(
      date: payment.paymentDate,
      title: AppStrings.paymentReceived,
      reference: payment.invoiceNumber,
      subtitle: payment.method.label,
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
    required this.reference,
    required this.subtitle,
    required this.amount,
    required this.kind,
    this.invoiceId,
    this.invoiceNumber,
    this.invoiceType,
    this.dueDate,
    this.isOverdue = false,
  });

  final DateTime date;
  final String title;
  final String reference;
  final String subtitle;
  final double amount;
  final _LedgerEntryKind kind;
  final String? invoiceId;
  final String? invoiceNumber;
  final InvoiceType? invoiceType;
  final DateTime? dueDate;
  final bool isOverdue;
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.entry,
    required this.customerId,
    required this.customerName,
  });

  final _LedgerEntry entry;
  final String customerId;
  final String customerName;

  @override
  Widget build(BuildContext context) {
    if (entry.kind == _LedgerEntryKind.outstanding) {
      return _OutstandingLedgerCard(
        entry: entry,
        customerId: customerId,
        customerName: customerName,
      );
    }

    return _CompactLedgerRow(entry: entry);
  }
}

class _OutstandingLedgerCard extends StatelessWidget {
  const _OutstandingLedgerCard({
    required this.entry,
    required this.customerId,
    required this.customerName,
  });

  final _LedgerEntry entry;
  final String customerId;
  final String customerName;

  @override
  Widget build(BuildContext context) {
    final accent = entry.isOverdue ? AppColors.overdue : AppColors.dueSoon;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final dateLabel = DateFormat.yMMMd().format(entry.date);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 22,
                  color: accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.reference} · $dateLabel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  Formatters.currencyPkr(entry.amount),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              entry.subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: accent.withValues(alpha: 0.2)),
            const SizedBox(height: 14),
            PaymentReminderActionBar(
              invoiceId: entry.invoiceId!,
              customerId: customerId,
              customerName: customerName,
              invoiceNumber: entry.invoiceNumber!,
              invoiceType: entry.invoiceType!,
              amountDue: entry.amount,
              dueDate: entry.dueDate,
              isOverdue: entry.isOverdue,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactLedgerRow extends StatelessWidget {
  const _CompactLedgerRow({required this.entry});

  final _LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final scheme = Theme.of(context).colorScheme;
    final dateLabel = DateFormat.yMMMd().format(entry.date);

    final (icon, iconColor, amountText, amountColor) = switch (entry.kind) {
      _LedgerEntryKind.settled => (
          Icons.check_circle_outline,
          muted,
          Formatters.currencyPkr(entry.amount),
          muted,
        ),
      _LedgerEntryKind.payment => (
          Icons.payments_outlined,
          scheme.primary,
          '-${Formatters.currencyPkr(entry.amount)}',
          scheme.primary,
        ),
      _LedgerEntryKind.outstanding => (
          Icons.receipt_long_outlined,
          scheme.error,
          Formatters.currencyPkr(entry.amount),
          scheme.error,
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: entry.kind == _LedgerEntryKind.settled
                            ? muted
                            : null,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.reference} · ${entry.subtitle} · $dateLabel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: muted,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
