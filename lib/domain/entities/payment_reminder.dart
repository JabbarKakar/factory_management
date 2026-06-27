import 'package:equatable/equatable.dart';

import '../enums/invoice_enums.dart';
import '../enums/reminder_enums.dart';

class PaymentReminder extends Equatable {
  const PaymentReminder({
    required this.id,
    required this.factoryId,
    required this.invoiceId,
    required this.invoiceType,
    required this.customerId,
    required this.customerName,
    required this.invoiceNumber,
    required this.amountDue,
    required this.sentAt,
    required this.sentBy,
    required this.channel,
    this.dueDate,
    this.messagePreview,
  });

  final String id;
  final String factoryId;
  final String invoiceId;
  final InvoiceType invoiceType;
  final String customerId;
  final String customerName;
  final String invoiceNumber;
  final double amountDue;
  final DateTime? dueDate;
  final DateTime sentAt;
  final String sentBy;
  final ReminderChannel channel;
  final String? messagePreview;

  @override
  List<Object?> get props => [
        id,
        factoryId,
        invoiceId,
        invoiceType,
        customerId,
        customerName,
        invoiceNumber,
        amountDue,
        dueDate,
        sentAt,
        sentBy,
        channel,
        messagePreview,
      ];
}
