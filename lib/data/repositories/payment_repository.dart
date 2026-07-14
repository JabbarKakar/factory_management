import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/payment.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/sales_enums.dart';
import '../models/payment_model.dart';
import '../services/customer_ledger_service.dart';
import '../services/job_work_container_sync_helper.dart';
import '../services/payment_due_scanner_service.dart';
import 'job_work_invoice_repository.dart';
import 'job_work_load_repository.dart';
import 'job_work_repository.dart';
import 'notification_repository.dart';
import 'sales_invoice_repository.dart';
import 'sales_order_repository.dart';

class PaymentException implements Exception {
  const PaymentException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PaymentRepository {
  PaymentRepository({
    FirebaseFirestore? firestore,
    required JobWorkInvoiceRepository jobWorkInvoiceRepository,
    required SalesInvoiceRepository salesInvoiceRepository,
    required JobWorkRepository jobWorkRepository,
    required JobWorkLoadRepository jobWorkLoadRepository,
    required SalesOrderRepository salesOrderRepository,
    CustomerLedgerService? ledgerService,
    NotificationRepository? notificationRepository,
    PaymentDueScannerService? scannerService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _jobWorkInvoiceRepository = jobWorkInvoiceRepository,
        _salesInvoiceRepository = salesInvoiceRepository,
        _jobWorkRepository = jobWorkRepository,
        _jobWorkLoadRepository = jobWorkLoadRepository,
        _salesOrderRepository = salesOrderRepository,
        _ledgerService = ledgerService,
        _notificationRepository = notificationRepository,
        _scannerService = scannerService;

  final FirebaseFirestore _firestore;
  final JobWorkInvoiceRepository _jobWorkInvoiceRepository;
  final SalesInvoiceRepository _salesInvoiceRepository;
  final JobWorkRepository _jobWorkRepository;
  final JobWorkLoadRepository _jobWorkLoadRepository;
  final SalesOrderRepository _salesOrderRepository;
  final CustomerLedgerService? _ledgerService;
  final NotificationRepository? _notificationRepository;
  final PaymentDueScannerService? _scannerService;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('payments');

  Future<List<Payment>> getPaymentsForCustomer({
    required String factoryId,
    required String customerId,
  }) async {
    final snapshot = await _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('customerId', isEqualTo: customerId)
        .get();
    final payments = snapshot.docs
        .map((doc) => PaymentModel.fromFirestore(doc.id, doc.data()).toEntity())
        .toList();
    payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return payments;
  }

  Stream<List<Payment>> watchPaymentsForCustomer({
    required String factoryId,
    required String customerId,
  }) {
    return _collection
        .where('factoryId', isEqualTo: factoryId)
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

  Future<List<Payment>> getPaymentsForInvoice({
    required String factoryId,
    required String invoiceId,
  }) async {
    final snapshot = await _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('invoiceId', isEqualTo: invoiceId)
        .get();
    final payments = snapshot.docs
        .map((doc) => PaymentModel.fromFirestore(doc.id, doc.data()).toEntity())
        .toList();
    payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return payments;
  }

  Stream<List<Payment>> watchPaymentsForInvoice({
    required String factoryId,
    required String invoiceId,
  }) {
    return _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('invoiceId', isEqualTo: invoiceId)
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

  Future<Payment?> getPayment(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return PaymentModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Future<Payment> updatePayment({
    required String paymentId,
    required double amount,
    required PaymentMethod method,
    required DateTime paymentDate,
    String? reference,
    String? notes,
  }) async {
    if (amount <= 0) {
      throw const PaymentException('Payment amount must be greater than zero.');
    }

    final existing = await getPayment(paymentId);
    if (existing == null) {
      throw const PaymentException('Payment not found.');
    }

    final invoice = await _getInvoiceForPayment(existing);
    if (invoice == null) {
      throw const PaymentException('Invoice not found.');
    }

    final otherPayments = await getPaymentsForInvoice(
      factoryId: existing.factoryId,
      invoiceId: existing.invoiceId,
    );
    final otherTotal = otherPayments
        .where((payment) => payment.id != paymentId)
        .fold<double>(0, (sum, payment) => sum + payment.amount);
    if (otherTotal + amount > invoice.totalAmount + 0.01) {
      throw PaymentException(
        'Payment total cannot exceed invoice amount '
        '(${invoice.totalAmount.toStringAsFixed(0)}).',
      );
    }

    final updated = Payment(
      id: existing.id,
      factoryId: existing.factoryId,
      customerId: existing.customerId,
      customerName: existing.customerName,
      invoiceId: existing.invoiceId,
      invoiceType: existing.invoiceType,
      invoiceNumber: existing.invoiceNumber,
      amount: amount,
      method: method,
      paymentDate: paymentDate,
      reference: reference?.trim().isEmpty ?? true ? null : reference?.trim(),
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      createdAt: existing.createdAt,
    );

    final updates = <String, dynamic>{
      'amount': updated.amount,
      'method': updated.method.firestoreValue,
      'date': Timestamp.fromDate(updated.paymentDate),
    };
    if (updated.reference == null) {
      updates['reference'] = FieldValue.delete();
    } else {
      updates['reference'] = updated.reference;
    }
    if (updated.notes == null) {
      updates['notes'] = FieldValue.delete();
    } else {
      updates['notes'] = updated.notes;
    }

    await _collection.doc(paymentId).update(updates);
    await _syncInvoiceFromPayments(
      invoiceId: existing.invoiceId,
      invoiceType: existing.invoiceType,
    );

    return updated;
  }

  Future<void> deletePayment(String paymentId) async {
    final existing = await getPayment(paymentId);
    if (existing == null) {
      throw const PaymentException('Payment not found.');
    }

    await _collection.doc(paymentId).delete();
    await _syncInvoiceFromPayments(
      invoiceId: existing.invoiceId,
      invoiceType: existing.invoiceType,
    );
  }

  Future<_InvoiceSnapshot?> _getInvoiceForPayment(Payment payment) async {
    if (payment.invoiceType == InvoiceType.jobWork) {
      final invoice =
          await _jobWorkInvoiceRepository.getInvoice(payment.invoiceId);
      if (invoice == null) return null;
      return _InvoiceSnapshot(
        id: invoice.id,
        factoryId: invoice.factoryId,
        customerId: invoice.customerId,
        totalAmount: invoice.totalAmount,
        dueDate: invoice.dueDate,
        parentId: invoice.jobWorkId,
        invoiceType: InvoiceType.jobWork,
      );
    }

    final invoice = await _salesInvoiceRepository.getInvoice(payment.invoiceId);
    if (invoice == null) return null;
    return _InvoiceSnapshot(
      id: invoice.id,
      factoryId: invoice.factoryId,
      customerId: invoice.customerId,
      totalAmount: invoice.totalAmount,
      dueDate: invoice.dueDate,
      parentId: invoice.salesOrderId,
      invoiceType: InvoiceType.sales,
    );
  }

  Future<void> _syncInvoiceFromPayments({
    required String invoiceId,
    required InvoiceType invoiceType,
  }) async {
    if (invoiceType == InvoiceType.jobWork) {
      final invoice = await _jobWorkInvoiceRepository.getInvoice(invoiceId);
      if (invoice == null) return;

      final payments = await getPaymentsForInvoice(
        factoryId: invoice.factoryId,
        invoiceId: invoiceId,
      );
      final paidAmount =
          payments.fold<double>(0, (sum, payment) => sum + payment.amount);
      final dueAmount = (invoice.totalAmount - paidAmount).clamp(0, invoice.totalAmount);
      final status = InvoiceStatus.fromAmounts(
        dueAmount: dueAmount.toDouble(),
        paidAmount: paidAmount,
        totalAmount: invoice.totalAmount,
        dueDate: invoice.dueDate,
      );

      await _jobWorkInvoiceRepository.collection.doc(invoiceId).update({
        'paid': paidAmount,
        'due': dueAmount,
        'status': status.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final loadId = invoice.loadId?.trim();
      if (loadId != null && loadId.isNotEmpty) {
        final load = await _jobWorkLoadRepository.getLoad(loadId);
        if (load != null) {
          final loadUpdates = <String, dynamic>{
            'pricing.advanceReceived': paidAmount,
            'pricing.balanceDue': dueAmount.toDouble(),
            'updatedAt': FieldValue.serverTimestamp(),
          };
          final financeStatus =
              JobWorkContainerSyncHelper.financeStatusForLoad(
            load: load,
            dueAmount: dueAmount.toDouble(),
          );
          if (financeStatus != null) {
            loadUpdates['status'] = financeStatus.firestoreValue;
          }
          await _jobWorkLoadRepository.loadDoc(loadId).update(loadUpdates);
          await _jobWorkLoadRepository
              .refreshContainerFromLoads(invoice.jobWorkId);
        }
      } else {
        final order =
            await _jobWorkRepository.getJobWorkOrder(invoice.jobWorkId);
        if (order == null) return;
        // Sprint 7: migrated containers get money only via Loads; skip JW patches.
        if (order.isLoadsAuthoritative) {
          await _jobWorkLoadRepository
              .refreshContainerFromLoads(invoice.jobWorkId);
        } else {
          await _jobWorkRepository.jobWorkDoc(invoice.jobWorkId).update({
            'pricing.advanceReceived': paidAmount,
            'pricing.balanceDue': dueAmount.toDouble(),
            if (dueAmount <= 0 &&
                order.status != JobWorkStatus.paid &&
                !order.status.isCollectionStatus)
              'status': JobWorkStatus.paid.firestoreValue,
            if (dueAmount > 0 && order.status == JobWorkStatus.paid)
              'status': JobWorkStatus.invoiced.firestoreValue,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await _ledgerService?.syncCustomerBalance(invoice.customerId);
      return;
    }

    final invoice = await _salesInvoiceRepository.getInvoice(invoiceId);
    if (invoice == null) return;

    final payments = await getPaymentsForInvoice(
      factoryId: invoice.factoryId,
      invoiceId: invoiceId,
    );
    final paidAmount =
        payments.fold<double>(0, (sum, payment) => sum + payment.amount);
    final dueAmount = (invoice.totalAmount - paidAmount).clamp(0, invoice.totalAmount);
    final status = InvoiceStatus.fromAmounts(
      dueAmount: dueAmount.toDouble(),
      paidAmount: paidAmount,
      totalAmount: invoice.totalAmount,
      dueDate: invoice.dueDate,
    );

    await _salesInvoiceRepository.collection.doc(invoiceId).update({
      'paid': paidAmount,
      'due': dueAmount,
      'status': status.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final order = await _salesOrderRepository.getSalesOrder(invoice.salesOrderId);
    if (order != null) {
      if (dueAmount <= 0 && order.status != SalesOrderStatus.paid) {
        await _salesOrderRepository.salesOrderDoc(invoice.salesOrderId).update({
          'status': SalesOrderStatus.paid.firestoreValue,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (dueAmount > 0 && order.status == SalesOrderStatus.paid) {
        await _salesOrderRepository.salesOrderDoc(invoice.salesOrderId).update({
          'status': SalesOrderStatus.invoiced.firestoreValue,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await _ledgerService?.syncCustomerBalance(invoice.customerId);
  }

  /// Records invoice paid amount in the payments ledger when advance was taken
  /// at booking and no payment row exists yet (feeds dashboard revenue + ledger).
  Future<void> ensureInvoicePaidAmountRecorded({
    required String invoiceId,
    required InvoiceType invoiceType,
  }) async {
    if (invoiceType == InvoiceType.sales) {
      final invoice = await _salesInvoiceRepository.getInvoice(invoiceId);
      if (invoice == null || invoice.paidAmount <= 0) return;
      final existing = await getPaymentsForInvoice(
        factoryId: invoice.factoryId,
        invoiceId: invoiceId,
      );
      if (existing.isNotEmpty) return;
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
    final existing = await getPaymentsForInvoice(
      factoryId: invoice.factoryId,
      invoiceId: invoiceId,
    );
    if (existing.isNotEmpty) return;
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
    );

    // Sync Load finance + JW rollup (or legacy JW finance when no loadId).
    await _syncInvoiceFromPayments(
      invoiceId: invoice.id,
      invoiceType: InvoiceType.jobWork,
    );

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

class _InvoiceSnapshot {
  const _InvoiceSnapshot({
    required this.id,
    required this.factoryId,
    required this.customerId,
    required this.totalAmount,
    required this.parentId,
    required this.invoiceType,
    this.dueDate,
  });

  final String id;
  final String factoryId;
  final String customerId;
  final double totalAmount;
  final DateTime? dueDate;
  final String parentId;
  final InvoiceType invoiceType;
}
