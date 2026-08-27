import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/stock_output_calculator.dart';
import '../../core/observability/tracked_firestore.dart';
import '../../core/utils/firestore_query_constraints.dart';
import '../../domain/entities/job_work_collection.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/enums/document_sequence.dart';
import '../../domain/enums/job_work_collection_enums.dart';
import '../models/job_work_collection_model.dart';
import '../services/job_work_collection_quantity_helper.dart';
import '../services/job_work_collection_status_helper.dart';
import '../services/sequence_number_service.dart';
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
    SequenceNumberService? sequenceNumberService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _jobWorkRepository =
            jobWorkRepository ?? JobWorkRepository(firestore: firestore),
        _loadRepository = loadRepository ??
            JobWorkLoadRepository(
              firestore: firestore,
              jobWorkRepository: jobWorkRepository,
            ),
        _sequenceNumberService =
            sequenceNumberService ?? SequenceNumberService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final JobWorkRepository _jobWorkRepository;
  final JobWorkLoadRepository _loadRepository;
  final SequenceNumberService _sequenceNumberService;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      trackedCollection(_firestore, 'jobWorkCollections');

  Stream<List<JobWorkCollection>> watchCollections(String factoryId) {
    return _collectionsQuery(factoryId).snapshots().map(
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

  Future<List<JobWorkCollection>> getCollections(
    String factoryId, {
    int? limit,
  }) async {
    final snapshot = await _collectionsQuery(factoryId, limit: limit).get();
    final collections = snapshot.docs
        .map(
          (doc) => JobWorkCollectionModel.fromFirestore(doc.id, doc.data()),
        )
        .map((model) => model.toEntity())
        .toList();
    collections.sort((a, b) => b.collectedAt.compareTo(a.collectedAt));
    return collections;
  }

  Query<Map<String, dynamic>> _collectionsQuery(
    String factoryId, {
    int? limit,
  }) {
    return constrainFactoryQuery(
      _collection.where('factoryId', isEqualTo: factoryId),
      limit: limit,
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
    String? receiverPhone,
    String? receiverAddress,
    String? receiverEmail,
    String? vehicleNumber,
    String? driverName,
    String? driverPhone,
    String? driverCnic,
    String? vehicleType,
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
      receiverName: _cleanString(receiverName),
      receiverPhone: _cleanString(receiverPhone),
      receiverAddress: _cleanString(receiverAddress),
      receiverEmail: _cleanString(receiverEmail),
      vehicleNumber: _cleanString(vehicleNumber),
      driverName: _cleanString(driverName),
      driverPhone: _cleanString(driverPhone),
      driverCnic: _cleanString(driverCnic),
      vehicleType: _cleanString(vehicleType),
      notes: _cleanString(notes),
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

  /// Cancels a collection record and re-syncs the load status.
  Future<void> cancelCollection(String collectionId) async {
    final docRef = _collection.doc(collectionId);
    final doc = await docRef.get();
    if (!doc.exists || doc.data() == null) return;

    final collection =
        JobWorkCollectionModel.fromFirestore(doc.id, doc.data()!).toEntity();
    await docRef.update({
      'status': JobWorkCollectionStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (collection.loadId != null && collection.loadId!.isNotEmpty) {
      await _syncLoadCollectionDerivedStatus(collection.loadId!);
    }
  }

  /// Deletes a collection record and re-syncs the load status.
  Future<void> deleteCollection(String collectionId) async {
    final docRef = _collection.doc(collectionId);
    final doc = await docRef.get();
    if (!doc.exists || doc.data() == null) return;

    final collection =
        JobWorkCollectionModel.fromFirestore(doc.id, doc.data()!).toEntity();
    await docRef.delete();

    if (collection.loadId != null && collection.loadId!.isNotEmpty) {
      await _syncLoadCollectionDerivedStatus(collection.loadId!);
    }
  }

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

    final order = await _jobWorkRepository.getJobWorkOrder(jobWorkOrderId);
    if (order == null) {
      throw const JobWorkCollectionException('Job work order not found.');
    }
    final existing = await _loadRepository.fetchLoadsForJobWork(
      factoryId: order.factoryId,
      jobWorkId: jobWorkOrderId,
    );
    if (existing.length > 1) {
      throw const JobWorkCollectionException(
        'Select a load before collecting material.',
      );
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

  Future<String> _generateCollectionNumber(String factoryId) {
    return _sequenceNumberService.allocate(
      factoryId: factoryId,
      sequence: DocumentSequence.jobWorkCollection,
    );
  }

  static String? _cleanString(String? val) {
    if (val == null) return null;
    final trimmed = val.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
