import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
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

  static const Color _whatsAppGreen = Color(0xFF25A56A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final isDark = theme.brightness == Brightness.dark;
    final surfaceTint = _whatsAppGreen.withValues(alpha: isDark ? 0.14 : 0.08);
    final borderTint = _whatsAppGreen.withValues(alpha: isDark ? 0.32 : 0.22);

    return StreamBuilder(
      stream: getIt<PaymentReminderRepository>()
          .watchRemindersForInvoice(invoiceId),
      builder: (context, snapshot) {
        final latest = snapshot.data?.isNotEmpty == true
            ? snapshot.data!.first
            : null;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: surfaceTint,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderTint),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
            child: Row(
              children: [
                Icon(
                  Icons.chat_outlined,
                  size: 14,
                  color: _whatsAppGreen.withValues(alpha: isDark ? 0.95 : 0.88),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: latest != null
                      ? Text(
                          '${AppStrings.lastRemindedOn} '
                          '${DateFormat.MMMd().add_jm().format(latest.sentAt)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: muted,
                            fontSize: 10,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          AppStrings.noRemindersYet,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: muted,
                            fontSize: 10,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: AppStrings.remindOnWhatsApp,
                  child: TextButton.icon(
                    onPressed: () => _send(context),
                    icon: const Icon(Icons.send_rounded, size: 13),
                    label: const Text(
                      'Remind',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? AppColors.success : _whatsAppGreen,
                    backgroundColor: _whatsAppGreen.withValues(
                      alpha: isDark ? 0.18 : 0.12,
                    ),
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                ),
              ],
            ),
          ),
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
