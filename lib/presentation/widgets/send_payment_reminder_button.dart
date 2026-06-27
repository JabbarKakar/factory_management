import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/enums/invoice_enums.dart';
import '../utils/payment_reminder_actions.dart';

class SendPaymentReminderButton extends StatelessWidget {
  const SendPaymentReminderButton({
    required this.customerId,
    required this.customerName,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceType,
    required this.amountDue,
    this.dueDate,
    this.isOverdue = false,
    this.iconOnly = true,
    super.key,
  });

  final String customerId;
  final String customerName;
  final String invoiceId;
  final String invoiceNumber;
  final InvoiceType invoiceType;
  final double amountDue;
  final DateTime? dueDate;
  final bool isOverdue;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    if (amountDue <= 0) return const SizedBox.shrink();

    if (iconOnly) {
      return IconButton(
        onPressed: () => _send(context),
        icon: const Icon(Icons.chat_outlined),
        tooltip: AppStrings.sendPaymentReminder,
      );
    }

    return TextButton.icon(
      onPressed: () => _send(context),
      icon: const Icon(Icons.chat_outlined),
      label: const Text(AppStrings.sendPaymentReminder),
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
