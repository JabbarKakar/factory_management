import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/job_work_charges_calculator.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/job_work_output.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/job_work_load_enums.dart';
import '../models/job_work_load_model.dart';
import '../services/job_work_container_sync_helper.dart';
import '../services/job_work_load_production_helper.dart';
import '../services/job_work_load_resolver.dart';
import 'job_work_repository.dart';

class JobWorkLoadException implements Exception {
  const JobWorkLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class JobWorkLoadRepository {
  JobWorkLoadRepository({
    FirebaseFirestore? firestore,
    JobWorkRepository? jobWorkRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _jobWorkRepository =
            jobWorkRepository ?? JobWorkRepository(firestore: firestore);

  final FirebaseFirestore _firestore;
  final JobWorkRepository _jobWorkRepository;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _loads =>
      _firestore.collection('jobWorkLoads');

  CollectionReference<Map<String, dynamic>> get _jobWorkOrders =>
      _firestore.collection('jobWorkOrders');

  CollectionReference<Map<String, dynamic>> get _invoices =>
      _firestore.collection('jobWorkInvoices');

  CollectionReference<Map<String, dynamic>> get _collections =>
      _firestore.collection('jobWorkCollections');

  Stream<List<JobWorkLoad>> watchLoads(String factoryId) {
    return _loads.where('factoryId', isEqualTo: factoryId).snapshots().map(
      (snapshot) {
        final loads = snapshot.docs
            .map((doc) => JobWorkLoadModel.fromFirestore(doc.id, doc.data()))
            .map((model) => model.toEntity())
            .toList();
        loads.sort((a, b) {
          final jobCompare = a.jobWorkId.compareTo(b.jobWorkId);
          if (jobCompare != 0) return jobCompare;
          return a.loadSequence.compareTo(b.loadSequence);
        });
        return loads;
      },
    );
  }

  Stream<List<JobWorkLoad>> watchLoadsForJobWork({
    required String factoryId,
    required String jobWorkId,
  }) {
    return _loads
        .where('factoryId', isEqualTo: factoryId)
        .where('jobWorkId', isEqualTo: jobWorkId)
        .snapshots()
        .map((snapshot) {
      final loads = snapshot.docs
          .map((doc) => JobWorkLoadModel.fromFirestore(doc.id, doc.data()))
          .map((model) => model.toEntity())
          .toList();
      loads.sort((a, b) => a.loadSequence.compareTo(b.loadSequence));
      return loads;
    });
  }

  Future<List<JobWorkLoad>> fetchLoadsForJobWork({
    required String factoryId,
    required String jobWorkId,
  }) async {
    final snapshot = await _loads
        .where('factoryId', isEqualTo: factoryId)
        .where('jobWorkId', isEqualTo: jobWorkId)
        .get();
    final loads = snapshot.docs
        .map((doc) => JobWorkLoadModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .toList();
    loads.sort((a, b) => a.loadSequence.compareTo(b.loadSequence));
    return loads;
  }

  Future<JobWorkLoad?> getLoad(String id) async {
    final doc = await _loads.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return JobWorkLoadModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Stream<JobWorkLoad?> watchLoad(String id) {
    return _loads.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return JobWorkLoadModel.fromFirestore(doc.id, doc.data()!).toEntity();
    });
  }

  /// Idempotent: creates Load #1 from nested JW fields when none exist.
  ///
  /// Also stamps container `schemaVersion` / `defaultLoadId` and best-effort
  /// backfills `loadId` on existing invoices/collections when this is the only
  /// Load (safe attribution).
  Future<JobWorkLoad> ensureDefaultLoad(String jobWorkId) async {
    final order = await _jobWorkRepository.getJobWorkOrder(jobWorkId);
    if (order == null) {
      throw const JobWorkLoadException('Job work order not found.');
    }

    final existing = await fetchLoadsForJobWork(
      factoryId: order.factoryId,
      jobWorkId: jobWorkId,
    );
    if (existing.isNotEmpty) {
      final preferred = JobWorkLoadResolver.preferredDefaultLoad(order, existing);
      if (order.defaultLoadId != preferred.id ||
          !order.isLoadsAuthoritative ||
          order.loadCount != existing.length) {
        await _markJobWorkMigrated(
          order: order,
          defaultLoadId: preferred.id,
          loads: existing,
        );
      }
      // Only auto-stamp orphans onto the default Load when there is exactly one.
      if (existing.length == 1) {
        await _backfillChildLoadIds(
          factoryId: order.factoryId,
          jobWorkId: jobWorkId,
          loadId: preferred.id,
          loadNumber: preferred.loadNumber,
        );
      }
      return preferred;
    }

    final loadId = _uuid.v4();
    final loadNumber = await _generateLoadNumber(order.factoryId);
    final load = JobWorkLoad.fromLegacyOrder(
      order,
      id: loadId,
      loadNumber: loadNumber,
      loadSequence: 1,
      migratedFromJobWork: true,
      isVirtual: false,
    );

    final batch = _firestore.batch();
    batch.set(
      _loads.doc(loadId),
      JobWorkLoadModel.fromEntity(load).toFirestore(isCreate: true),
    );
    _applyJobWorkMigratedUpdate(
      batch: batch,
      order: order,
      defaultLoadId: loadId,
      loadCount: 1,
      activeLoadCount: load.status.isCompleted ||
              load.status == LoadStatus.cancelled
          ? 0
          : 1,
      summaryStatus: JobWorkSummaryStatus.fromLoadStatuses([load.status]),
      containerStatus: JobWorkContainerSyncHelper.resolveContainerStatus(
        order: order,
        loads: [load],
      ),
      finalCuttingCharges: JobWorkContainerSyncHelper.rollupFinalCuttingCharges(
        order: order,
        loads: [load],
      ),
      advanceReceived: JobWorkContainerSyncHelper.rollupAdvanceReceived(
        order: order,
        loads: [load],
      ),
      balanceDue: JobWorkContainerSyncHelper.rollupBalanceDue(
        order: order,
        loads: [load],
      ),
    );
    await batch.commit();

    await _backfillChildLoadIds(
      factoryId: order.factoryId,
      jobWorkId: jobWorkId,
      loadId: loadId,
      loadNumber: loadNumber,
    );

    return (await getLoad(loadId)) ?? load;
  }

  /// Creates a new Load under an existing Job Work (Add Load).
  Future<JobWorkLoad> createLoad(JobWorkLoad draft) async {
    final order = await _jobWorkRepository.getJobWorkOrder(draft.jobWorkId);
    if (order == null) {
      throw const JobWorkLoadException('Job work order not found.');
    }

    final existing = await fetchLoadsForJobWork(
      factoryId: order.factoryId,
      jobWorkId: order.id,
    );
    final id = draft.id.isEmpty ? _uuid.v4() : draft.id;
    final loadNumber = draft.loadNumber.isEmpty
        ? await _generateLoadNumber(order.factoryId)
        : draft.loadNumber;
    final sequence = draft.loadSequence > 0
        ? draft.loadSequence
        : JobWorkLoadResolver.nextLoadSequence(existing);

    final load = draft.copyWith(
      id: id,
      loadNumber: loadNumber,
      loadSequence: sequence,
      jobWorkId: order.id,
      jobWorkNumber: order.jobWorkNumber,
      factoryId: order.factoryId,
      customerId: order.customerId,
      customerName: order.customerName,
      isVirtual: false,
    );

    final allLoads = [...existing, load];
    final batch = _firestore.batch();
    batch.set(
      _loads.doc(id),
      JobWorkLoadModel.fromEntity(load).toFirestore(isCreate: true),
    );
    _applyJobWorkMigratedUpdate(
      batch: batch,
      order: order,
      defaultLoadId: order.defaultLoadId ??
          (existing.isNotEmpty ? existing.first.id : id),
      loadCount: allLoads.length,
      activeLoadCount: _activeLoadCount(allLoads),
      summaryStatus: JobWorkSummaryStatus.fromLoadStatuses(
        allLoads.map((item) => item.status),
      ),
      containerStatus: JobWorkContainerSyncHelper.resolveContainerStatus(
        order: order,
        loads: allLoads,
      ),
      finalCuttingCharges: JobWorkContainerSyncHelper.rollupFinalCuttingCharges(
        order: order,
        loads: allLoads,
      ),
      advanceReceived: JobWorkContainerSyncHelper.rollupAdvanceReceived(
        order: order,
        loads: allLoads,
      ),
      balanceDue: JobWorkContainerSyncHelper.rollupBalanceDue(
        order: order,
        loads: allLoads,
      ),
    );
    await batch.commit();
    return (await getLoad(id)) ?? load;
  }

  /// Updates an existing Load and refreshes JW container counters.
  Future<JobWorkLoad> updateLoad(JobWorkLoad load) async {
    if (load.id.isEmpty || load.isVirtual) {
      throw const JobWorkLoadException('Cannot update a virtual or empty load.');
    }
    final order = await _jobWorkRepository.getJobWorkOrder(load.jobWorkId);
    if (order == null) {
      throw const JobWorkLoadException('Job work order not found.');
    }

    await _loads.doc(load.id).update(
          JobWorkLoadModel.fromEntity(load).toFirestore(),
        );

    final existing = await fetchLoadsForJobWork(
      factoryId: order.factoryId,
      jobWorkId: order.id,
    );
    await _markJobWorkMigrated(
      order: order,
      defaultLoadId: order.defaultLoadId ??
          JobWorkLoadResolver.preferredDefaultLoad(order, existing).id,
      loads: existing,
    );
    return (await getLoad(load.id)) ?? load;
  }

  /// Records output / shifts / execution on a Load and advances Load status.
  ///
  /// Does not mutate other Loads or close the parent Job Work.
  Future<JobWorkLoad> recordLoadOutput(JobWorkLoad load) async {
    if (load.id.isEmpty || load.isVirtual) {
      throw const JobWorkLoadException('Cannot record output on a virtual load.');
    }
    if (!load.status.canRecordOutput) {
      throw const JobWorkLoadException(
        'Output cannot be recorded for this load status.',
      );
    }

    final manualOutput = load.output ?? const JobWorkOutput();
    final output = load.shiftLogs.isNotEmpty
        ? JobWorkOutput.aggregateFromShifts(
            load.shiftLogs,
            wasteDisposition: manualOutput.wasteDisposition,
            slurryDust: manualOutput.slurryDust,
          ).copyWith(
            wasteAmount: manualOutput.wasteAmount,
            wasteUnit: manualOutput.wasteUnit,
            recordedAt: DateTime.now(),
          )
        : manualOutput.copyWith(recordedAt: DateTime.now());

    final finalCuttingCharges = JobWorkChargesCalculator.calculateForLoad(
      load: load,
      output: output,
      shiftLogs: load.shiftLogs,
    );
    final resolvedCharges = finalCuttingCharges > 0
        ? finalCuttingCharges
        : load.finalCuttingCharges;
    final balanceDue = resolvedCharges - load.advanceReceived;

    final withOutput = load.copyWith(
      output: output,
      finalCuttingCharges: resolvedCharges,
      balanceDue: balanceDue,
    );
    final newStatus =
        JobWorkLoadProductionHelper.statusAfterOutputSaved(withOutput);
    final updated = withOutput.copyWith(status: newStatus);
    return updateLoad(updated);
  }

  /// Advances a single Load's operational status (cutting FSM).
  Future<JobWorkLoad> advanceLoadStatus({
    required String loadId,
    required LoadStatus newStatus,
  }) async {
    final load = await getLoad(loadId);
    if (load == null) {
      throw const JobWorkLoadException('Load not found.');
    }
    if (load.isVirtual) {
      throw const JobWorkLoadException('Cannot advance a virtual load.');
    }

    var updated = load.copyWith(status: newStatus);
    if (newStatus == LoadStatus.inCutting) {
      final execution = (load.execution ?? const JobWorkExecution()).copyWith(
        cuttingStartDate: load.execution?.cuttingStartDate ?? DateTime.now(),
      );
      updated = updated.copyWith(execution: execution);
    }
    if (newStatus == LoadStatus.qc || newStatus == LoadStatus.ready) {
      final execution = (updated.execution ?? const JobWorkExecution()).copyWith(
        cuttingCompletionDate:
            updated.execution?.cuttingCompletionDate ?? DateTime.now(),
      );
      updated = updated.copyWith(execution: execution);
    }

    return updateLoad(updated);
  }

  /// Completes a Load (`collected` → `closed`) without closing the Job Work.
  Future<JobWorkLoad> advanceLoadCompletionStatus({
    required String loadId,
    required LoadStatus targetStatus,
  }) async {
    final load = await getLoad(loadId);
    if (load == null) {
      throw const JobWorkLoadException('Load not found.');
    }

    final allowed = switch ((load.status, targetStatus)) {
      (LoadStatus.collected, LoadStatus.closed) => true,
      _ => false,
    };
    if (!allowed) {
      throw const JobWorkLoadException(
        'Invalid load completion status transition.',
      );
    }

    return updateLoad(
      load.copyWith(
        status: targetStatus,
        closedAt: DateTime.now(),
      ),
    );
  }

  /// Deletes one Load and all belonging records (collections, QC, invoices,
  /// payments). Output and shift logs live on the Load document and go with it.
  ///
  /// Returns `true` when this was the last Load and the parent Job Work was
  /// deleted as well.
  Future<bool> deleteLoad(String loadId) async {
    final load = await getLoad(loadId);
    if (load == null) {
      throw const JobWorkLoadException('Load not found.');
    }
    if (load.isVirtual) {
      throw const JobWorkLoadException('Cannot delete a virtual load.');
    }

    final order = await _jobWorkRepository.getJobWorkOrder(load.jobWorkId);
    if (order == null) {
      throw const JobWorkLoadException('Job work order not found.');
    }

    final existingLoads = await fetchLoadsForJobWork(
      factoryId: order.factoryId,
      jobWorkId: order.id,
    );
    final isLastLoad = existingLoads.length <= 1;

    final collectionSnap = await _collections
        .where('factoryId', isEqualTo: load.factoryId)
        .where('loadId', isEqualTo: loadId)
        .get();
    final invoiceSnap = await _invoices
        .where('factoryId', isEqualTo: load.factoryId)
        .where('loadId', isEqualTo: loadId)
        .get();
    final qcSnap = await _firestore
        .collection('qualityChecks')
        .where('factoryId', isEqualTo: load.factoryId)
        .where('referenceId', isEqualTo: loadId)
        .where(
          'referenceType',
          isEqualTo: 'jobWorkLoad',
        )
        .get();

    final paymentRefs = <DocumentReference<Map<String, dynamic>>>[];
    for (final invoiceDoc in invoiceSnap.docs) {
      final paymentsSnap = await _firestore
          .collection('payments')
          .where('factoryId', isEqualTo: load.factoryId)
          .where('invoiceId', isEqualTo: invoiceDoc.id)
          .get();
      paymentRefs.addAll(paymentsSnap.docs.map((doc) => doc.reference));
    }

    final toDelete = <DocumentReference<Map<String, dynamic>>>[
      ...collectionSnap.docs.map((doc) => doc.reference),
      ...qcSnap.docs.map((doc) => doc.reference),
      ...paymentRefs,
      ...invoiceSnap.docs.map((doc) => doc.reference),
      _loads.doc(loadId),
    ];

    const batchLimit = 400;
    for (var index = 0; index < toDelete.length; index += batchLimit) {
      final batch = _firestore.batch();
      final chunk = toDelete.skip(index).take(batchLimit);
      for (final ref in chunk) {
        batch.delete(ref);
      }
      await batch.commit();
    }

    if (isLastLoad) {
      // Last load gone → remove the Job Work container entirely.
      await _jobWorkRepository.deleteJobWorkOrder(order.id);
      return true;
    }

    final remaining = await fetchLoadsForJobWork(
      factoryId: order.factoryId,
      jobWorkId: order.id,
    );
    final defaultLoadId = (order.defaultLoadId == loadId)
        ? JobWorkLoadResolver.preferredDefaultLoad(order, remaining).id
        : (order.defaultLoadId ??
            JobWorkLoadResolver.preferredDefaultLoad(order, remaining).id);
    await _markJobWorkMigrated(
      order: order,
      defaultLoadId: defaultLoadId,
      loads: remaining,
    );
    return false;
  }

  /// Deletes all loads for a Job Work (cascade helper).
  Future<int> deleteLoadsForJobWork({
    required String factoryId,
    required String jobWorkId,
  }) async {
    final snapshot = await _loads
        .where('factoryId', isEqualTo: factoryId)
        .where('jobWorkId', isEqualTo: jobWorkId)
        .get();
    if (snapshot.docs.isEmpty) return 0;

    var deleted = 0;
    for (final doc in snapshot.docs) {
      await deleteLoad(doc.id);
      deleted++;
    }
    return deleted;
  }

  int _activeLoadCount(List<JobWorkLoad> loads) {
    return loads
        .where(
          (load) =>
              !load.status.isCompleted && load.status != LoadStatus.cancelled,
        )
        .length;
  }

  Future<void> _markJobWorkMigrated({
    required JobWorkOrder order,
    required String defaultLoadId,
    required List<JobWorkLoad> loads,
  }) async {
    final activeCount = loads
        .where(
          (load) =>
              !load.status.isCompleted && load.status != LoadStatus.cancelled,
        )
        .length;
    final batch = _firestore.batch();
    _applyJobWorkMigratedUpdate(
      batch: batch,
      order: order,
      defaultLoadId: defaultLoadId,
      loadCount: loads.length,
      activeLoadCount: activeCount,
      summaryStatus: JobWorkSummaryStatus.fromLoadStatuses(
        loads.map((load) => load.status),
      ),
      containerStatus: JobWorkContainerSyncHelper.resolveContainerStatus(
        order: order,
        loads: loads,
      ),
      finalCuttingCharges: JobWorkContainerSyncHelper.rollupFinalCuttingCharges(
        order: order,
        loads: loads,
      ),
      advanceReceived: JobWorkContainerSyncHelper.rollupAdvanceReceived(
        order: order,
        loads: loads,
      ),
      balanceDue: JobWorkContainerSyncHelper.rollupBalanceDue(
        order: order,
        loads: loads,
      ),
    );
    await batch.commit();
  }

  void _applyJobWorkMigratedUpdate({
    required WriteBatch batch,
    required JobWorkOrder order,
    required String defaultLoadId,
    required int loadCount,
    required int activeLoadCount,
    required JobWorkSummaryStatus summaryStatus,
    required JobWorkStatus containerStatus,
    required double finalCuttingCharges,
    required double advanceReceived,
    required double balanceDue,
  }) {
    batch.update(_jobWorkOrders.doc(order.id), {
      'schemaVersion': JobWorkSchemaVersion.loadsAuthoritative,
      'defaultLoadId': defaultLoadId,
      'loadCount': loadCount,
      'activeLoadCount': activeLoadCount,
      'summaryStatus': summaryStatus.firestoreValue,
      'status': containerStatus.firestoreValue,
      'finalCuttingCharges': finalCuttingCharges,
      'advanceReceived': advanceReceived,
      'balanceDue': balanceDue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _backfillChildLoadIds({
    required String factoryId,
    required String jobWorkId,
    required String loadId,
    required String loadNumber,
  }) async {
    final invoiceSnap = await _invoices
        .where('factoryId', isEqualTo: factoryId)
        .where('jobWorkId', isEqualTo: jobWorkId)
        .get();
    final collectionSnap = await _collections
        .where('factoryId', isEqualTo: factoryId)
        .where('jobWorkOrderId', isEqualTo: jobWorkId)
        .get();

    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[
      ...invoiceSnap.docs,
      ...collectionSnap.docs,
    ];
    if (docs.isEmpty) return;

    const batchLimit = 400;
    for (var index = 0; index < docs.length; index += batchLimit) {
      final batch = _firestore.batch();
      final chunk = docs.skip(index).take(batchLimit);
      for (final doc in chunk) {
        final data = doc.data();
        if (data['loadId'] != null &&
            (data['loadId'] as String).trim().isNotEmpty) {
          continue;
        }
        batch.update(doc.reference, {
          'loadId': loadId,
          'loadNumber': loadNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Future<String> _generateLoadNumber(String factoryId) async {
    final year = DateTime.now().year;
    final snapshot =
        await _loads.where('factoryId', isEqualTo: factoryId).get();
    final count = snapshot.docs.length + 1;
    return 'JWL-$year-${count.toString().padLeft(4, '0')}';
  }

  /// Resolve loads for UI/read paths (persisted or virtual).
  Future<List<JobWorkLoad>> resolveLoadsForJobWork(String jobWorkId) async {
    final order = await _jobWorkRepository.getJobWorkOrder(jobWorkId);
    if (order == null) return const [];
    final loads = await fetchLoadsForJobWork(
      factoryId: order.factoryId,
      jobWorkId: jobWorkId,
    );
    return JobWorkLoadResolver.resolveLoads(order, loads);
  }
}
