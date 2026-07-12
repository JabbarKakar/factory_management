import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/stock_output_calculator.dart';
import '../../domain/entities/job_work_collection.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/enums/job_work_collection_enums.dart';
import '../models/job_work_collection_model.dart';
import '../services/job_work_collection_quantity_helper.dart';
import '../services/job_work_collection_status_helper.dart';
import 'job_work_load_repository.dart';
import 'job_work_repository.dart';

class JobWorkCollectionException implements Exception {
  const JobWorkCollectionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class JobWorkCollectionRepository {
  JobWorkCollectionRepository({
    FirebaseFirestore? firestore,
    JobWorkRepository? jobWorkRepository,
    JobWorkLoadRepository? loadRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _jobWorkRepository =
            jobWorkRepository ?? JobWorkRepository(firestore: firestore),
        _loadRepository = loadRepository ??
            JobWorkLoadRepository(
              firestore: firestore,
              jobWorkRepository: jobWorkRepository,
            );

  final FirebaseFirestore _firestore;
  final JobWorkRepository _jobWorkRepository;
  final JobWorkLoadRepository _loadRepository;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('jobWorkCollections');

  Stream<List<JobWorkCollection>> watchCollections(String factoryId) {
    return _collection.where('factoryId', isEqualTo: factoryId).snapshots().map(
      (snapshot) {
        final collections = snapshot.docs
            .map(
              (doc) => JobWorkCollectionModel.fromFirestore(doc.id, doc.data()),
            )
            .map((model) => model.toEntity())
            .toList();
        collections.sort((a, b) => b.collectedAt.compareTo(a.collectedAt));
        return collections;
      },
    );
  }

  Stream<List<JobWorkCollection>> watchCollectionsForJobWork({
    required String factoryId,
    required String jobWorkOrderId,
  }) {
    return _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('jobWorkOrderId', isEqualTo: jobWorkOrderId)
        .snapshots()
        .map((snapshot) {
      final collections = snapshot.docs
          .map((doc) => JobWorkCollectionModel.fromFirestore(doc.id, doc.data()))
          .map((model) => model.toEntity())
          .toList();
      collections.sort((a, b) => b.collectedAt.compareTo(a.collectedAt));
      return collections;
    });
  }

  Future<List<JobWorkCollection>> fetchCollectionsForJobWork({
    required String factoryId,
    required String jobWorkOrderId,
  }) async {
    final snapshot = await _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('jobWorkOrderId', isEqualTo: jobWorkOrderId)
        .get();
    final collections = snapshot.docs
        .map((doc) => JobWorkCollectionModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .toList();
    collections.sort((a, b) => b.collectedAt.compareTo(a.collectedAt));
    return collections;
  }

  Future<JobWorkCollection?> getCollection(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return JobWorkCollectionModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  /// One-step Collect Material: creates a collected record with quantities.
  ///
  /// Sprint 4: always stamps [loadId]/[loadNumber]. When [loadId] is omitted,
  /// resolves/creates the default Load (and backfills orphan collections).
  Future<JobWorkCollection> recordCollection({
    required String jobWorkOrderId,
    required DateTime collectedAt,
    required List<JobWorkCollectionLineItem> lineItems,
    String? loadId,
    String? receiverName,
    String? notes,
  }) async {
    final order = await _jobWorkRepository.getJobWorkOrder(jobWorkOrderId);
    if (order == null) {
      throw const JobWorkCollectionException('Job work order not found.');
    }

    final load = await _resolveLoadForCollection(
      jobWorkOrderId: order.id,
      loadId: loadId,
    );
    if (!load.status.canCollectMaterial) {
      throw const JobWorkCollectionException(
        'Material can only be collected after cutting has started, '
        'and not after the load is fully collected or closed.',
      );
    }

    final normalized = _normalizeLineItems(lineItems);
    if (normalized.isEmpty) {
      throw const JobWorkCollectionException(
        'Enter pieces to collect for at least one size.',
      );
    }

    final existing = await fetchCollectionsForJobWork(
      factoryId: order.factoryId,
      jobWorkOrderId: order.id,
    );
    _validateAgainstRemainingForLoad(
      load: load,
      lineItems: normalized,
      existingCollections: existing,
    );

    final id = _uuid.v4();
    final collectionNumber = await _generateCollectionNumber(order.factoryId);
    final record = JobWorkCollection(
      id: id,
      collectionNumber: collectionNumber,
      factoryId: order.factoryId,
      jobWorkOrderId: order.id,
      jobWorkNumber: order.jobWorkNumber,
      customerId: order.customerId,
      customerName: order.customerName,
      loadId: load.id,
      loadNumber: load.loadNumber,
      collectedAt: collectedAt,
      status: JobWorkCollectionStatus.collected,
      lineItems: normalized,
      receiverName: receiverName?.trim().isEmpty ?? true
          ? null
          : receiverName?.trim(),
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      createdAt: DateTime.now(),
    );

    final model = JobWorkCollectionModel.fromEntity(record);
    await _collection.doc(id).set(model.toFirestore(isCreate: true));
    await _syncLoadCollectionDerivedStatus(load.id);
    final created = await getCollection(id);
    return created ?? record;
  }

  /// Re-applies collection-derived Load status (heals rounding dust leftovers).
  Future<void> syncLoadCollectionDerivedStatus(String loadId) =>
      _syncLoadCollectionDerivedStatus(loadId);

  Future<JobWorkLoad> _resolveLoadForCollection({
    required String jobWorkOrderId,
    String? loadId,
  }) async {
    if (loadId != null && loadId.isNotEmpty) {
      final load = await _loadRepository.getLoad(loadId);
      if (load == null) {
        throw const JobWorkCollectionException('Load not found.');
      }
      if (load.jobWorkId != jobWorkOrderId) {
        throw const JobWorkCollectionException(
          'Load does not belong to this job work order.',
        );
      }
      if (load.isVirtual) {
        throw const JobWorkCollectionException(
          'Cannot collect material on a virtual load.',
        );
      }
      return load;
    }

    try {
      return await _loadRepository.ensureDefaultLoad(jobWorkOrderId);
    } on JobWorkLoadException catch (error) {
      throw JobWorkCollectionException(error.message);
    }
  }

  Future<void> _syncLoadCollectionDerivedStatus(String loadId) async {
    final load = await _loadRepository.getLoad(loadId);
    if (load == null) return;

    final collections = await fetchCollectionsForJobWork(
      factoryId: load.factoryId,
      jobWorkOrderId: load.jobWorkId,
    );
    final targetStatus =
        JobWorkCollectionStatusHelper.resolveTargetStatusForLoad(
      load: load,
      collections: collections,
    );
    if (targetStatus == null || targetStatus == load.status) return;

    await _loadRepository.updateLoad(load.copyWith(status: targetStatus));
  }

  List<JobWorkCollectionLineItem> _normalizeLineItems(
    List<JobWorkCollectionLineItem> lineItems,
  ) {
    final normalized = <JobWorkCollectionLineItem>[];
    for (final item in lineItems) {
      if (item.pieces <= 0) continue;
      final computed = StockOutputCalculator.compute(
        size: item.size,
        pieces: item.pieces,
        pricePerSqFt: 0,
      );
      // Prefer provided sq.ft (full remaining pickup clears rounding dust).
      final squareFeet = item.squareFeet > 0
          ? double.parse(item.squareFeet.toStringAsFixed(2))
          : computed.squareFeet;
      normalized.add(item.copyWith(squareFeet: squareFeet));
    }
    return normalized;
  }

  void _validateAgainstRemainingForLoad({
    required JobWorkLoad load,
    required List<JobWorkCollectionLineItem> lineItems,
    required List<JobWorkCollection> existingCollections,
  }) {
    final remainingBySize = {
      for (final line in JobWorkCollectionQuantityHelper.remainingLinesForLoad(
        load,
        existingCollections,
      ))
        line.size: line,
    };

    for (final item in lineItems) {
      final remaining = remainingBySize[item.size];
      if (remaining == null) {
        throw JobWorkCollectionException(
          'No remaining stock for size ${item.size}.',
        );
      }
      if (item.pieces > remaining.remainingPieces) {
        throw JobWorkCollectionException(
          'Cannot collect ${item.pieces} pcs of ${item.size}. '
          'Only ${remaining.remainingPieces} remaining.',
        );
      }
    }
  }

  Future<String> _generateCollectionNumber(String factoryId) async {
    final year = DateTime.now().year;
    final snapshot =
        await _collection.where('factoryId', isEqualTo: factoryId).get();
    final count = snapshot.docs.length + 1;
    return 'JC-$year-${count.toString().padLeft(4, '0')}';
  }
}
