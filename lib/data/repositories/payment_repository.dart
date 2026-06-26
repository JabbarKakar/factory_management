import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/payment.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/sales_enums.dart';
import '../models/payment_model.dart';
import '../services/customer_ledger_service.dart';
import '../services/payment_due_scanner_service.dart';
import 'job_work_invoice_repository.dart';
import 'job_work_repository.dart';
import 'notification_repository.dart';
import 'sales_invoice_repository.dart';
import 'sales_order_repository.dart';

class PaymentRepository {
  PaymentRepository({
    FirebaseFirestore? firestore,
    required JobWorkInvoiceRepository jobWorkInvoiceRepository,
    required SalesInvoiceRepository salesInvoiceRepository,
    required JobWorkRepository jobWorkRepository,
    required SalesOrderRepository salesOrderRepository,
    CustomerLedgerService? ledgerService,
    NotificationRepository? notificationRepository,
    PaymentDueScannerService? scannerService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _jobWorkInvoiceRepository = jobWorkInvoiceRepository,
        _salesInvoiceRepository = salesInvoiceRepository,
        _jobWorkRepository = jobWorkRepository,
        _salesOrderRepository = salesOrderRepository,
        _ledgerService = ledgerService,
        _notificationRepository = notificationRepository,
        _scannerService = scannerService;

  final FirebaseFirestore _firestore;
  final JobWorkInvoiceRepository _jobWorkInvoiceRepository;
  final SalesInvoiceRepository _salesInvoiceRepository;
  final JobWorkRepository _jobWorkRepository;
  final SalesOrderRepository _salesOrderRepository;
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

  Stream<List<Payment>> watchPaymentsForFactory(String factoryId) {
    return _collection
        .where('factoryId', isEqualTo: factoryId)
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

  Future<List<Payment>> getPaymentsForInvoice(String invoiceId) async {
    final snapshot =
        await _collection.where('invoiceId', isEqualTo: invoiceId).get();
    final payments = snapshot.docs
        .map((doc) => PaymentModel.fromFirestore(doc.id, doc.data()).toEntity())
        .toList();
    payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return payments;
  }

  /// Records invoice paid amount in the payments ledger when advance was taken
  /// at booking and no payment row exists yet (feeds dashboard revenue + ledger).
  Future<void> ensureInvoicePaidAmountRecorded({
    required String invoiceId,
    required InvoiceType invoiceType,
  }) async {
    final existing = await getPaymentsForInvoice(invoiceId);
    if (existing.isNotEmpty) return;

    if (invoiceType == InvoiceType.sales) {
      final invoice = await _salesInvoiceRepository.getInvoice(invoiceId);
      if (invoice == null || invoice.paidAmount <= 0) return;
      await _createStandalonePayment(
        factoryId: invoice.factoryId,
        customerId: invoice.customerId,
        customerName: invoice.customerName,
        invoiceId: invoice.id,
        invoiceType: InvoiceType.sales,
        invoiceNumber: invoice.invoiceNumber,
        amount: invoice.paidAmount,
        paymentDate: invoice.createdAt,
        notes: 'Amount received at invoicing (incl. advance)',
      );
      return;
    }

    final invoice = await _jobWorkInvoiceRepository.getInvoice(invoiceId);
    if (invoice == null || invoice.paidAmount <= 0) return;
    await _createStandalonePayment(
      factoryId: invoice.factoryId,
      customerId: invoice.customerId,
      customerName: invoice.customerName,
      invoiceId: invoice.id,
      invoiceType: InvoiceType.jobWork,
      invoiceNumber: invoice.invoiceNumber,
      amount: invoice.paidAmount,
      paymentDate: invoice.createdAt,
      notes: 'Amount received at invoicing (incl. advance)',
    );
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

    final invoice = await _jobWorkInvoiceRepository.getInvoice(invoiceId);
    if (invoice == null) {
      throw StateError('Invoice not found.');
    }
    if (invoice.dueAmount <= 0) {
      throw StateError('This invoice is already fully paid.');
    }

    final appliedAmount =
        amount > invoice.dueAmount ? invoice.dueAmount : amount;
    final newPaid = invoice.paidAmount + appliedAmount;
    final newDue = invoice.dueAmount - appliedAmount;
    final newStatus = InvoiceStatus.fromAmounts(
      dueAmount: newDue,
      paidAmount: newPaid,
      totalAmount: invoice.totalAmount,
      dueDate: invoice.dueDate,
    );

    final payment = await _recordPayment(
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
      invoiceCollection: _jobWorkInvoiceRepository.collection,
      invoiceUpdate: {
        'paid': newPaid,
        'due': newDue,
        'status': newStatus.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      onFullyPaid: newDue <= 0
          ? () => _jobWorkRepository.jobWorkDoc(invoice.jobWorkId).update({
                'status': JobWorkStatus.paid.firestoreValue,
                'updatedAt': FieldValue.serverTimestamp(),
              })
          : null,
    );

    await _ledgerService?.syncCustomerBalance(invoice.customerId);

    if (newDue > 0 &&
        _notificationRepository != null &&
        _scannerService != null) {
      final updatedInvoice = await _jobWorkInvoiceRepository.getInvoice(invoiceId);
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

  Future<Payment> recordSalesPayment({
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

    final invoice = await _salesInvoiceRepository.getInvoice(invoiceId);
    if (invoice == null) {
      throw StateError('Invoice not found.');
    }
    if (invoice.dueAmount <= 0) {
      throw StateError('This invoice is already fully paid.');
    }

    final appliedAmount =
        amount > invoice.dueAmount ? invoice.dueAmount : amount;
    final newPaid = invoice.paidAmount + appliedAmount;
    final newDue = invoice.dueAmount - appliedAmount;
    final newStatus = InvoiceStatus.fromAmounts(
      dueAmount: newDue,
      paidAmount: newPaid,
      totalAmount: invoice.totalAmount,
      dueDate: invoice.dueDate,
    );

    final payment = await _recordPayment(
      factoryId: invoice.factoryId,
      customerId: invoice.customerId,
      customerName: invoice.customerName,
      invoiceId: invoice.id,
      invoiceType: InvoiceType.sales,
      invoiceNumber: invoice.invoiceNumber,
      amount: appliedAmount,
      method: method,
      paymentDate: paymentDate,
      reference: reference,
      notes: notes,
      invoiceCollection: _salesInvoiceRepository.collection,
      invoiceUpdate: {
        'paid': newPaid,
        'due': newDue,
        'status': newStatus.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      onFullyPaid: newDue <= 0
          ? () => _salesOrderRepository.salesOrderDoc(invoice.salesOrderId).update({
                'status': SalesOrderStatus.paid.firestoreValue,
                'updatedAt': FieldValue.serverTimestamp(),
              })
          : null,
    );

    await _ledgerService?.syncCustomerBalance(invoice.customerId);

    if (newDue > 0 &&
        _notificationRepository != null &&
        _scannerService != null) {
      final updatedInvoice = await _salesInvoiceRepository.getInvoice(invoiceId);
      if (updatedInvoice != null) {
        await _notificationRepository.createNotification(
          _scannerService.buildSalesPartialPaymentNotification(
            invoice: updatedInvoice,
            amountPaid: appliedAmount,
            remainingDue: newDue,
          ),
        );
      }
    }

    return payment;
  }

  Future<Payment> _recordPayment({
    required String factoryId,
    required String customerId,
    required String customerName,
    required String invoiceId,
    required InvoiceType invoiceType,
    required String invoiceNumber,
    required double amount,
    required PaymentMethod method,
    required DateTime paymentDate,
    required CollectionReference<Map<String, dynamic>> invoiceCollection,
    required Map<String, dynamic> invoiceUpdate,
    Future<void> Function()? onFullyPaid,
    String? reference,
    String? notes,
  }) async {
    final paymentId = _uuid.v4();
    final payment = Payment(
      id: paymentId,
      factoryId: factoryId,
      customerId: customerId,
      customerName: customerName,
      invoiceId: invoiceId,
      invoiceType: invoiceType,
      invoiceNumber: invoiceNumber,
      amount: amount,
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

    batch.update(invoiceCollection.doc(invoiceId), invoiceUpdate);
    await batch.commit();

    if (onFullyPaid != null) {
      await onFullyPaid();
    }

    return payment;
  }

  Future<Payment> _createStandalonePayment({
    required String factoryId,
    required String customerId,
    required String customerName,
    required String invoiceId,
    required InvoiceType invoiceType,
    required String invoiceNumber,
    required double amount,
    required DateTime paymentDate,
    PaymentMethod method = PaymentMethod.cash,
    String? reference,
    String? notes,
  }) async {
    final paymentId = _uuid.v4();
    final payment = Payment(
      id: paymentId,
      factoryId: factoryId,
      customerId: customerId,
      customerName: customerName,
      invoiceId: invoiceId,
      invoiceType: invoiceType,
      invoiceNumber: invoiceNumber,
      amount: amount,
      method: method,
      paymentDate: paymentDate,
      reference: reference,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await _collection.doc(paymentId).set(
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

    return payment;
  }
}
