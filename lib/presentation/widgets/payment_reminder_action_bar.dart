import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../../data/repositories/payment_reminder_repository.dart';
import '../../domain/enums/invoice_enums.dart';
import '../utils/payment_reminder_actions.dart';

/// Compact reminder action for ledger cards and similar inline contexts.
class PaymentReminderActionBar extends StatelessWidget {
  const PaymentReminderActionBar({
    required this.invoiceId,
    required this.customerId,
    required this.customerName,
    required this.invoiceNumber,
    required this.invoiceType,
    required this.amountDue,
    this.dueDate,
    this.isOverdue = false,
    super.key,
  });

  final String invoiceId;
  final String customerId;
  final String customerName;
  final String invoiceNumber;
  final InvoiceType invoiceType;
  final double amountDue;
  final DateTime? dueDate;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return StreamBuilder(
      stream: getIt<PaymentReminderRepository>()
          .watchRemindersForInvoice(invoiceId),
      builder: (context, snapshot) {
        final latest = snapshot.data?.isNotEmpty == true
            ? snapshot.data!.first
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (latest != null) ...[
              Row(
                children: [
                  Icon(Icons.history, size: 14, color: muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${AppStrings.lastRemindedOn} '
                      '${DateFormat.yMMMd().add_jm().format(latest.sentAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _send(context),
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: const Text(AppStrings.remindOnWhatsApp),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  alignment: Alignment.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _send(BuildContext context) async {
    try {
      await PaymentReminderActions.sendWhatsApp(
        context: context,
        customerId: customerId,
        customerName: customerName,
        invoiceId: invoiceId,
        invoiceNumber: invoiceNumber,
        invoiceType: invoiceType,
        amountDue: amountDue,
        dueDate: dueDate,
        isOverdue: isOverdue,
      );
    } catch (error) {
      if (context.mounted) {
        PaymentReminderActions.showError(context, error);
      }
    }
  }
}
