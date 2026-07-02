import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/job_work_charges_calculator.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/job_work_output.dart';
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

  DocumentReference<Map<String, dynamic>> jobWorkDoc(String id) =>
      _jobWorkCollection.doc(id);

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
    await _jobWorkCollection
        .doc(order.id)
        .update(model.toFirestoreWithComputedYield());
  }

  Future<void> advanceJobWorkStatus(String id, JobWorkStatus status) async {
    await _jobWorkCollection.doc(id).update({
      'status': status.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> advanceJobWorkCompletionStatus(
    String id,
    JobWorkStatus targetStatus,
  ) async {
    final order = await getJobWorkOrder(id);
    if (order == null) {
      throw StateError('Job work order not found.');
    }

    final allowed = switch ((order.status, targetStatus)) {
      (JobWorkStatus.paid, JobWorkStatus.collected) => true,
      (JobWorkStatus.collected, JobWorkStatus.closed) => true,
      _ => false,
    };
    if (!allowed) {
      throw StateError('Invalid job work completion status transition.');
    }

    final updates = <String, dynamic>{
      'status': targetStatus.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (targetStatus == JobWorkStatus.collected) {
      updates['collectedAt'] = FieldValue.serverTimestamp();
    }
    if (targetStatus == JobWorkStatus.closed) {
      updates['closedAt'] = FieldValue.serverTimestamp();
    }

    await _jobWorkCollection.doc(id).update(updates);
  }

  Future<JobWorkOrder> recordJobWorkOutput(JobWorkOrder order) async {
    final manualOutput = order.output ?? const JobWorkOutput();
    final output = order.shiftLogs.isNotEmpty
        ? JobWorkOutput.aggregateFromShifts(
            order.shiftLogs,
            wasteDisposition: manualOutput.wasteDisposition,
            slurryDust: manualOutput.slurryDust,
          ).copyWith(
            wasteAmount: manualOutput.wasteAmount,
            wasteUnit: manualOutput.wasteUnit,
            recordedAt: DateTime.now(),
          )
        : manualOutput.copyWith(recordedAt: DateTime.now());

    final finalCuttingCharges = JobWorkChargesCalculator.calculate(
      order: order,
      output: output,
      shiftLogs: order.shiftLogs,
    );
    final resolvedCharges = finalCuttingCharges > 0
        ? finalCuttingCharges
        : order.finalCuttingCharges;
    final balanceDue = resolvedCharges - order.advanceReceived;

    final withOutput = order.copyWith(
      output: output,
      finalCuttingCharges: resolvedCharges,
      balanceDue: balanceDue,
    );
    final newStatus = _statusAfterOutputSaved(withOutput);
    final updated = withOutput.copyWith(status: newStatus);

    await updateJobWorkOrder(updated);
    return (await getJobWorkOrder(order.id)) ?? updated;
  }

  JobWorkStatus _statusAfterOutputSaved(JobWorkOrder order) {
    final output = order.output;
    if (output == null || !output.isRecorded) return order.status;

    final hasCompletion = order.execution?.cuttingCompletionDate != null;
    final hasStart = order.execution?.cuttingStartDate != null;

    if (hasCompletion) {
      return switch (order.status) {
        JobWorkStatus.qc => JobWorkStatus.ready,
        JobWorkStatus.inCutting || JobWorkStatus.agreed => JobWorkStatus.qc,
        _ => order.status,
      };
    }

    if (order.status == JobWorkStatus.agreed &&
        (hasStart || output.totalUsableSqFt > 0)) {
      return JobWorkStatus.inCutting;
    }

    return order.status;
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
