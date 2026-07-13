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
import '../job_work/job_work_detail_section.dart';
import '../payment_reminder_action_bar.dart';

class CustomerLedgerSection extends StatelessWidget {
  const CustomerLedgerSection({
    required this.factoryId,
    required this.customerId,
    required this.customerName,
    super.key,
  });

  final String factoryId;
  final String customerId;
  final String customerName;

  @override
  Widget build(BuildContext context) {
    final jobWorkInvoiceRepository = getIt<JobWorkInvoiceRepository>();
    final salesInvoiceRepository = getIt<SalesInvoiceRepository>();
    final paymentRepository = getIt<PaymentRepository>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: JobWorkDetailSection(
        title: AppStrings.accountLedger,
        icon: Icons.account_balance_wallet_outlined,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.ledgerOpeningBalanceNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      height: 1.35,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
            StreamBuilder<List<JobWorkInvoice>>(
              stream: jobWorkInvoiceRepository.watchInvoicesForCustomer(
                factoryId: factoryId,
                customerId: customerId,
              ),
              builder: (context, jobWorkSnapshot) {
                return StreamBuilder<List<SalesInvoice>>(
                  stream: salesInvoiceRepository.watchInvoicesForCustomer(
                    factoryId: factoryId,
                    customerId: customerId,
                  ),
                  builder: (context, salesSnapshot) {
                    return StreamBuilder<List<Payment>>(
                      stream: paymentRepository.watchPaymentsForCustomer(
                        factoryId: factoryId,
                        customerId: customerId,
                      ),
                      builder: (context, paymentSnapshot) {
                        final jobWorkInvoices = jobWorkSnapshot.data ?? const [];
                        final salesInvoices = salesSnapshot.data ?? const [];
                        final payments = paymentSnapshot.data ?? const [];

                        if (jobWorkInvoices.isEmpty &&
                            salesInvoices.isEmpty &&
                            payments.isEmpty) {
                          return Text(
                            AppStrings.noLedgerActivity,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 11),
                          );
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
      ),
    );
  }

  _LedgerEntry _entryFromJobWorkInvoice(JobWorkInvoice invoice) {
    final isSettled = invoice.dueAmount <= 0;
    return _LedgerEntry(
      date: invoice.createdAt,
      title: '${AppStrings.invoiceTypeJobWork} ${invoice.invoiceNumber}',
      reference: [
        invoice.jobWorkNumber,
        if (invoice.loadNumber != null && invoice.loadNumber!.isNotEmpty)
          invoice.loadNumber!,
      ].join(' · '),
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
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                  color: accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${entry.reference} · $dateLabel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: muted,
                              fontSize: 11,
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
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
            ),
            const SizedBox(height: 8),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
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
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}
