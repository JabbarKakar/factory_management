import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/payment.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/job_work_enums.dart';
import '../models/payment_model.dart';
import '../services/customer_ledger_service.dart';
import '../services/payment_due_scanner_service.dart';
import 'job_work_invoice_repository.dart';
import 'job_work_repository.dart';
import 'notification_repository.dart';

class PaymentRepository {
  PaymentRepository({
    FirebaseFirestore? firestore,
    required JobWorkInvoiceRepository invoiceRepository,
    required JobWorkRepository jobWorkRepository,
    CustomerLedgerService? ledgerService,
    NotificationRepository? notificationRepository,
    PaymentDueScannerService? scannerService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _invoiceRepository = invoiceRepository,
        _jobWorkRepository = jobWorkRepository,
        _ledgerService = ledgerService,
        _notificationRepository = notificationRepository,
        _scannerService = scannerService;

  final FirebaseFirestore _firestore;
  final JobWorkInvoiceRepository _invoiceRepository;
  final JobWorkRepository _jobWorkRepository;
  final CustomerLedgerService? _ledgerService;
  final NotificationRepository? _notificationRepository;
  final PaymentDueScannerService? _scannerService;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('payments');

  Future<List<Payment>> getPaymentsForCustomer(String customerId) async {
    final snapshot =
        await _collection.where('customerId', isEqualTo: customerId).get();
    final payments = snapshot.docs
        .map((doc) => PaymentModel.fromFirestore(doc.id, doc.data()).toEntity())
        .toList();
    payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return payments;
  }

  Stream<List<Payment>> watchPaymentsForCustomer(String customerId) {
    return _collection
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final payments = snapshot.docs
              .map((doc) =>
                  PaymentModel.fromFirestore(doc.id, doc.data()).toEntity())
              .toList();
          payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
          return payments;
        });
  }

  Future<Payment> recordJobWorkPayment({
    required String invoiceId,
    required double amount,
    required PaymentMethod method,
    required DateTime paymentDate,
    String? reference,
    String? notes,
  }) async {
    if (amount <= 0) {
      throw StateError('Payment amount must be greater than zero.');
    }

    final invoice = await _invoiceRepository.getInvoice(invoiceId);
    if (invoice == null) {
      throw StateError('Invoice not found.');
    }
    if (invoice.dueAmount <= 0) {
      throw StateError('This invoice is already fully paid.');
    }

    final appliedAmount = amount > invoice.dueAmount ? invoice.dueAmount : amount;
    final newPaid = invoice.paidAmount + appliedAmount;
    final newDue = invoice.dueAmount - appliedAmount;
    final newStatus = InvoiceStatus.fromAmounts(
      dueAmount: newDue,
      paidAmount: newPaid,
      totalAmount: invoice.totalAmount,
      dueDate: invoice.dueDate,
    );

    final paymentId = _uuid.v4();
    final payment = Payment(
      id: paymentId,
      factoryId: invoice.factoryId,
      customerId: invoice.customerId,
      customerName: invoice.customerName,
      invoiceId: invoice.id,
      invoiceType: InvoiceType.jobWork,
      invoiceNumber: invoice.invoiceNumber,
      amount: appliedAmount,
      method: method,
      paymentDate: paymentDate,
      reference: reference,
      notes: notes,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(
      _collection.doc(paymentId),
      PaymentModel(
        id: paymentId,
        factoryId: payment.factoryId,
        customerId: payment.customerId,
        customerName: payment.customerName,
        invoiceId: payment.invoiceId,
        invoiceType: payment.invoiceType,
        invoiceNumber: payment.invoiceNumber,
        amount: payment.amount,
        method: payment.method,
        paymentDate: payment.paymentDate,
        reference: payment.reference,
        notes: payment.notes,
        createdAt: payment.createdAt,
      ).toFirestore(isCreate: true),
    );

    batch.update(_invoiceRepository.collection.doc(invoiceId), {
      'paid': newPaid,
      'due': newDue,
      'status': newStatus.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (newDue <= 0) {
      batch.update(_jobWorkRepository.jobWorkDoc(invoice.jobWorkId), {
        'status': JobWorkStatus.paid.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    await _ledgerService?.syncCustomerBalance(invoice.customerId);

    if (newDue > 0 && _notificationRepository != null && _scannerService != null) {
      final updatedInvoice = await _invoiceRepository.getInvoice(invoiceId);
      if (updatedInvoice != null) {
        await _notificationRepository.createNotification(
          _scannerService.buildPartialPaymentNotification(
            invoice: updatedInvoice,
            amountPaid: appliedAmount,
            remainingDue: newDue,
          ),
        );
      }
    }

    return payment;
  }
}
