import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/payment_reminder_repository.dart';
import '../../domain/entities/payment_reminder.dart';
import '../../domain/enums/reminder_enums.dart';
import 'job_work/job_work_detail_section.dart';

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
          return JobWorkDetailSection(
            title: AppStrings.reminderHistory,
            icon: Icons.notifications_outlined,
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        if (reminders.isEmpty) {
          return const SizedBox.shrink();
        }

        return JobWorkDetailSection(
          title: AppStrings.reminderHistory,
          icon: Icons.notifications_outlined,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
    final sentLabel = DateFormat.yMMMd().add_jm().format(reminder.sentAt);
    final channelLabel = switch (reminder.channel) {
      ReminderChannel.whatsapp => AppStrings.reminderViaWhatsApp,
      ReminderChannel.sms => AppStrings.reminderViaSms,
      ReminderChannel.inApp => AppStrings.reminderViaInApp,
    };
    final icon = reminder.channel == ReminderChannel.whatsapp
        ? Icons.chat_outlined
        : Icons.notifications_outlined;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sentLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$channelLabel · ${Formatters.currencyPkr(reminder.amountDue)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: muted,
                        fontSize: 10,
                        height: 1.2,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
