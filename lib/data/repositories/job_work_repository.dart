import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/events/entity_reactive_event_bus.dart';
import '../../core/utils/job_work_charges_calculator.dart';
import '../../core/observability/tracked_firestore.dart';
import '../../core/utils/firestore_query_constraints.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/job_work_output.dart';
import '../../domain/enums/customer_enums.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/job_work_enums.dart';
import '../models/customer_model.dart';
import '../models/job_work_collection_model.dart';
import '../../domain/enums/document_sequence.dart';
import '../models/job_work_order_model.dart';
import '../services/job_work_collection_status_helper.dart';
import '../services/sequence_number_service.dart';

import '../../core/utils/firestore_paginator.dart';
import '../models/paginated_result.dart';

class JobWorkRepository {
  JobWorkRepository({
    FirebaseFirestore? firestore,
    SequenceNumberService? sequenceNumberService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _sequenceNumberService =
            sequenceNumberService ?? SequenceNumberService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final SequenceNumberService _sequenceNumberService;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _jobWorkCollection =>
      trackedCollection(_firestore, 'jobWorkOrders');

  DocumentReference<Map<String, dynamic>> jobWorkDoc(String id) =>
      _jobWorkCollection.doc(id);

  CollectionReference<Map<String, dynamic>> get _customerCollection =>
      trackedCollection(_firestore, 'customers');

  Future<PaginatedResult<JobWorkOrder>> fetchJobWorkOrdersPage({
    required String factoryId,
    DocumentSnapshot? startAfter,
    int limit = 20,
    JobWorkStatus? statusFilter,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    Query<Map<String, dynamic>> query =
        _jobWorkCollection.where('factoryId', isEqualTo: factoryId);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.firestoreValue);
    }
    if (fromDate != null) {
      query = query.where(
        'receivedDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate),
      );
    }
    if (toDate != null) {
      query = query.where(
        'receivedDate',
        isLessThanOrEqualTo: Timestamp.fromDate(toDate),
      );
    }

    return FirestorePaginator.fetchPage<JobWorkOrder>(
      query: query,
      orderByField: 'createdAt',
      descending: true,
      startAfter: startAfter,
      limit: limit,
      mapDoc: (id, data) =>
          JobWorkOrderModel.fromFirestore(id, data).toEntity(),
    );
  }

  Stream<List<JobWorkOrder>> watchJobWorkOrders(
    String factoryId, {
    int? limit,
  }) {
    return constrainFactoryQuery(
      _jobWorkCollection.where('factoryId', isEqualTo: factoryId),
      limit: limit,
    ).snapshots().map((snapshot) {
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

  Future<List<JobWorkOrder>> getJobWorkOrders(String factoryId) async {
    final snapshot = await _jobWorkCollection
        .where('factoryId', isEqualTo: factoryId)
        .get();
    final orders = snapshot.docs
        .map((doc) => JobWorkOrderModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  Stream<JobWorkOrder?> watchJobWorkOrder(String id) {
    return _jobWorkCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return JobWorkOrderModel.fromFirestore(doc.id, doc.data()!).toEntity();
    });
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
    final created = (await getJobWorkOrder(id)) ?? model.toEntity();
    EntityReactiveEventBus.instance.notifyCreated<JobWorkOrder>(created);
    return created;
  }

  Future<void> updateJobWorkOrder(JobWorkOrder order) async {
    final existing = await getJobWorkOrder(order.id);
    final model = JobWorkOrderModel.fromEntity(order);
    // Sprint 7: once Loads are authoritative, nested ops fields are archive-only.
    final map = existing != null && existing.isLoadsAuthoritative
        ? model.toFirestore(containerOnly: true)
        : model.toFirestoreWithComputedYield();
    await _jobWorkCollection.doc(order.id).update(map);
    EntityReactiveEventBus.instance.notifyUpdated<JobWorkOrder>(order);
  }

  Future<void> deleteJobWorkOrder(String id) async {
    final order = await getJobWorkOrder(id);
    if (order == null) {
      // Best-effort remove if the doc was already partially cleaned up.
      await _jobWorkCollection.doc(id).delete();
      return;
    }

    final factoryId = order.factoryId;
    final loadSnap = await _firestore
        .collection('jobWorkLoads')
        .where('factoryId', isEqualTo: factoryId)
        .get();

    final loads = loadSnap.docs
        .where((doc) => doc.data()['jobWorkId'] == id)
        .toList();

    // Load-scoped QC uses referenceId = loadId (not jobWorkId).
    for (final loadDoc in loads) {
      await _deleteDocumentsMatching(
        collection: 'qualityChecks',
        factoryId: factoryId,
        field: 'referenceId',
        value: loadDoc.id,
      );
    }

    await _deleteLoadsForJobWork(factoryId: factoryId, jobWorkId: id);
    await _deleteDocumentsMatching(
      collection: 'jobWorkCollections',
      factoryId: factoryId,
      field: 'jobWorkOrderId',
      value: id,
    );
    await _deleteInvoicesAndPaymentsForJobWork(
      factoryId: factoryId,
      jobWorkId: id,
    );
    await _deleteDocumentsMatching(
      collection: 'qualityChecks',
      factoryId: factoryId,
      field: 'referenceId',
      value: id,
    );
    await _jobWorkCollection.doc(id).delete();
    EntityReactiveEventBus.instance.notifyDeleted<JobWorkOrder>(order);
  }

  Future<void> _deleteInvoicesAndPaymentsForJobWork({
    required String factoryId,
    required String jobWorkId,
  }) async {
    final invoiceSnap = await _firestore
        .collection('jobWorkInvoices')
        .where('factoryId', isEqualTo: factoryId)
        .get();
    final invoices = invoiceSnap.docs
        .where((doc) => doc.data()['jobWorkId'] == jobWorkId)
        .toList();

    if (invoices.isEmpty) return;

    final toDelete = <DocumentReference<Map<String, dynamic>>>[];
    for (final invoiceDoc in invoices) {
      final paymentsSnap = await _firestore
          .collection('payments')
          .where('factoryId', isEqualTo: factoryId)
          .get();
      final payments = paymentsSnap.docs
          .where((doc) => doc.data()['invoiceId'] == invoiceDoc.id)
          .toList();

      toDelete.addAll(payments.map((doc) => doc.reference));
      toDelete.add(invoiceDoc.reference);
    }
    await _commitDeletes(toDelete);
  }

  Future<void> _deleteDocumentsMatching({
    required String collection,
    required String factoryId,
    required String field,
    required String value,
  }) async {
    final snapshot = await _firestore
        .collection(collection)
        .where('factoryId', isEqualTo: factoryId)
        .get();
    final docs = snapshot.docs
        .where((doc) => doc.data()[field] == value)
        .toList();

    if (docs.isEmpty) return;
    await _commitDeletes(
      docs.map((doc) => doc.reference).toList(),
    );
  }

  Future<void> _commitDeletes(
    List<DocumentReference<Map<String, dynamic>>> refs,
  ) async {
    const batchLimit = 400;
    for (var index = 0; index < refs.length; index += batchLimit) {
      final batch = _firestore.batch();
      final chunk = refs.skip(index).take(batchLimit);
      for (final ref in chunk) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  Future<void> advanceJobWorkStatus(String id, JobWorkStatus status) async {
    final order = await getJobWorkOrder(id);
    // Sprint 7: container status is rolled up from Loads — skip order-level FSM.
    if (order != null && order.isLoadsAuthoritative) {
      return;
    }
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
      (JobWorkStatus.collected, JobWorkStatus.closed) => true,
      _ => false,
    };
    if (!allowed) {
      throw StateError('Invalid job work completion status transition.');
    }

    final updates = <String, dynamic>{
      'status': targetStatus.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
      'closedAt': FieldValue.serverTimestamp(),
    };

    await _jobWorkCollection.doc(id).update(updates);
  }

  /// Applies collection-derived status (partiallyCollected / collected).
  Future<void> syncCollectionDerivedStatus(String jobWorkId) async {
    final order = await getJobWorkOrder(jobWorkId);
    if (order == null) return;
    // Sprint 7: Load-scoped collection sync owns status when migrated.
    if (order.isLoadsAuthoritative) return;

    final snapshot = await _firestore
        .collection('jobWorkCollections')
        .where('factoryId', isEqualTo: order.factoryId)
        .where('jobWorkOrderId', isEqualTo: jobWorkId)
        .get();
    final collections = snapshot.docs
        .map(
          (doc) => JobWorkCollectionModel.fromFirestore(doc.id, doc.data())
              .toEntity(),
        )
        .toList();

    final targetStatus = JobWorkCollectionStatusHelper.resolveTargetStatus(
      order: order,
      collections: collections,
    );
    if (targetStatus == null || targetStatus == order.status) return;

    final updates = <String, dynamic>{
      'status': targetStatus.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (targetStatus == JobWorkStatus.collected) {
      updates['collectedAt'] = FieldValue.serverTimestamp();
    }
    if (order.status == JobWorkStatus.collected &&
        targetStatus != JobWorkStatus.collected) {
      updates['collectedAt'] = FieldValue.delete();
    }

    await _jobWorkCollection.doc(jobWorkId).update(updates);
  }

  Future<JobWorkOrder> recordJobWorkOutput(JobWorkOrder order) async {
    final existing = await getJobWorkOrder(order.id) ?? order;
    if (existing.isLoadsAuthoritative) {
      throw StateError(
        'Record output on a Load. Job Work no longer stores nested output.',
      );
    }

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
    final saved = (await getJobWorkOrder(order.id)) ?? updated;
    await syncCollectionDerivedStatus(saved.id);
    return (await getJobWorkOrder(order.id)) ?? saved;
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
    final order = await getJobWorkOrder(id);
    if (order == null) {
      throw StateError('Job work order not found.');
    }

    final batch = _firestore.batch();

    // 1. Cancel all loads
    final loadSnap = await _firestore
        .collection('jobWorkLoads')
        .where('factoryId', isEqualTo: order.factoryId)
        .where('jobWorkId', isEqualTo: id)
        .get();

    for (final doc in loadSnap.docs) {
      batch.update(doc.reference, {
        'status': JobWorkStatus.cancelled.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 2. Cancel Job Work Order
    batch.update(_jobWorkCollection.doc(id), {
      'status': JobWorkStatus.cancelled.firestoreValue,
      'summaryStatus': 'cancelled',
      'activeLoadCount': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 3. Cancel linked invoices
    final invoiceSnap = await _firestore
        .collection('jobWorkInvoices')
        .where('factoryId', isEqualTo: order.factoryId)
        .where('jobWorkId', isEqualTo: id)
        .get();

    for (final doc in invoiceSnap.docs) {
      batch.update(doc.reference, {
        'status': InvoiceStatus.cancelled.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 4. Void linked payments
    final paymentsSnap = await _firestore
        .collection('payments')
        .where('factoryId', isEqualTo: order.factoryId)
        .where('customerId', isEqualTo: order.customerId)
        .get();

    final loadIds = loadSnap.docs.map((d) => d.id).toSet();
    final invoiceIds = invoiceSnap.docs.map((d) => d.id).toSet();

    for (final doc in paymentsSnap.docs) {
      final data = doc.data();
      final orderId = data['orderId'] as String? ?? '';
      final loadId = data['loadId'] as String? ?? '';
      final invoiceId = data['invoiceId'] as String? ?? '';

      if (orderId == id ||
          loadIds.contains(loadId) ||
          invoiceIds.contains(invoiceId) ||
          doc.id == 'advance_job_$id' ||
          doc.id.startsWith('advance_load_')) {
        batch.update(doc.reference, {
          'status': PaymentStatus.voided.firestoreValue,
          'notes': '${data['notes'] ?? ''} (Cancelled with Job Work #${order.jobWorkNumber})'.trim(),
        });
      }
    }

    await batch.commit();
    EntityReactiveEventBus.instance.notifyUpdated<JobWorkOrder>(
      order.copyWith(status: JobWorkStatus.cancelled),
    );
  }

  /// Live count of non-cancelled job work orders for a customer.
  Stream<int> watchActiveOrderCountForCustomer({
    required String factoryId,
    required String customerId,
  }) {
    return watchOrdersForCustomer(
      factoryId: factoryId,
      customerId: customerId,
    ).map((orders) => orders.length);
  }

  /// Non-cancelled job work orders for a customer (newest first).
  ///
  /// Query is `factoryId` + `customerId` so a single-customer sync does not
  /// download the rest of the factory.
  Stream<List<JobWorkOrder>> watchOrdersForCustomer({
    required String factoryId,
    required String customerId,
  }) {
    return _ordersForCustomerQuery(
      factoryId: factoryId,
      customerId: customerId,
    ).snapshots().map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => JobWorkOrderModel.fromFirestore(doc.id, doc.data()))
          .map((model) => model.toEntity())
          .where((order) => order.status != JobWorkStatus.cancelled)
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Future<List<JobWorkOrder>> getOrdersForCustomer({
    required String factoryId,
    required String customerId,
  }) async {
    final snapshot = await _ordersForCustomerQuery(
      factoryId: factoryId,
      customerId: customerId,
    ).get();
    final orders = snapshot.docs
        .map((doc) => JobWorkOrderModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  Query<Map<String, dynamic>> _ordersForCustomerQuery({
    required String factoryId,
    required String customerId,
  }) {
    return _jobWorkCollection
        .where('factoryId', isEqualTo: factoryId)
        .where('customerId', isEqualTo: customerId);
  }

  Future<int> countOrdersForCustomer({
    required String factoryId,
    required String customerId,
  }) async {
    final orders = await getOrdersForCustomer(
      factoryId: factoryId,
      customerId: customerId,
    );
    return orders.where((order) => order.customerId == customerId).length;
  }

  Future<void> deleteOrdersForCustomer({
    required String factoryId,
    required String customerId,
  }) async {
    final snapshot = await _jobWorkCollection
        .where('factoryId', isEqualTo: factoryId)
        .get();
    final docs = snapshot.docs
        .where((doc) => doc.data()['customerId'] == customerId)
        .toList();

    if (docs.isEmpty) return;

    for (final doc in docs) {
      await deleteJobWorkOrder(doc.id);
    }
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

    for (final doc in orphanedDocs) {
      await deleteJobWorkOrder(doc.id);
    }

    return orphanedDocs.length;
  }

  Future<void> _deleteLoadsForJobWork({
    required String factoryId,
    required String jobWorkId,
  }) async {
    final snapshot = await _firestore
        .collection('jobWorkLoads')
        .where('factoryId', isEqualTo: factoryId)
        .where('jobWorkId', isEqualTo: jobWorkId)
        .get();
    if (snapshot.docs.isEmpty) return;

    const batchLimit = 400;
    for (var index = 0; index < snapshot.docs.length; index += batchLimit) {
      final batch = _firestore.batch();
      final chunk = snapshot.docs.skip(index).take(batchLimit);
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
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

  Future<String> _generateJobWorkNumber(String factoryId) {
    return _sequenceNumberService.allocate(
      factoryId: factoryId,
      sequence: DocumentSequence.jobWorkOrder,
    );
  }
}
