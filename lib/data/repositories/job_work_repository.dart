import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/customer.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/enums/customer_enums.dart';
import '../../domain/enums/job_work_enums.dart';
import '../models/customer_model.dart';
import '../models/job_work_order_model.dart';

class JobWorkRepository {
  JobWorkRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _jobWorkCollection =>
      _firestore.collection('jobWorkOrders');

  CollectionReference<Map<String, dynamic>> get _customerCollection =>
      _firestore.collection('customers');

  Stream<List<JobWorkOrder>> watchJobWorkOrders(String factoryId) {
    return _jobWorkCollection
        .where('factoryId', isEqualTo: factoryId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => JobWorkOrderModel.fromFirestore(doc.id, doc.data()))
              .map((model) => model.toEntity())
              .toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  Future<JobWorkOrder?> getJobWorkOrder(String id) async {
    final doc = await _jobWorkCollection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return JobWorkOrderModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Future<List<Customer>> fetchJobWorkEligibleCustomers(String factoryId) async {
    final snapshot =
        await _customerCollection.where('factoryId', isEqualTo: factoryId).get();

    return snapshot.docs
        .map((doc) => CustomerModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<JobWorkOrder> createJobWorkOrder(JobWorkOrder order) async {
    final id = order.id.isEmpty ? _uuid.v4() : order.id;
    final jobWorkNumber = order.jobWorkNumber.isEmpty
        ? await _generateJobWorkNumber(order.factoryId)
        : order.jobWorkNumber;

    final model = JobWorkOrderModel.fromEntity(
      order.copyWith(
        id: id,
        jobWorkNumber: jobWorkNumber,
        status: JobWorkStatus.agreed,
      ),
    );

    await _jobWorkCollection.doc(id).set(model.toFirestore(isCreate: true));
    final created = await getJobWorkOrder(id);
    return created ?? model.toEntity();
  }

  Future<void> updateJobWorkOrder(JobWorkOrder order) async {
    final model = JobWorkOrderModel.fromEntity(order);
    await _jobWorkCollection.doc(order.id).update(model.toFirestore());
  }

  Future<void> cancelJobWorkOrder(String id) async {
    await _jobWorkCollection.doc(id).update({
      'status': JobWorkStatus.cancelled.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> countOrdersForCustomer(String customerId) async {
    final snapshot = await _jobWorkCollection
        .where('customerId', isEqualTo: customerId)
        .get();
    return snapshot.docs.length;
  }

  Future<void> deleteOrdersForCustomer(String customerId) async {
    final snapshot = await _jobWorkCollection
        .where('customerId', isEqualTo: customerId)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Deletes job work orders whose [customerId] no longer exists.
  Future<int> deleteOrphanedOrders(String factoryId) async {
    final ordersSnapshot = await _jobWorkCollection
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

  /// Ensures the order's linked customer appears in the picker (e.g. if deleted).
  List<Customer> customersForOrderForm({
    required List<Customer> eligible,
    JobWorkOrder? order,
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

  Customer _removedCustomerPlaceholder(JobWorkOrder order) {
    return Customer(
      id: order.customerId,
      factoryId: order.factoryId,
      customerType: CustomerType.individual,
      name: order.customerName.isEmpty
          ? 'Removed customer'
          : '${order.customerName} (removed)',
      phone: '',
      serviceType: CustomerServiceType.jobWork,
      category: CustomerCategory.retail,
      paymentTerms: PaymentTerms.cash,
      creditLimit: 0,
      balance: 0,
      openingBalance: 0,
      createdAt: order.createdAt,
    );
  }

  Future<String> _generateJobWorkNumber(String factoryId) async {
    final year = DateTime.now().year;
    final snapshot =
        await _jobWorkCollection.where('factoryId', isEqualTo: factoryId).get();
    final count = snapshot.docs.length + 1;
    return 'JW-$year-${count.toString().padLeft(4, '0')}';
  }
}
