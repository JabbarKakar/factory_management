import '../../domain/entities/payment_reminder.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/reminder_enums.dart';

class PaymentReminderModel {
  const PaymentReminderModel({
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
  final String invoiceType;
  final String customerId;
  final String customerName;
  final String invoiceNumber;
  final double amountDue;
  final DateTime? dueDate;
  final DateTime sentAt;
  final String sentBy;
  final String channel;
  final String? messagePreview;

  factory PaymentReminderModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return PaymentReminderModel(
      id: id,
      factoryId: data['factoryId'] as String? ?? '',
      invoiceId: data['invoiceId'] as String? ?? '',
      invoiceType: data['invoiceType'] as String? ?? InvoiceType.jobWork.name,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      invoiceNumber: data['invoiceNumber'] as String? ?? '',
      amountDue: (data['amountDue'] as num?)?.toDouble() ?? 0,
      dueDate: (data['dueDate'] as dynamic)?.toDate() as DateTime?,
      sentAt: (data['sentAt'] as dynamic)?.toDate() as DateTime? ??
          DateTime.now(),
      sentBy: data['sentBy'] as String? ?? '',
      channel: data['channel'] as String? ?? ReminderChannel.whatsapp.name,
      messagePreview: data['messagePreview'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'factoryId': factoryId,
      'invoiceId': invoiceId,
      'invoiceType': invoiceType,
      'customerId': customerId,
      'customerName': customerName,
      'invoiceNumber': invoiceNumber,
      'amountDue': amountDue,
      if (dueDate != null) 'dueDate': dueDate,
      'sentAt': sentAt,
      'sentBy': sentBy,
      'channel': channel,
      if (messagePreview != null) 'messagePreview': messagePreview,
    };
  }

  PaymentReminder toEntity() {
    return PaymentReminder(
      id: id,
      factoryId: factoryId,
      invoiceId: invoiceId,
      invoiceType: InvoiceType.values.firstWhere(
        (type) => type.name == invoiceType,
        orElse: () => InvoiceType.jobWork,
      ),
      customerId: customerId,
      customerName: customerName,
      invoiceNumber: invoiceNumber,
      amountDue: amountDue,
      dueDate: dueDate,
      sentAt: sentAt,
      sentBy: sentBy,
      channel: ReminderChannel.fromString(channel),
      messagePreview: messagePreview,
    );
  }

  factory PaymentReminderModel.fromEntity(PaymentReminder reminder) {
    return PaymentReminderModel(
      id: reminder.id,
      factoryId: reminder.factoryId,
      invoiceId: reminder.invoiceId,
      invoiceType: reminder.invoiceType.name,
      customerId: reminder.customerId,
      customerName: reminder.customerName,
      invoiceNumber: reminder.invoiceNumber,
      amountDue: reminder.amountDue,
      dueDate: reminder.dueDate,
      sentAt: reminder.sentAt,
      sentBy: reminder.sentBy,
      channel: reminder.channel.name,
      messagePreview: reminder.messagePreview,
    );
  }
}
