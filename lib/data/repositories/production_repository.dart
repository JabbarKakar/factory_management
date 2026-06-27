import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/production_batch.dart';
import '../../domain/enums/production_enums.dart';
import '../../domain/enums/raw_material_enums.dart';
import '../models/production_batch_model.dart';
import '../models/raw_material_model.dart';
import '../models/stock_transaction_model.dart';
import '../repositories/finished_goods_repository.dart';
import '../services/raw_material_stock_service.dart';

class ProductionBatchException implements Exception {
  const ProductionBatchException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProductionRepository {
  ProductionRepository({
    FirebaseFirestore? firestore,
    RawMaterialStockService? stockService,
    FinishedGoodsRepository? finishedGoodsRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _stockService = stockService ?? RawMaterialStockService(),
        _finishedGoodsRepository = finishedGoodsRepository;

  final FirebaseFirestore _firestore;
  final RawMaterialStockService _stockService;
  final FinishedGoodsRepository? _finishedGoodsRepository;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _batchesCollection =>
      _firestore.collection('productionBatches');

  CollectionReference<Map<String, dynamic>> get _materialsCollection =>
      _firestore.collection('rawMaterials');

  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _firestore.collection('stockTransactions');

  Stream<List<ProductionBatch>> watchBatches(String factoryId) {
    return _batchesCollection
        .where('factoryId', isEqualTo: factoryId)
        .snapshots()
        .map((snapshot) {
          final batches = snapshot.docs
              .map(
                (doc) => ProductionBatchModel.fromFirestore(
                  doc.id,
                  doc.data(),
                ).toEntity(),
              )
              .toList();
          batches.sort(
            (a, b) => b.productionDate.compareTo(a.productionDate),
          );
          return batches;
        });
  }

  Stream<ProductionBatch?> watchBatch(String id) {
    return _batchesCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ProductionBatchModel.fromFirestore(doc.id, doc.data()!).toEntity();
    });
  }

  Future<ProductionBatch?> getBatch(String id) async {
    final doc = await _batchesCollection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return ProductionBatchModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Future<ProductionBatch> createBatch({
    required String factoryId,
    required DateTime productionDate,
    required ProductionShift shift,
    required RawMaterialType rawMaterialType,
    required double materialConsumed,
    required ProductionProductType productType,
    required String marbleVariety,
    required double gradeASqFt,
    required double gradeBSqFt,
    required double gradeCSqFt,
    required double rejectSqFt,
    String? thickness,
    String? size,
    double? wasteTons,
    String? supervisorName,
    String? notes,
  }) async {
    if (materialConsumed <= 0) {
      throw const ProductionBatchException(
        'Material consumed must be greater than zero.',
      );
    }

    final totalOutput = gradeASqFt + gradeBSqFt + gradeCSqFt + rejectSqFt;
    if (totalOutput <= 0) {
      throw const ProductionBatchException(
        'Record at least some output (Grade A/B/C or Reject).',
      );
    }

    if (marbleVariety.trim().isEmpty) {
      throw const ProductionBatchException('Marble variety is required.');
    }

    final materialSnapshot = await _materialsCollection
        .where('factoryId', isEqualTo: factoryId)
        .where('materialType', isEqualTo: rawMaterialType.firestoreValue)
        .limit(1)
        .get();

    if (materialSnapshot.docs.isEmpty) {
      throw ProductionBatchException(
        'No stock record found for ${rawMaterialType.label}.',
      );
    }

    final materialDoc = materialSnapshot.docs.first;
    final material = RawMaterialModel.fromFirestore(
      materialDoc.id,
      materialDoc.data(),
    ).toEntity();

    _stockService.validateStockOut(
      currentStock: material.currentStock,
      quantity: materialConsumed,
    );

    final batchNumber = await _generateBatchNumber(factoryId: factoryId);
    final batchId = _uuid.v4();
    final transactionId = _uuid.v4();
    final transactionNumber = await _generateStockOutNumber(factoryId);
    final materialCost = material.averageCost * materialConsumed;
    final updatedMaterial = material.copyWith(
      currentStock: material.currentStock - materialConsumed,
    );

    final batch = ProductionBatch(
      id: batchId,
      batchNumber: batchNumber,
      factoryId: factoryId,
      productionDate: productionDate,
      shift: shift,
      rawMaterialType: rawMaterialType,
      rawMaterialId: material.id,
      materialConsumed: materialConsumed,
      productType: productType,
      marbleVariety: marbleVariety.trim(),
      thickness: thickness?.trim().isEmpty ?? true ? null : thickness?.trim(),
      size: size?.trim().isEmpty ?? true ? null : size?.trim(),
      gradeASqFt: gradeASqFt,
      gradeBSqFt: gradeBSqFt,
      gradeCSqFt: gradeCSqFt,
      rejectSqFt: rejectSqFt,
      wasteTons: wasteTons,
      supervisorName:
          supervisorName?.trim().isEmpty ?? true ? null : supervisorName?.trim(),
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      stockTransactionId: transactionId,
      materialCost: materialCost,
      createdAt: DateTime.now(),
    );

    final transaction = StockTransactionModel(
      id: transactionId,
      transactionNumber: transactionNumber,
      factoryId: factoryId,
      rawMaterialId: material.id,
      materialType: rawMaterialType,
      movementType: StockMovementType.stockOut,
      quantity: materialConsumed,
      transactionDate: productionDate,
      notes: 'Production batch $batchNumber',
      createdAt: DateTime.now(),
    );

    final writeBatch = _firestore.batch();
    writeBatch.update(
      _materialsCollection.doc(material.id),
      RawMaterialModel.fromEntity(updatedMaterial).toFirestore(),
    );
    writeBatch.set(
      _transactionsCollection.doc(transactionId),
      transaction.toFirestore(isCreate: true),
    );
    writeBatch.set(
      _batchesCollection.doc(batchId),
      ProductionBatchModel.fromEntity(batch).toFirestore(isCreate: true),
    );

    if (_finishedGoodsRepository != null) {
      await _finishedGoodsRepository.receiveFromProductionBatch(
        writeBatch: writeBatch,
        batch: batch,
      );
    }

    await writeBatch.commit();

    return batch;
  }

  Future<String> _generateBatchNumber({required String factoryId}) async {
    final year = DateTime.now().year;
    final snapshot = await _batchesCollection
        .where('factoryId', isEqualTo: factoryId)
        .get();
    final count = snapshot.docs.length + 1;
    return 'PRD-$year-${count.toString().padLeft(4, '0')}';
  }

  Future<String> _generateStockOutNumber(String factoryId) async {
    final year = DateTime.now().year;
    final snapshot = await _transactionsCollection
        .where('factoryId', isEqualTo: factoryId)
        .where('movementType', isEqualTo: StockMovementType.stockOut.firestoreValue)
        .get();
    final count = snapshot.docs.length + 1;
    return 'STK-OUT-$year-${count.toString().padLeft(4, '0')}';
  }
}
