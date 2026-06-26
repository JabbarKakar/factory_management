import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/customer.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/customer_enums.dart';
import '../../domain/enums/sales_enums.dart';
import '../models/customer_model.dart';
import '../models/sales_order_model.dart';

class SalesOrderRepository {
  SalesOrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('salesOrders');

  DocumentReference<Map<String, dynamic>> salesOrderDoc(String id) =>
      _ordersCollection.doc(id);

  CollectionReference<Map<String, dynamic>> get _customerCollection =>
      _firestore.collection('customers');

  Stream<List<SalesOrder>> watchSalesOrders(String factoryId) {
    return _ordersCollection
        .where('factoryId', isEqualTo: factoryId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => SalesOrderModel.fromFirestore(doc.id, doc.data()))
              .map((model) => model.toEntity())
              .toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  Future<SalesOrder?> getSalesOrder(String id) async {
    final doc = await _ordersCollection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return SalesOrderModel.fromFirestore(doc.id, doc.data()!).toEntity();
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

    final withTotals = _recomputeTotals(
      order.copyWith(
        id: id,
        orderNumber: orderNumber,
        status: SalesOrderStatus.received,
        paymentDueDate: paymentDueDate,
      ),
    );

    final model = SalesOrderModel.fromEntity(withTotals);
    await _ordersCollection.doc(id).set(model.toFirestore(isCreate: true));
    final created = await getSalesOrder(id);
    return created ?? withTotals;
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
  }

  Future<void> cancelSalesOrder(String id) async {
    await _ordersCollection.doc(id).update({
      'status': SalesOrderStatus.cancelled.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteOrdersForCustomer(String customerId) async {
    final snapshot = await _ordersCollection
        .where('customerId', isEqualTo: customerId)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
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

  Future<String> _generateOrderNumber(String factoryId) async {
    final year = DateTime.now().year;
    final snapshot =
        await _ordersCollection.where('factoryId', isEqualTo: factoryId).get();
    final count = snapshot.docs.length + 1;
    return 'ORD-$year-${count.toString().padLeft(4, '0')}';
  }
}
