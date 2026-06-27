import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/payment_reminder_repository.dart';
import '../../domain/entities/payment_reminder.dart';
import '../../domain/enums/reminder_enums.dart';
import 'settings_section.dart';

class InvoiceReminderHistorySection extends StatelessWidget {
  const InvoiceReminderHistorySection({required this.invoiceId, super.key});

  final String invoiceId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymentReminder>>(
      stream: getIt<PaymentReminderRepository>()
          .watchRemindersForInvoice(invoiceId),
      builder: (context, snapshot) {
        final reminders = snapshot.data ?? const [];

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return SettingsSection(
            title: AppStrings.reminderHistory,
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        if (reminders.isEmpty) {
          return const SizedBox.shrink();
        }

        return SettingsSection(
          title: AppStrings.reminderHistory,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                for (var i = 0; i < reminders.length; i++) ...[
                  _ReminderHistoryRow(reminder: reminders[i]),
                  if (i < reminders.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReminderHistoryRow extends StatelessWidget {
  const _ReminderHistoryRow({required this.reminder});

  final PaymentReminder reminder;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;
    final sentLabel = DateFormat.yMMMd().add_jm().format(reminder.sentAt);
    final channelLabel = switch (reminder.channel) {
      ReminderChannel.whatsapp => AppStrings.reminderViaWhatsApp,
      ReminderChannel.sms => AppStrings.reminderViaSms,
      ReminderChannel.inApp => AppStrings.reminderViaInApp,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  reminder.channel == ReminderChannel.whatsapp
                      ? Icons.chat_outlined
                      : Icons.notifications_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sentLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$channelLabel · ${Formatters.currencyPkr(reminder.amountDue)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
