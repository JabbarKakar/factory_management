import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/events/entity_reactive_event_bus.dart';
import '../../core/observability/tracked_firestore.dart';
import '../../core/utils/firestore_query_constraints.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/customer_enums.dart';
import '../../domain/enums/document_sequence.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/sales_enums.dart';
import '../models/customer_model.dart';
import '../models/payment_model.dart';
import '../models/sales_order_model.dart';
import '../services/sequence_number_service.dart';
import 'sales_agreement_repository.dart';

import '../../core/utils/firestore_paginator.dart';
import '../models/paginated_result.dart';

class SalesOrderRepository {
  SalesOrderRepository({
    FirebaseFirestore? firestore,
    SalesAgreementRepository? salesAgreementRepository,
    SequenceNumberService? sequenceNumberService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _salesAgreementRepository = salesAgreementRepository ??
            SalesAgreementRepository(firestore: firestore),
        _sequenceNumberService =
            sequenceNumberService ?? SequenceNumberService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final SalesAgreementRepository _salesAgreementRepository;
  final SequenceNumberService _sequenceNumberService;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      trackedCollection(_firestore, 'salesOrders');

  DocumentReference<Map<String, dynamic>> salesOrderDoc(String id) =>
      _ordersCollection.doc(id);

  CollectionReference<Map<String, dynamic>> get _customerCollection =>
      trackedCollection(_firestore, 'customers');

  Future<PaginatedResult<SalesOrder>> fetchSalesOrdersPage({
    required String factoryId,
    DocumentSnapshot? startAfter,
    int limit = 20,
    SalesOrderStatus? statusFilter,
  }) async {
    Query<Map<String, dynamic>> query =
        _ordersCollection.where('factoryId', isEqualTo: factoryId);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.firestoreValue);
    }

    return FirestorePaginator.fetchPage<SalesOrder>(
      query: query,
      orderByField: 'createdAt',
      descending: true,
      startAfter: startAfter,
      limit: limit,
      mapDoc: (id, data) => SalesOrderModel.fromFirestore(id, data).toEntity(),
    );
  }

  Stream<List<SalesOrder>> watchSalesOrders(
    String factoryId, {
    int? limit,
  }) {
    return constrainFactoryQuery(
      _ordersCollection.where('factoryId', isEqualTo: factoryId),
      limit: limit,
    ).snapshots().map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => SalesOrderModel.fromFirestore(doc.id, doc.data()))
              .map((model) => model.toEntity())
              .toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  Future<List<SalesOrder>> getSalesOrders(String factoryId) async {
    final snapshot =
        await _ordersCollection.where('factoryId', isEqualTo: factoryId).get();
    final orders = snapshot.docs
        .map((doc) => SalesOrderModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  Future<SalesOrder?> getSalesOrder(String id) async {
    final doc = await _ordersCollection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return SalesOrderModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Stream<SalesOrder?> watchSalesOrder(String id) {
    return _ordersCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return SalesOrderModel.fromFirestore(doc.id, doc.data()!).toEntity();
    });
  }

  Future<List<SalesOrder>> getOrdersForAgreement({
    required String factoryId,
    required String agreementId,
  }) async {
    final snapshot = await _ordersCollection
        .where('factoryId', isEqualTo: factoryId)
        .where('agreementId', isEqualTo: agreementId)
        .get();
    final orders = snapshot.docs
        .map((doc) => SalesOrderModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .toList();
    orders.sort((a, b) {
      final seqA = a.orderSequence ?? 0;
      final seqB = b.orderSequence ?? 0;
      if (seqA != seqB) return seqA.compareTo(seqB);
      return a.createdAt.compareTo(b.createdAt);
    });
    return orders;
  }

  Stream<List<SalesOrder>> watchOrdersForAgreement({
    required String factoryId,
    required String agreementId,
  }) {
    return _ordersCollection
        .where('factoryId', isEqualTo: factoryId)
        .where('agreementId', isEqualTo: agreementId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => SalesOrderModel.fromFirestore(doc.id, doc.data()))
          .map((model) => model.toEntity())
          .toList();
      orders.sort((a, b) {
        final seqA = a.orderSequence ?? 0;
        final seqB = b.orderSequence ?? 0;
        if (seqA != seqB) return seqA.compareTo(seqB);
        return a.createdAt.compareTo(b.createdAt);
      });
      return orders;
    });
  }

  Future<List<Customer>> fetchSalesEligibleCustomers(String factoryId) async {
    final snapshot =
        await _customerCollection.where('factoryId', isEqualTo: factoryId).get();

    return snapshot.docs
        .map((doc) => CustomerModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .where(
          (customer) =>
              customer.serviceType == CustomerServiceType.buyer ||
              customer.serviceType == CustomerServiceType.both,
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<Customer> customersForOrderForm({
    required List<Customer> eligible,
    SalesOrder? order,
  }) {
    if (order == null || order.customerId.isEmpty) return eligible;
    if (eligible.any((customer) => customer.id == order.customerId)) {
      return eligible;
    }

    return [
      _removedCustomerPlaceholder(order),
      ...eligible,
    ];
  }

  Customer _removedCustomerPlaceholder(SalesOrder order) {
    return Customer(
      id: order.customerId,
      factoryId: order.factoryId,
      customerType: CustomerType.individual,
      name: order.customerName.isEmpty
          ? 'Removed customer'
          : '${order.customerName} (removed)',
      phone: '',
      serviceType: CustomerServiceType.buyer,
      category: CustomerCategory.retail,
      paymentTerms: PaymentTerms.cash,
      creditLimit: 0,
      balance: 0,
      openingBalance: 0,
      createdAt: order.createdAt,
    );
  }

  Future<SalesOrder> createSalesOrder(SalesOrder order) async {
    final id = order.id.isEmpty ? _uuid.v4() : order.id;
    final orderNumber = order.orderNumber.isEmpty
        ? await _generateOrderNumber(order.factoryId)
        : order.orderNumber;

    final paymentDueDate =
        order.paymentDueDate ?? _dueDateFromTerms(order.paymentTerms, order.orderDate);

    var draft = order.copyWith(
      id: id,
      orderNumber: orderNumber,
      status: SalesOrderStatus.received,
      paymentDueDate: paymentDueDate,
    );

    final agreementId = draft.agreementId?.trim() ?? '';
    if (agreementId.isNotEmpty) {
      final agreement =
          await _salesAgreementRepository.getAgreement(agreementId);
      if (agreement == null) {
        throw StateError('Sales agreement not found.');
      }
      final sequence = draft.orderSequence ??
          await _salesAgreementRepository.nextOrderSequence(
            factoryId: draft.factoryId,
            agreementId: agreementId,
          );
      draft = draft.copyWith(
        agreementId: agreement.id,
        agreementNumber: agreement.agreementNumber,
        orderSequence: sequence,
        customerId: draft.customerId.isEmpty
            ? agreement.customerId
            : draft.customerId,
        customerName: draft.customerName.isEmpty
            ? agreement.customerName
            : draft.customerName,
      );
    }

    final withTotals = _recomputeTotals(draft);
    final model = SalesOrderModel.fromEntity(withTotals);

    final batch = _firestore.batch();
    batch.set(_ordersCollection.doc(id), model.toFirestore(isCreate: true));

    if (withTotals.advanceReceived > 0) {
      final paymentId = _uuid.v4();
      final payment = Payment(
        id: paymentId,
        factoryId: withTotals.factoryId,
        customerId: withTotals.customerId,
        customerName: withTotals.customerName,
        invoiceId: '',
        invoiceType: InvoiceType.sales,
        invoiceNumber: withTotals.orderNumber,
        amount: withTotals.advanceReceived,
        method: withTotals.paymentTerms == PaymentTerms.cash
            ? PaymentMethod.cash
            : PaymentMethod.bankTransfer,
        paymentDate: withTotals.orderDate,
        reference: withTotals.orderNumber,
        notes: 'Advance deposit for Sales Order #${withTotals.orderNumber}',
        createdAt: DateTime.now(),
        isAdvance: true,
        orderId: withTotals.id,
      );
      batch.set(
        _firestore.collection('payments').doc(paymentId),
        PaymentModel.fromEntity(payment).toFirestore(isCreate: true),
      );
    }

    await batch.commit();
    final created = await getSalesOrder(id) ?? withTotals;

    if (!created.hasAgreement) {
      await _salesAgreementRepository.ensureAgreementForOrder(created);
    } else {
      await _salesAgreementRepository.syncAgreementContainer(
        created.agreementId!,
      );
    }
    final finalCreated = (await getSalesOrder(id)) ?? created;
    EntityReactiveEventBus.instance.notifyCreated<SalesOrder>(finalCreated);
    return finalCreated;
  }

  Future<void> updateSalesOrder(SalesOrder order) async {
    var updated = _recomputeTotals(order);
    if (updated.status == SalesOrderStatus.received) {
      updated = updated.copyWith(
        paymentDueDate: _dueDateFromTerms(
          updated.paymentTerms,
          updated.orderDate,
        ),
      );
    }
    final model = SalesOrderModel.fromEntity(updated);
    await _ordersCollection.doc(order.id).update(model.toFirestore());
    await _syncAgreementIfLinked(updated.agreementId);
    EntityReactiveEventBus.instance.notifyUpdated<SalesOrder>(updated);
  }

  Future<void> advanceSalesOrderStatus(String id, SalesOrderStatus status) async {
    final order = await getSalesOrder(id);
    if (order == null) {
      throw StateError('Sales order not found.');
    }

    if (order.status == SalesOrderStatus.paid &&
        status != SalesOrderStatus.closed) {
      throw StateError('Paid sales orders can only be closed.');
    }

    await _ordersCollection.doc(id).update({
      'status': status.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == SalesOrderStatus.closed)
        'closedAt': FieldValue.serverTimestamp(),
    });
    await _syncAgreementIfLinked(order.agreementId);
  }

  Future<void> updateDispatchStatus(String id, SalesOrderStatus status) async {
    final order = await getSalesOrder(id);
    await _ordersCollection.doc(id).update({
      'status': status.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _syncAgreementIfLinked(order?.agreementId);
  }

  Future<void> deleteSalesOrder(String id) async {
    final order = await getSalesOrder(id);
    await _ordersCollection.doc(id).delete();
    await _syncAgreementIfLinked(order?.agreementId);
    if (order != null) {
      EntityReactiveEventBus.instance.notifyDeleted<SalesOrder>(order);
    }
  }

  Future<void> cancelSalesOrder(String id) async {
    final order = await getSalesOrder(id);
    if (order == null) return;

    final batch = _firestore.batch();
    batch.update(_ordersCollection.doc(id), {
      'status': SalesOrderStatus.cancelled.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 1. Cancel linked single invoices
    final invoiceSnap = await _firestore
        .collection('salesInvoices')
        .where('factoryId', isEqualTo: order.factoryId)
        .where('salesOrderId', isEqualTo: id)
        .get();

    for (final doc in invoiceSnap.docs) {
      batch.update(doc.reference, {
        'status': InvoiceStatus.cancelled.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 2. Void linked advance payments or payments linked to this order/invoices
    final paymentsSnap = await _firestore
        .collection('payments')
        .where('factoryId', isEqualTo: order.factoryId)
        .where('customerId', isEqualTo: order.customerId)
        .get();

    final invoiceIds = invoiceSnap.docs.map((d) => d.id).toSet();

    for (final doc in paymentsSnap.docs) {
      final data = doc.data();
      final orderId = data['orderId'] as String? ?? '';
      final invoiceId = data['invoiceId'] as String? ?? '';

      if (orderId == id ||
          invoiceIds.contains(invoiceId) ||
          doc.id == 'advance_sales_$id') {
        batch.update(doc.reference, {
          'status': PaymentStatus.voided.firestoreValue,
          'notes': '${data['notes'] ?? ''} (Cancelled with order #${order.orderNumber})'.trim(),
        });
      }
    }

    await batch.commit();
    await _syncAgreementIfLinked(order.agreementId);
    EntityReactiveEventBus.instance.notifyUpdated<SalesOrder>(
      order.copyWith(status: SalesOrderStatus.cancelled),
    );
  }

  Future<void> _syncAgreementIfLinked(String? agreementId) async {
    final id = agreementId?.trim() ?? '';
    if (id.isEmpty) return;
    await _salesAgreementRepository.syncAgreementContainer(id);
  }

  Future<List<SalesOrder>> getSalesOrdersForCustomer({
    required String factoryId,
    required String customerId,
  }) async {
    final snapshot = await _ordersCollection
        .where('factoryId', isEqualTo: factoryId)
        .where('customerId', isEqualTo: customerId)
        .get();
    final orders = snapshot.docs
        .map((doc) => SalesOrderModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  /// Live count of non-cancelled sales orders for a customer.
  ///
  /// Query is `factoryId` + `customerId` so a customer screen does not
  /// download the rest of the factory.
  Stream<int> watchActiveOrderCountForCustomer({
    required String factoryId,
    required String customerId,
  }) {
    return _ordersCollection
        .where('factoryId', isEqualTo: factoryId)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SalesOrderModel.fromFirestore(doc.id, doc.data()))
              .map((model) => model.toEntity())
              .where(
                (order) =>
                    order.customerId == customerId &&
                    order.status != SalesOrderStatus.cancelled,
              )
              .length,
        );
  }

  Future<void> deleteOrdersForCustomer({
    required String factoryId,
    required String customerId,
  }) async {
    final snapshot = await _ordersCollection
        .where('factoryId', isEqualTo: factoryId)
        .get();
    final docs = snapshot.docs
        .where((doc) => doc.data()['customerId'] == customerId)
        .toList();

    if (docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<int> deleteOrphanedOrders(String factoryId) async {
    final ordersSnapshot = await _ordersCollection
        .where('factoryId', isEqualTo: factoryId)
        .get();

    if (ordersSnapshot.docs.isEmpty) return 0;

    final customersSnapshot = await _customerCollection
        .where('factoryId', isEqualTo: factoryId)
        .get();

    final customerIds = customersSnapshot.docs.map((doc) => doc.id).toSet();

    final orphanedDocs = ordersSnapshot.docs.where((doc) {
      final customerId = doc.data()['customerId'] as String? ?? '';
      return customerId.isEmpty || !customerIds.contains(customerId);
    }).toList();

    if (orphanedDocs.isEmpty) return 0;

    const batchLimit = 500;
    var deletedCount = 0;

    for (var index = 0; index < orphanedDocs.length; index += batchLimit) {
      final batch = _firestore.batch();
      final chunk = orphanedDocs.skip(index).take(batchLimit);
      for (final doc in chunk) {
        batch.delete(doc.reference);
        deletedCount++;
      }
      await batch.commit();
    }

    return deletedCount;
  }

  SalesOrder _recomputeTotals(SalesOrder order) {
    final subtotal = SalesOrder.computeSubtotal(order.lineItems);
    final grandTotal = SalesOrder.computeGrandTotal(
      subtotal: subtotal,
      orderDiscount: order.orderDiscount,
      tax: order.tax,
    );
    final balanceDue = (grandTotal - order.advanceReceived).clamp(0, double.infinity);

    return order.copyWith(
      subtotal: subtotal,
      grandTotal: grandTotal,
      balanceDue: balanceDue.toDouble(),
    );
  }

  DateTime? _dueDateFromTerms(PaymentTerms terms, DateTime orderDate) {
    final base = DateTime(orderDate.year, orderDate.month, orderDate.day);
    return switch (terms) {
      PaymentTerms.cash => base,
      PaymentTerms.days7 => base.add(const Duration(days: 7)),
      PaymentTerms.days15 => base.add(const Duration(days: 15)),
      PaymentTerms.days30 => base.add(const Duration(days: 30)),
      PaymentTerms.days60 => base.add(const Duration(days: 60)),
    };
  }

  Future<String> _generateOrderNumber(String factoryId) {
    return _sequenceNumberService.allocate(
      factoryId: factoryId,
      sequence: DocumentSequence.salesOrder,
    );
  }
}
