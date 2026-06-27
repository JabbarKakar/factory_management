import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/payment_reminder.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/reminder_enums.dart';
import '../models/payment_reminder_model.dart';

class PaymentReminderRepository {
  PaymentReminderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get collection =>
      _firestore.collection('paymentReminders');

  Future<PaymentReminder> logReminder({
    required String factoryId,
    required String invoiceId,
    required InvoiceType invoiceType,
    required String customerId,
    required String customerName,
    required String invoiceNumber,
    required double amountDue,
    required String sentBy,
    required ReminderChannel channel,
    DateTime? dueDate,
    String? messagePreview,
  }) async {
    final id = _uuid.v4();
    final model = PaymentReminderModel(
      id: id,
      factoryId: factoryId,
      invoiceId: invoiceId,
      invoiceType: invoiceType.name,
      customerId: customerId,
      customerName: customerName,
      invoiceNumber: invoiceNumber,
      amountDue: amountDue,
      dueDate: dueDate,
      sentAt: DateTime.now(),
      sentBy: sentBy,
      channel: channel.name,
      messagePreview: messagePreview,
    );

    await collection.doc(id).set(model.toFirestore());
    return model.toEntity();
  }

  Stream<List<PaymentReminder>> watchRemindersForInvoice(String invoiceId) {
    return collection
        .where('invoiceId', isEqualTo: invoiceId)
        .snapshots()
        .map((snapshot) {
          final reminders = snapshot.docs
              .map((doc) => PaymentReminderModel.fromFirestore(doc.id, doc.data()))
              .map((model) => model.toEntity())
              .toList();
          reminders.sort((a, b) => b.sentAt.compareTo(a.sentAt));
          return reminders;
        });
  }
}
