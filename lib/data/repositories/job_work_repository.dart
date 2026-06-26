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
        .where(
          (customer) =>
              customer.serviceType == CustomerServiceType.jobWork ||
              customer.serviceType == CustomerServiceType.both,
        )
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

  Future<String> _generateJobWorkNumber(String factoryId) async {
    final year = DateTime.now().year;
    final snapshot =
        await _jobWorkCollection.where('factoryId', isEqualTo: factoryId).get();
    final count = snapshot.docs.length + 1;
    return 'JW-$year-${count.toString().padLeft(4, '0')}';
  }
}
