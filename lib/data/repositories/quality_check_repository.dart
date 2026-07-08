import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/production_batch.dart';
import '../../domain/entities/quality_check.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/quality_enums.dart';
import '../models/quality_check_model.dart';
import 'job_work_repository.dart';
import 'production_repository.dart';

class QualityCheckException implements Exception {
  const QualityCheckException(this.message);

  final String message;

  @override
  String toString() => message;
}

class QualityCheckRepository {
  QualityCheckRepository({
    FirebaseFirestore? firestore,
    ProductionRepository? productionRepository,
    JobWorkRepository? jobWorkRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _productionRepository =
            productionRepository ?? ProductionRepository(),
        _jobWorkRepository = jobWorkRepository ?? JobWorkRepository();

  final FirebaseFirestore _firestore;
  final ProductionRepository _productionRepository;
  final JobWorkRepository _jobWorkRepository;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('qualityChecks');

  Stream<List<QualityCheck>> watchQualityChecks(String factoryId) {
    return _collection.where('factoryId', isEqualTo: factoryId).snapshots().map(
      (snapshot) {
        final checks = snapshot.docs
            .map((doc) => QualityCheckModel.fromFirestore(doc.id, doc.data()))
            .map((model) => model.toEntity())
            .toList();
        checks.sort((a, b) => b.inspectionDate.compareTo(a.inspectionDate));
        return checks;
      },
    );
  }

  Stream<List<QualityCheck>> watchQualityChecksForReference({
    required QcReferenceType referenceType,
    required String referenceId,
  }) {
    return _collection
        .where('referenceId', isEqualTo: referenceId)
        .where('referenceType', isEqualTo: referenceType.firestoreValue)
        .snapshots()
        .map(
      (snapshot) {
        final checks = snapshot.docs
            .map((doc) => QualityCheckModel.fromFirestore(doc.id, doc.data()))
            .map((model) => model.toEntity())
            .toList();
        checks.sort((a, b) => b.inspectionDate.compareTo(a.inspectionDate));
        return checks;
      },
    );
  }

  Future<QualityCheck?> getQualityCheck(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return QualityCheckModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Stream<QualityCheck?> watchQualityCheck(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return QualityCheckModel.fromFirestore(doc.id, doc.data()!).toEntity();
    });
  }

  Future<List<ProductionBatch>> fetchEligibleProductionBatches(
    String factoryId,
  ) async {
    final batches = await _productionRepository.watchBatches(factoryId).first;
    return batches.where((batch) => batch.totalOutputSqFt > 0).toList();
  }

  Future<List<JobWorkOrder>> fetchEligibleJobWorkOrders(String factoryId) async {
    final orders = await _jobWorkRepository.watchJobWorkOrders(factoryId).first;
    return orders.where(_isJobWorkQcEligible).toList();
  }

  Future<ProductionBatch?> getProductionBatchReference(String id) =>
      _productionRepository.getBatch(id);

  Future<JobWorkOrder?> getJobWorkReference(String id) =>
      _jobWorkRepository.getJobWorkOrder(id);

  Future<bool> hasQualityChecksForReference({
    required QcReferenceType referenceType,
    required String referenceId,
  }) async {
    final snapshot = await _collection
        .where('referenceId', isEqualTo: referenceId)
        .where('referenceType', isEqualTo: referenceType.firestoreValue)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<QualityCheck> updateQualityCheck(QualityCheck check) async {
    if (check.inspectorName.trim().isEmpty) {
      throw const QualityCheckException('Inspector name is required.');
    }
    if (check.quantityInspected <= 0) {
      throw const QualityCheckException('Quantity inspected must be greater than 0.');
    }

    final gradedTotal = check.totalGradedSqFt;
    if (gradedTotal > check.quantityInspected) {
      throw const QualityCheckException(
        'Graded quantities cannot exceed quantity inspected.',
      );
    }
    if (gradedTotal <= 0) {
      throw const QualityCheckException('Enter at least one grade quantity.');
    }

    final model = QualityCheckModel.fromEntity(
      check.copyWith(updatedAt: DateTime.now()),
    );
    await _collection.doc(check.id).update(model.toFirestore());
    final updated = await getQualityCheck(check.id);
    return updated ?? model.toEntity();
  }

  Future<QualityCheck> createQualityCheck(QualityCheck check) async {
    if (check.inspectorName.trim().isEmpty) {
      throw const QualityCheckException('Inspector name is required.');
    }
    if (check.quantityInspected <= 0) {
      throw const QualityCheckException('Quantity inspected must be greater than 0.');
    }

    final gradedTotal = check.totalGradedSqFt;
    if (gradedTotal > check.quantityInspected) {
      throw const QualityCheckException(
        'Graded quantities cannot exceed quantity inspected.',
      );
    }
    if (gradedTotal <= 0) {
      throw const QualityCheckException('Enter at least one grade quantity.');
    }

    final id = check.id.isEmpty ? _uuid.v4() : check.id;
    final qcNumber = check.qcNumber.isEmpty
        ? await _generateQcNumber(check.factoryId)
        : check.qcNumber;

    final model = QualityCheckModel.fromEntity(
      check.copyWith(id: id, qcNumber: qcNumber),
    );

    await _collection.doc(id).set(model.toFirestore(isCreate: true));
    final created = await getQualityCheck(id);
    return created ?? model.toEntity();
  }

  bool _isJobWorkQcEligible(JobWorkOrder order) {
    if (order.status == JobWorkStatus.cancelled) return false;
    final output = order.output;
    return output != null && output.isRecorded;
  }

  Future<String> _generateQcNumber(String factoryId) async {
    final year = DateTime.now().year;
    final snapshot =
        await _collection.where('factoryId', isEqualTo: factoryId).get();
    final count = snapshot.docs.length + 1;
    return 'QC-$year-${count.toString().padLeft(4, '0')}';
  }
}
