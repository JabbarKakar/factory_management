import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/observability/tracked_firestore.dart';
import '../../core/utils/firestore_query_constraints.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/payment.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/job_work_enums.dart';
import '../models/job_work_invoice_model.dart';
import '../models/job_work_load_model.dart';
import '../models/job_work_order_model.dart';
import '../models/payment_model.dart';
import '../models/sales_invoice_model.dart';
import '../services/customer_ledger_service.dart';
import '../services/dashboard_rollup_service.dart';
import '../services/job_work_container_sync_helper.dart';
import '../services/payment_due_scanner_service.dart';
import '../services/sales_container_sync_helper.dart';
import 'job_work_invoice_repository.dart';
import 'job_work_load_repository.dart';
import 'job_work_repository.dart';
import 'notification_repository.dart';
import 'sales_agreement_repository.dart';
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
    SalesAgreementRepository? salesAgreementRepository,
    CustomerLedgerService? ledgerService,
    NotificationRepository? notificationRepository,
    PaymentDueScannerService? scannerService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _jobWorkInvoiceRepository = jobWorkInvoiceRepository,
        _salesInvoiceRepository = salesInvoiceRepository,
        _jobWorkRepository = jobWorkRepository,
        _jobWorkLoadRepository = jobWorkLoadRepository,
        _salesOrderRepository = salesOrderRepository,
        _salesAgreementRepository = salesAgreementRepository ??
            SalesAgreementRepository(firestore: firestore),
        _ledgerService = ledgerService,
        _notificationRepository = notificationRepository,
        _scannerService = scannerService;

  final FirebaseFirestore _firestore;
  final JobWorkInvoiceRepository _jobWorkInvoiceRepository;
  final SalesInvoiceRepository _salesInvoiceRepository;
  final JobWorkRepository _jobWorkRepository;
  final JobWorkLoadRepository _jobWorkLoadRepository;
  final SalesOrderRepository _salesOrderRepository;
  final SalesAgreementRepository _salesAgreementRepository;
  final CustomerLedgerService? _ledgerService;
  final NotificationRepository? _notificationRepository;
  final PaymentDueScannerService? _scannerService;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      trackedCollection(_firestore, 'payments');

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

  Stream<List<Payment>> watchPaymentsForFactory(
    String factoryId, {
    DateTime? from,
    int? limit,
  }) {
    return constrainFactoryQuery(
      _collection.where('factoryId', isEqualTo: factoryId),
      // PaymentModel persists the instant as `date`, not `paymentDate`.
      dateField: from == null ? null : 'date',
      from: from,
      limit: limit,
    ).snapshots().map((snapshot) {
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

  /// Watch payments linked to a Job Work order (by orderId).
  Stream<List<Payment>> watchPaymentsForOrder({
    required String factoryId,
    required String orderId,
  }) {
    return _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('orderId', isEqualTo: orderId)
        .snapshots()
        .map((snapshot) {
          final payments = snapshot.docs
              .map((doc) =>
                  PaymentModel.fromFirestore(doc.id, doc.data()).toEntity())
              .where((p) => p.status != PaymentStatus.voided)
              .toList();
          payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
          return payments;
        });
  }

  /// Watch advance payments linked to a Job Work order (by orderId).
  /// These payments have an empty invoiceId and are tagged with isAdvance.
  Stream<List<Payment>> watchAdvancePaymentsForOrder({
    required String factoryId,
    required String orderId,
  }) {
    return watchPaymentsForOrder(factoryId: factoryId, orderId: orderId).map(
      (payments) => payments.where((p) => p.isAdvance).toList(),
    );
  }

  Future<Payment?> getPayment(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return PaymentModel.fromFirestore(doc.id, doc.data()!).toEntity();
    } catch (_) {
      return null;
    }
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

    if (existing.isCreditApplication) {
      throw const PaymentException(
        'Credit applications cannot be edited. Delete and re-apply the credit.',
      );
    }

    final invoice = await _getInvoiceForPayment(existing);
    if (invoice == null) {
      throw const PaymentException('Invoice not found.');
    }

    final otherPayments = await getPaymentsForInvoice(
      factoryId: existing.factoryId,
      invoiceId: existing.invoiceId,
    );
    final others = otherPayments.where((payment) => payment.id != paymentId);
    var appliedCap = invoice.totalAmount -
        others.fold<double>(0, (sum, payment) => sum + payment.appliedAmount);
    final existingLoadId = existing.loadId?.trim();
    if (existingLoadId != null && existingLoadId.isNotEmpty) {
      final load = await _jobWorkLoadRepository.getLoad(existingLoadId);
      if (load != null) {
        final othersOnLoad = others.where(
          (payment) => payment.loadId == existingLoadId,
        );
        appliedCap = load.finalCuttingCharges -
            othersOnLoad.fold<double>(
              0,
              (sum, payment) => sum + payment.appliedAmount,
            );
      }
    }
    final newApplied = _roundMoney(
      amount < appliedCap.clamp(0.0, double.infinity)
          ? amount
          : appliedCap.clamp(0.0, double.infinity).toDouble(),
    );

    final updated = Payment(
      id: existing.id,
      factoryId: existing.factoryId,
      customerId: existing.customerId,
      customerName: existing.customerName,
      invoiceId: existing.invoiceId,
      invoiceType: existing.invoiceType,
      invoiceNumber: existing.invoiceNumber,
      amount: amount,
      appliedAmount: newApplied,
      method: method,
      paymentDate: paymentDate,
      reference: reference?.trim().isEmpty ?? true ? null : reference?.trim(),
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      createdAt: existing.createdAt,
      isAdvance: existing.isAdvance,
      orderId: existing.orderId,
      loadId: existing.loadId,
      status: existing.status,
    );

    final updates = <String, dynamic>{
      'amount': updated.amount,
      'appliedAmount': updated.appliedAmount,
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
    await applyDashboardRollup(
      (service) => service.applyPayment(payment: updated, previous: existing),
    );
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

    // Only decrement/adjust advanceReceived if the payment being deleted was actually an advance deposit
    if (existing.isAdvance || paymentId.startsWith('advance_')) {
      if (existing.invoiceType == InvoiceType.jobWork) {
        final invoice =
            await _jobWorkInvoiceRepository.getInvoice(existing.invoiceId);
        final loadId = existing.loadId ??
            (paymentId.startsWith('advance_load_')
                ? paymentId.replaceAll('advance_load_', '').trim()
                : invoice?.loadId?.trim());

        if (loadId != null && loadId.isNotEmpty) {
          final load = await _jobWorkLoadRepository.getLoad(loadId);
          if (load != null) {
            final updatedAdvance = (load.advanceReceived - existing.amount)
                .clamp(0.0, double.infinity);
            await _jobWorkLoadRepository.loadDoc(loadId).update({
              'pricing.advanceReceived': updatedAdvance,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      } else if (existing.invoiceType == InvoiceType.sales) {
        final orderId = existing.orderId ??
            (paymentId.startsWith('advance_sales_')
                ? paymentId.replaceAll('advance_sales_', '').trim()
                : null);
        if (orderId != null && orderId.isNotEmpty) {
          final order = await _salesOrderRepository.getSalesOrder(orderId);
          if (order != null) {
            final updatedAdvance = (order.advanceReceived - existing.amount)
                .clamp(0.0, double.infinity);
            await _salesOrderRepository.salesOrderDoc(orderId).update({
              'advanceReceived': updatedAdvance,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    }

    await _syncInvoiceFromPayments(
      invoiceId: existing.invoiceId,
      invoiceType: existing.invoiceType,
    );
    await applyDashboardRollup(
      (service) => service.applyPayment(payment: existing, deleted: true),
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
    bool repair = true,
  }) async {
    if (invoiceType == InvoiceType.jobWork) {
      final invoice = await _jobWorkInvoiceRepository.getInvoice(invoiceId);
      if (invoice == null) return;

      if (!repair) {
        var containerId = invoice.jobWorkId;
        final linkedLoadId = invoice.loadId?.trim();
        if (linkedLoadId != null && linkedLoadId.isNotEmpty) {
          final load = await _jobWorkLoadRepository.getLoad(linkedLoadId);
          if (load != null && load.jobWorkId.trim().isNotEmpty) {
            containerId = load.jobWorkId;
          }
        }
        await _jobWorkLoadRepository.refreshContainerFromLoads(containerId);
        await _ledgerService?.syncCustomerBalance(invoice.customerId);
        return;
      }

      final payments = await getPaymentsForInvoice(
        factoryId: invoice.factoryId,
        invoiceId: invoiceId,
      );
      var paidAmount = _appliedSum(payments);

      final loadId = invoice.loadId?.trim();
      if (loadId != null && loadId.isNotEmpty) {
        final advanceId = 'advance_load_$loadId';
        DocumentSnapshot<Map<String, dynamic>>? advanceDoc;
        try {
          advanceDoc = await _firestore.collection('payments').doc(advanceId).get();
        } catch (_) {}
        if (advanceDoc != null && advanceDoc.exists) {
          final isAlreadyCounted = payments.any((p) => p.id == advanceId);
          if (!isAlreadyCounted) {
            final data = advanceDoc.data();
            paidAmount += (data?['appliedAmount'] as num?)?.toDouble() ??
                (data?['amount'] as num?)?.toDouble() ??
                0.0;
          }
        }
      }

      // Resolve effective total in case Firestore doc has stale totalAmount.
      final effectiveInvoice = await _resolveEffectiveInvoice(invoice);
      final effectiveTotal = effectiveInvoice.totalAmount;

      final dueAmount = (effectiveTotal - paidAmount).clamp(0, effectiveTotal);
      final status = InvoiceStatus.fromAmounts(
        dueAmount: dueAmount.toDouble(),
        paidAmount: paidAmount,
        totalAmount: effectiveTotal,
        dueDate: invoice.dueDate,
      );

      final invoiceAlreadySynced =
          _sameMoney(invoice.totalAmount, effectiveTotal) &&
              _sameMoney(invoice.paidAmount, paidAmount) &&
              _sameMoney(invoice.dueAmount, dueAmount.toDouble()) &&
              invoice.status == status;
      if (!invoiceAlreadySynced) {
        await _jobWorkInvoiceRepository.collection.doc(invoiceId).update({
          'total': effectiveTotal,
          'paid': paidAmount,
          'due': dueAmount,
          'status': status.firestoreValue,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Sync Grand Invoice for the Job Work container if one exists.
      await _jobWorkInvoiceRepository.syncGrandInvoice(
        factoryId: invoice.factoryId,
        jobWorkId: invoice.jobWorkId,
      );

      if (loadId != null && loadId.isNotEmpty) {
        final load = await _jobWorkLoadRepository.getLoad(loadId);
        if (load != null) {
          final financeStatus =
              JobWorkContainerSyncHelper.financeStatusForLoad(
            load: load,
            dueAmount: dueAmount.toDouble(),
          );
          final loadAlreadySynced =
              _sameMoney(load.balanceDue, dueAmount.toDouble()) &&
                  (financeStatus == null || load.status == financeStatus);
          if (!loadAlreadySynced) {
            final loadUpdates = <String, dynamic>{
              'pricing.balanceDue': dueAmount.toDouble(),
              'updatedAt': FieldValue.serverTimestamp(),
            };
            if (financeStatus != null) {
              loadUpdates['status'] = financeStatus.firestoreValue;
            }
            await _jobWorkLoadRepository.loadDoc(loadId).update(loadUpdates);
          }
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
          JobWorkStatus nextStatus = order.status;
          if (dueAmount <= 0 &&
              order.status != JobWorkStatus.paid &&
              !order.status.isCollectionStatus) {
            nextStatus = JobWorkStatus.paid;
          } else if (dueAmount > 0 && order.status == JobWorkStatus.paid) {
            nextStatus = JobWorkStatus.invoiced;
          }
          if (!_sameMoney(order.balanceDue, dueAmount.toDouble()) ||
              nextStatus != order.status) {
            await _jobWorkRepository.jobWorkDoc(invoice.jobWorkId).update({
              'pricing.balanceDue': dueAmount.toDouble(),
              if (nextStatus != order.status)
                'status': nextStatus.firestoreValue,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
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
    final paidAmount = _appliedSum(payments);
    final dueAmount =
        (invoice.totalAmount - paidAmount).clamp(0, invoice.totalAmount);
    final status = InvoiceStatus.fromAmounts(
      dueAmount: dueAmount.toDouble(),
      paidAmount: paidAmount,
      totalAmount: invoice.totalAmount,
      dueDate: invoice.dueDate,
    );

    final invoiceAlreadySynced =
        _sameMoney(invoice.paidAmount, paidAmount) &&
            _sameMoney(invoice.dueAmount, dueAmount.toDouble()) &&
            invoice.status == status;
    if (!invoiceAlreadySynced) {
      await _salesInvoiceRepository.collection.doc(invoiceId).update({
        'paid': paidAmount,
        'due': dueAmount,
        'status': status.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Order finance updates only for single-order invoices; grand has empty salesOrderId.
    final salesOrderId = invoice.salesOrderId.trim();
    String? agreementId = invoice.agreementId?.trim();
    if (salesOrderId.isNotEmpty) {
      final order = await _salesOrderRepository.getSalesOrder(salesOrderId);
      if (order != null) {
        agreementId ??= order.agreementId?.trim();
        final finance = SalesContainerSyncHelper.orderFinanceAfterPaymentSync(
          order: order,
          paidAmount: paidAmount,
          dueAmount: dueAmount.toDouble(),
        );
        final orderAlreadySynced =
            _sameMoney(order.advanceReceived, finance.advanceReceived) &&
                _sameMoney(order.balanceDue, finance.balanceDue) &&
                (finance.status == null || order.status == finance.status);
        if (!orderAlreadySynced) {
          await _salesOrderRepository.salesOrderDoc(salesOrderId).update({
            'advanceReceived': finance.advanceReceived,
            'balanceDue': finance.balanceDue,
            'updatedAt': FieldValue.serverTimestamp(),
            if (finance.status != null)
              'status': finance.status!.firestoreValue,
          });
        }
      }
    }

    final linkedAgreementId = agreementId?.trim() ?? '';
    if (linkedAgreementId.isNotEmpty) {
      await cleanupSalesGrandPhantomAdvances(
        factoryId: invoice.factoryId,
        agreementId: linkedAgreementId,
      );
      await _salesInvoiceRepository.syncGrandInvoice(
        factoryId: invoice.factoryId,
        agreementId: linkedAgreementId,
      );
      await _salesAgreementRepository.syncAgreementContainer(linkedAgreementId);
    }

    await _ledgerService?.syncCustomerBalance(invoice.customerId);
  }

  /// Removes synthetic advance rows on grand invoices (paid is a rollup).
  Future<void> cleanupSalesGrandPhantomAdvances({
    required String factoryId,
    required String agreementId,
  }) async {
    final grand = await _salesInvoiceRepository.getGrandInvoiceForAgreement(
      factoryId: factoryId,
      agreementId: agreementId,
    );
    if (grand == null) return;
    await _deletePaymentDocIfExists('advance_sales_${grand.id}');
  }

  Future<void> _deletePaymentDocIfExists(String paymentId) async {
    final doc = await _collection.doc(paymentId).get();
    if (doc.exists) {
      await _collection.doc(paymentId).delete();
    }
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

      // Grand paidAmount is a rollup of order payments.
      if (invoice.isGrandInvoice) {
        await _deletePaymentDocIfExists('advance_sales_${invoice.id}');
        return;
      }

      // 1. Check if an advance payment document already exists for this order
      final customerPayments = await getPaymentsForCustomer(
        factoryId: invoice.factoryId,
        customerId: invoice.customerId,
      );

      final existingForOrder = customerPayments.where((p) =>
          p.orderId == invoice.salesOrderId &&
          p.status != PaymentStatus.voided).toList();

      if (existingForOrder.isNotEmpty) {
        // Link any unlinked or stale invoiceId on these payments to this invoice
        for (final p in existingForOrder) {
          if (p.invoiceId != invoice.id) {
            await _collection.doc(p.id).update({
              'invoiceId': invoice.id,
              'invoiceNumber': invoice.invoiceNumber,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        return;
      }

      // Legacy fallback: order had advance but no payment doc was created
      final advanceId = 'advance_sales_${invoice.salesOrderId.trim()}';
      final existingPayments = await getPaymentsForInvoice(
        factoryId: invoice.factoryId,
        invoiceId: invoice.id,
      );
      final nonAdvancePaid = existingPayments
          .where((payment) => payment.id != advanceId)
          .fold<double>(0, (total, payment) => total + payment.amount);

      if (nonAdvancePaid + 0.01 >= invoice.paidAmount) {
        if (existingPayments.any((payment) => payment.id == advanceId)) {
          await _collection.doc(advanceId).delete();
        }
        return;
      }

      if (existingPayments.any((payment) => payment.id == advanceId)) {
        return;
      }

      final gap = invoice.paidAmount - nonAdvancePaid;
      if (gap <= 0.01) return;

      final order =
          await _salesOrderRepository.getSalesOrder(invoice.salesOrderId);

      await _createStandalonePayment(
        factoryId: invoice.factoryId,
        customerId: invoice.customerId,
        customerName: invoice.customerName,
        invoiceId: invoice.id,
        invoiceType: InvoiceType.sales,
        invoiceNumber: invoice.invoiceNumber,
        amount: gap,
        paymentDate: order?.orderDate ?? invoice.createdAt,
        notes: 'Advance deposit for Sales Order #${invoice.salesOrderId}',
        paymentId: advanceId,
        orderId: invoice.salesOrderId,
        isAdvance: true,
      );
      return;
    }

    final invoice = await _jobWorkInvoiceRepository.getInvoice(invoiceId);
    if (invoice == null || invoice.paidAmount <= 0) return;

    final order = await _jobWorkRepository.getJobWorkOrder(invoice.jobWorkId);
    if (order == null) return;

    // Check if advance payments already exist for this JW or load
    final customerPayments = await getPaymentsForCustomer(
      factoryId: invoice.factoryId,
      customerId: invoice.customerId,
    );

    final existingForJob = customerPayments.where((p) =>
        (p.orderId == invoice.jobWorkId ||
            (invoice.loadId != null && p.loadId == invoice.loadId)) &&
        p.status != PaymentStatus.voided).toList();

    if (existingForJob.isNotEmpty) {
      for (final p in existingForJob) {
        if (p.invoiceId != invoice.id) {
          await _collection.doc(p.id).update({
            'invoiceId': invoice.id,
            'invoiceNumber': invoice.invoiceNumber,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return;
    }

    // Legacy fallback
    if (order.isLoadsAuthoritative) {
      final loads = await _jobWorkLoadRepository.fetchLoadsForJobWork(
        factoryId: invoice.factoryId,
        jobWorkId: invoice.jobWorkId,
      );

      final loadsToProcess =
          invoice.loadId != null && invoice.loadId!.trim().isNotEmpty
              ? loads.where((l) => l.id == invoice.loadId)
              : loads;

      for (final load in loadsToProcess) {
        if (load.advanceReceived <= 0) continue;

        final paymentId = 'advance_load_${load.id}';
        bool exists = false;
        try {
          final existingDoc = await _collection.doc(paymentId).get();
          exists = existingDoc.exists;
        } catch (_) {
          exists = false;
        }
        if (exists) continue;

        await _createStandalonePayment(
          factoryId: invoice.factoryId,
          customerId: invoice.customerId,
          customerName: invoice.customerName,
          invoiceId: invoice.id,
          invoiceType: InvoiceType.jobWork,
          invoiceNumber: invoice.invoiceNumber,
          amount: load.advanceReceived,
          paymentDate: load.receivedDate,
          notes: 'Advance deposit for Job Work Load #${load.loadNumber}',
          paymentId: paymentId,
          orderId: invoice.jobWorkId,
          loadId: load.id,
          isAdvance: true,
        );
      }
    } else {
      if (order.advanceReceived <= 0) return;

      final paymentId = 'advance_job_${order.id}';
      bool exists = false;
      try {
        final existingDoc = await _collection.doc(paymentId).get();
        exists = existingDoc.exists;
      } catch (_) {
        exists = false;
      }
      if (exists) return;

      await _createStandalonePayment(
        factoryId: invoice.factoryId,
        customerId: invoice.customerId,
        customerName: invoice.customerName,
        invoiceId: invoice.id,
        invoiceType: InvoiceType.jobWork,
        invoiceNumber: invoice.invoiceNumber,
        amount: order.advanceReceived,
        paymentDate: order.createdAt,
        notes: 'Advance deposit for Job Work #${order.jobWorkNumber}',
        paymentId: paymentId,
        orderId: order.id,
        isAdvance: true,
      );
    }
  }

  Future<Payment> recordJobWorkPayment({
    required String invoiceId,
    required double amount,
    required PaymentMethod method,
    required DateTime paymentDate,
    String? loadId,
    String? idempotencyKey,
    String? reference,
    String? notes,
    bool creditApplication = false,
  }) async {
    if (amount <= 0) {
      throw StateError(
        creditApplication
            ? 'Credit amount must be greater than zero.'
            : 'Payment amount must be greater than zero.',
      );
    }

    final paymentId = idempotencyKey ?? _uuid.v4();
    final paymentDocRef = _collection.doc(paymentId);
    final invoiceDocRef = _jobWorkInvoiceRepository.collection.doc(invoiceId);

    final payment =
        await _firestore.runTransaction<Payment>((transaction) async {
      final invoiceSnapshot = await transaction.get(invoiceDocRef);
      if (!invoiceSnapshot.exists || invoiceSnapshot.data() == null) {
        throw StateError('Invoice not found.');
      }

      final invoice = JobWorkInvoiceModel.fromFirestore(
        invoiceSnapshot.id,
        invoiceSnapshot.data()!,
      ).toEntity();

      // Determine target loadId (prefer explicit loadId, fallback to invoice.loadId)
      final effectiveLoadId = (loadId != null && loadId.trim().isNotEmpty)
          ? loadId.trim()
          : (invoice.loadId != null && invoice.loadId!.trim().isNotEmpty)
              ? invoice.loadId!.trim()
              : null;

      DocumentSnapshot<Map<String, dynamic>>? targetLoadSnapshot;
      DocumentReference<Map<String, dynamic>>? loadDocRef;
      JobWorkLoad? targetLoad;

      if (effectiveLoadId != null) {
        loadDocRef = _jobWorkLoadRepository.loadDoc(effectiveLoadId);
        targetLoadSnapshot = await transaction.get(loadDocRef);
        if (targetLoadSnapshot.exists && targetLoadSnapshot.data() != null) {
          targetLoad = JobWorkLoadModel.fromFirestore(
            targetLoadSnapshot.id,
            targetLoadSnapshot.data()!,
          ).toEntity();
        }
      }

      final remainingDue = JobWorkContainerSyncHelper.remainingDueForPayment(
        invoice: invoice,
        load: targetLoad,
      );

      if (remainingDue <= 0.005) {
        throw StateError(
          targetLoad != null
              ? 'The selected load is already fully paid.'
              : 'This invoice is already fully paid.',
        );
      }

      // 3. READ PARENT JOB WORK ORDER (must occur before any writes in a transaction)
      // Prefer the load's live container id — migrated invoices may still
      // carry a legacy jobWorkId that no longer matches the order document.
      final parentOrderId =
          (targetLoad != null && targetLoad.jobWorkId.trim().isNotEmpty)
              ? targetLoad.jobWorkId
              : invoice.jobWorkId;
      final orderDocRef = _jobWorkRepository.jobWorkDoc(parentOrderId);
      final orderSnapshot = await transaction.get(orderDocRef);
      JobWorkOrder? order;
      if (orderSnapshot.exists && orderSnapshot.data() != null) {
        order = JobWorkOrderModel.fromFirestore(
          orderSnapshot.id,
          orderSnapshot.data()!,
        ).toEntity();
      }

      final appliedAmount =
          _roundMoney(amount < remainingDue ? amount : remainingDue);
      final cashAmount = creditApplication ? 0.0 : amount;
      final newPaid = _roundMoney(
        (invoice.paidAmount + appliedAmount)
            .clamp(0, invoice.totalAmount)
            .toDouble(),
      );
      final newDue = _roundMoney(
        (invoice.totalAmount - newPaid)
            .clamp(0, invoice.totalAmount)
            .toDouble(),
      );
      final newStatus = InvoiceStatus.fromAmounts(
        dueAmount: newDue,
        paidAmount: newPaid,
        totalAmount: invoice.totalAmount,
        dueDate: invoice.dueDate,
      );

      final newPayment = Payment(
        id: paymentId,
        factoryId: invoice.factoryId,
        customerId: invoice.customerId,
        customerName: invoice.customerName,
        invoiceId: invoice.id,
        invoiceType: InvoiceType.jobWork,
        invoiceNumber: invoice.invoiceNumber,
        amount: cashAmount,
        appliedAmount: appliedAmount,
        method: method,
        paymentDate: paymentDate,
        reference: reference,
        notes: notes,
        orderId: order?.id ?? parentOrderId,
        loadId: effectiveLoadId,
        createdAt: DateTime.now(),
      );

      // --- ALL READS COMPLETE: PERFORM WRITES ---

      transaction.set(
        paymentDocRef,
        PaymentModel.fromEntity(newPayment).toFirestore(isCreate: true),
      );

      transaction.update(invoiceDocRef, {
        'paid': newPaid,
        'due': newDue,
        'status': newStatus.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Atomically update target child load if present
      if (targetLoad != null && loadDocRef != null) {
        final loadNewDue = double.parse(
          (targetLoad.balanceDue - appliedAmount)
              .clamp(0, targetLoad.finalCuttingCharges)
              .toStringAsFixed(2),
        );
        final loadUpdates = <String, dynamic>{
          'pricing.balanceDue': loadNewDue,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        final financeStatus = JobWorkContainerSyncHelper.financeStatusForLoad(
          load: targetLoad,
          dueAmount: loadNewDue,
        );
        if (financeStatus != null) {
          loadUpdates['status'] = financeStatus.firestoreValue;
        }
        transaction.update(loadDocRef, loadUpdates);
      }

      // Atomically update parent Job Work Order
      if (order != null) {
        final orderNewDue = double.parse(
          (order.balanceDue - appliedAmount)
              .clamp(0, double.infinity)
              .toStringAsFixed(2),
        );
        final orderUpdates = <String, dynamic>{
          'pricing.balanceDue': orderNewDue,
          'balanceDue': orderNewDue,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (orderNewDue <= 0.005 &&
            order.status != JobWorkStatus.paid &&
            !order.status.isCollectionStatus) {
          orderUpdates['status'] = JobWorkStatus.paid.firestoreValue;
        }
        transaction.update(orderDocRef, orderUpdates);
      }

      return newPayment;
    });

    // Repair path only: happy-path payment already wrote invoice+load+order.
    await _syncInvoiceFromPayments(
      invoiceId: invoiceId,
      invoiceType: InvoiceType.jobWork,
      repair: false,
    );

    if (_notificationRepository != null && _scannerService != null) {
      final updatedInvoice =
          await _jobWorkInvoiceRepository.getInvoice(invoiceId);
      if (updatedInvoice != null && updatedInvoice.dueAmount > 0) {
        await _notificationRepository.createNotification(
          _scannerService.buildPartialPaymentNotification(
            invoice: updatedInvoice,
            paymentId: payment.id,
            amountPaid: payment.amount,
            remainingDue: updatedInvoice.dueAmount,
          ),
        );
      }
    }

    await applyDashboardRollup(
      (service) => service.applyPayment(payment: payment),
    );
    return payment;
  }

  Future<Payment> recordSalesPayment({
    required String invoiceId,
    required double amount,
    required PaymentMethod method,
    required DateTime paymentDate,
    String? idempotencyKey,
    String? reference,
    String? notes,
    bool creditApplication = false,
  }) async {
    if (amount <= 0) {
      throw StateError(
        creditApplication
            ? 'Credit amount must be greater than zero.'
            : 'Payment amount must be greater than zero.',
      );
    }

    final paymentId = idempotencyKey ?? _uuid.v4();
    final paymentDocRef = _collection.doc(paymentId);
    final invoiceDocRef = _salesInvoiceRepository.collection.doc(invoiceId);

    final payment =
        await _firestore.runTransaction<Payment>((transaction) async {
      final invoiceSnapshot = await transaction.get(invoiceDocRef);
      if (!invoiceSnapshot.exists || invoiceSnapshot.data() == null) {
        throw StateError('Invoice not found.');
      }

      final invoice = SalesInvoiceModel.fromFirestore(
        invoiceSnapshot.id,
        invoiceSnapshot.data()!,
      ).toEntity();

      if (invoice.dueAmount <= 0.005) {
        throw StateError('This invoice is already fully paid.');
      }

      final appliedAmount =
          _roundMoney(amount < invoice.dueAmount ? amount : invoice.dueAmount);
      final cashAmount = creditApplication ? 0.0 : amount;
      final newPaid = _roundMoney(
        (invoice.paidAmount + appliedAmount)
            .clamp(0, invoice.totalAmount)
            .toDouble(),
      );
      final newDue = _roundMoney(
        (invoice.totalAmount - newPaid)
            .clamp(0, invoice.totalAmount)
            .toDouble(),
      );
      final newStatus = InvoiceStatus.fromAmounts(
        dueAmount: newDue,
        paidAmount: newPaid,
        totalAmount: invoice.totalAmount,
        dueDate: invoice.dueDate,
      );

      final newPayment = Payment(
        id: paymentId,
        factoryId: invoice.factoryId,
        customerId: invoice.customerId,
        customerName: invoice.customerName,
        invoiceId: invoice.id,
        invoiceType: InvoiceType.sales,
        invoiceNumber: invoice.invoiceNumber,
        amount: cashAmount,
        appliedAmount: appliedAmount,
        method: method,
        paymentDate: paymentDate,
        reference: reference,
        notes: notes,
        orderId: invoice.salesOrderId.isNotEmpty ? invoice.salesOrderId : null,
        createdAt: DateTime.now(),
      );

      transaction.set(
        paymentDocRef,
        PaymentModel.fromEntity(newPayment).toFirestore(isCreate: true),
      );

      transaction.update(invoiceDocRef, {
        'paid': newPaid,
        'due': newDue,
        'status': newStatus.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return newPayment;
    });

    // Recompute order/agreement/ledger. Invoice paid/due were written above;
    // skip rewriting them unless the payment docs disagree (repair).
    await _syncInvoiceFromPayments(
      invoiceId: invoiceId,
      invoiceType: InvoiceType.sales,
      repair: false,
    );

    if (_notificationRepository != null && _scannerService != null) {
      final updatedInvoice =
          await _salesInvoiceRepository.getInvoice(invoiceId);
      if (updatedInvoice != null && updatedInvoice.dueAmount > 0) {
        await _notificationRepository.createNotification(
          _scannerService.buildSalesPartialPaymentNotification(
            invoice: updatedInvoice,
            paymentId: payment.id,
            amountPaid: payment.amount,
            remainingDue: updatedInvoice.dueAmount,
          ),
        );
      }
    }

    await applyDashboardRollup(
      (service) => service.applyPayment(payment: payment),
    );
    return payment;
  }

  Future<double> getUnallocatedCreditForCustomer({
    required String factoryId,
    required String customerId,
  }) async {
    final payments = await getPaymentsForCustomer(
      factoryId: factoryId,
      customerId: customerId,
    );
    return Payment.unallocatedTotal(payments);
  }

  /// Allocates existing customer credit to [invoiceId] without recording new cash.
  Future<Payment> applyCustomerCredit({
    required String invoiceId,
    required InvoiceType invoiceType,
    required double appliedAmount,
    required PaymentMethod method,
    required DateTime paymentDate,
    String? loadId,
    String? reference,
    String? notes,
  }) async {
    if (appliedAmount <= 0.005) {
      throw StateError('Credit amount must be greater than zero.');
    }
    if (invoiceType == InvoiceType.jobWork) {
      return recordJobWorkPayment(
        invoiceId: invoiceId,
        amount: appliedAmount,
        method: method,
        paymentDate: paymentDate,
        loadId: loadId,
        reference: reference,
        notes: notes ?? 'Applied customer credit',
        creditApplication: true,
      );
    }
    return recordSalesPayment(
      invoiceId: invoiceId,
      amount: appliedAmount,
      method: method,
      paymentDate: paymentDate,
      reference: reference,
      notes: notes ?? 'Applied customer credit',
      creditApplication: true,
    );
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
    String? paymentId,
    bool isAdvance = false,
    String? orderId,
    String? loadId,
    PaymentStatus status = PaymentStatus.completed,
  }) async {
    final id = paymentId ?? _uuid.v4();
    final payment = Payment(
      id: id,
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
      isAdvance: isAdvance,
      orderId: orderId,
      loadId: loadId,
      status: status,
    );

    await _collection.doc(id).set(
          PaymentModel.fromEntity(payment).toFirestore(isCreate: true),
        );

    await applyDashboardRollup(
      (service) => service.applyPayment(payment: payment),
    );
    return payment;
  }

  /// Computes effective financial amounts for a job work invoice by
  /// consulting the load's financeMap. This handles cases where the
  /// Firestore invoice doc has stale totals (e.g. total=0 because the
  /// invoice was generated before cutting output was recorded).
  Future<JobWorkInvoice> _resolveEffectiveInvoice(
    JobWorkInvoice invoice,
  ) async {
    final loadId = invoice.loadId?.trim();
    if (loadId != null && loadId.isNotEmpty) {
      // Load-scoped invoice — use the per-load financeMap.
      final order =
          await _jobWorkRepository.getJobWorkOrder(invoice.jobWorkId);
      if (order != null) {
        final loads = await _jobWorkLoadRepository.fetchLoadsForJobWork(
          factoryId: invoice.factoryId,
          jobWorkId: invoice.jobWorkId,
        );
        final invoices = await _jobWorkInvoiceRepository.getInvoicesByJobWorkId(
          factoryId: invoice.factoryId,
          jobWorkId: invoice.jobWorkId,
        );
        final paymentSnap = await _collection
            .where('factoryId', isEqualTo: invoice.factoryId)
            .where('customerId', isEqualTo: invoice.customerId)
            .get();
        final payments = paymentSnap.docs
            .map((doc) =>
                PaymentModel.fromFirestore(doc.id, doc.data()).toEntity())
            .where((payment) => payment.status != PaymentStatus.voided)
            .toList();
        final financeMap =
            JobWorkContainerSyncHelper.calculatePerLoadFinanceMap(
          order: order,
          loads: loads,
          invoices: invoices,
          payments: payments,
        );
        final fin = financeMap[loadId];
        if (fin != null) {
          return invoice.copyWith(
            totalAmount: fin.charges,
            paidAmount: fin.paid,
            dueAmount: fin.due,
            status: InvoiceStatus.fromAmounts(
              dueAmount: fin.due,
              paidAmount: fin.paid,
              totalAmount: fin.charges,
              dueDate: invoice.dueDate,
            ),
          );
        }
      }
    } else {
      // Grand invoice — sync from all loads.
      final synced = await _jobWorkInvoiceRepository.syncGrandInvoice(
        factoryId: invoice.factoryId,
        jobWorkId: invoice.jobWorkId,
      );
      if (synced != null) return synced;
    }
    return invoice;
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

bool _sameMoney(num a, num b) => (a - b).abs() < 0.005;

double _roundMoney(double value) => double.parse(value.toStringAsFixed(2));

double _appliedSum(Iterable<Payment> payments) =>
    payments.fold<double>(0, (sum, payment) => sum + payment.appliedAmount);
