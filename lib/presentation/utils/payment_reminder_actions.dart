import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../../data/services/payment_reminder_service.dart';
import '../../domain/enums/invoice_enums.dart';
import '../utils/auth_context.dart';

abstract final class PaymentReminderActions {
  static Future<void> sendWhatsApp({
    required BuildContext context,
    required String customerId,
    required String customerName,
    required String invoiceId,
    required String invoiceNumber,
    required InvoiceType invoiceType,
    required double amountDue,
    DateTime? dueDate,
    bool isOverdue = false,
  }) async {
    final factoryId = readFactoryId(context);
    final authState = context.read<AuthBloc>().state;
    if (factoryId == null || authState is! AuthAuthenticated) {
      throw StateError('Not signed in');
    }

    await getIt<PaymentReminderService>().sendWhatsAppReminder(
      factoryId: factoryId,
      sentByUserId: authState.user.id,
      customerId: customerId,
      customerName: customerName,
      invoiceId: invoiceId,
      invoiceNumber: invoiceNumber,
      invoiceType: invoiceType,
      amountDue: amountDue,
      dueDate: dueDate,
      isOverdue: isOverdue,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.paymentReminderSent)),
      );
    }
  }

  static void showError(BuildContext context, [Object? error]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.paymentReminderFailed),
      ),
    );
  }
}
