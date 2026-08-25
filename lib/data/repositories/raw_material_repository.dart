import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/observability/tracked_firestore.dart';
import '../../domain/entities/raw_material.dart';
import '../../domain/entities/stock_transaction.dart';
import '../../domain/enums/document_sequence.dart';
import '../../domain/enums/raw_material_enums.dart';
import '../models/raw_material_model.dart';
import '../models/stock_transaction_model.dart';
import '../services/raw_material_stock_service.dart';
import '../services/sequence_number_service.dart';
import '../services/stock_correction_helper.dart';
import '../services/stock_movement_payload.dart';

class RawMaterialRepository {
  RawMaterialRepository({
    FirebaseFirestore? firestore,
    RawMaterialStockService? stockService,
    SequenceNumberService? sequenceNumberService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _stockService = stockService ?? RawMaterialStockService(),
        _sequenceNumberService =
            sequenceNumberService ?? SequenceNumberService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final RawMaterialStockService _stockService;
  final SequenceNumberService _sequenceNumberService;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _materialsCollection =>
      trackedCollection(_firestore, 'rawMaterials');

  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      trackedCollection(_firestore, 'stockTransactions');

  Stream<List<RawMaterial>> watchMaterials(String factoryId) {
    return _materialsCollection
        .where('factoryId', isEqualTo: factoryId)
        .snapshots()
        .map((snapshot) {
          final materials = snapshot.docs
              .map((doc) =>
                  RawMaterialModel.fromFirestore(doc.id, doc.data()).toEntity())
              .toList();
          materials.sort(
            (a, b) => a.materialType.label.compareTo(b.materialType.label),
          );
          return materials;
        });
  }

  Stream<RawMaterial?> watchMaterial(String id) {
    return _materialsCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return RawMaterialModel.fromFirestore(doc.id, doc.data()!).toEntity();
    });
  }

  Stream<List<StockTransaction>> watchTransactions(String factoryId) {
    return _transactionsCollection
        .where('factoryId', isEqualTo: factoryId)
        .snapshots()
        .map((snapshot) {
          final transactions = snapshot.docs
              .map((doc) => StockTransactionModel.fromFirestore(
                    doc.id,
                    doc.data(),
                  ).toEntity())
              .toList();
          transactions.sort(
            (a, b) => b.transactionDate.compareTo(a.transactionDate),
          );
          return transactions;
        });
  }

  Future<List<StockTransaction>> getTransactions(String factoryId) async {
    final snapshot = await _transactionsCollection
        .where('factoryId', isEqualTo: factoryId)
        .get();
    final transactions = snapshot.docs
        .map((doc) => StockTransactionModel.fromFirestore(
              doc.id,
              doc.data(),
            ).toEntity())
        .toList();
    transactions.sort(
      (a, b) => b.transactionDate.compareTo(a.transactionDate),
    );
    return transactions;
  }

  Future<RawMaterial?> getMaterialByType({
    required String factoryId,
    required RawMaterialType materialType,
  }) async {
    final model = await _findMaterialModel(
      factoryId: factoryId,
      materialType: materialType,
    );
    return model?.toEntity();
  }

  /// Same lookup as [getMaterialByType], but keeps the model so write paths can
  /// see whether the document already stores its totals.
  Future<RawMaterialModel?> _findMaterialModel({
    required String factoryId,
    required RawMaterialType materialType,
  }) async {
    final snapshot = await _materialsCollection
        .where('factoryId', isEqualTo: factoryId)
        .where('materialType', isEqualTo: materialType.firestoreValue)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return RawMaterialModel.fromFirestore(doc.id, doc.data());
  }

  Future<StockTransaction?> getTransaction(String id) async {
    final doc = await _transactionsCollection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return StockTransactionModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Future<void> updateReorderLevel({
    required String materialId,
    required double reorderLevel,
  }) async {
    await _materialsCollection.doc(materialId).update({
      'reorderLevel': reorderLevel,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<StockTransaction> recordStockIn({
    required String factoryId,
    required RawMaterialType materialType,
    required double quantity,
    required double unitCost,
    required DateTime transactionDate,
    String? supplierId,
    String? referenceNumber,
    String? notes,
  }) async {
    if (quantity <= 0) {
      throw const RawMaterialStockException('Quantity must be greater than zero.');
    }
    if (unitCost < 0) {
      throw const RawMaterialStockException('Unit cost cannot be negative.');
    }

    final totalCost = quantity * unitCost;
    // Locating read only: it tells us which document to write and gives the cost
    // basis for the mirrors. The new stock level is computed by the server from
    // the increments below, so an overlapping movement cannot be lost.
    final existingModel = await _findMaterialModel(
      factoryId: factoryId,
      materialType: materialType,
    );
    final existing = existingModel?.toEntity();

    final materialId = existing?.id ?? _uuid.v4();

    final transactionId = _uuid.v4();
    final transactionNumber = await _generateTransactionNumber(
      factoryId: factoryId,
      movementType: StockMovementType.stockIn,
    );

    final transaction = StockTransaction(
      id: transactionId,
      transactionNumber: transactionNumber,
      factoryId: factoryId,
      rawMaterialId: materialId,
      materialType: materialType,
      movementType: StockMovementType.stockIn,
      quantity: quantity,
      unitCost: unitCost,
      totalCost: totalCost,
      transactionDate: transactionDate,
      supplierId: supplierId,
      referenceNumber: referenceNumber,
      notes: notes,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(
      _materialsCollection.doc(materialId),
      buildStockMovementPayload(
        mirror: StockQuantityMirror.rawMaterial,
        quantityDelta: quantity,
        valueDelta: totalCost,
        projectedQuantity: (existing?.totalQuantity ?? 0) + quantity,
        projectedUnitCost: _stockService.calculateWeightedAverageCost(
          currentStock: existing?.currentStock ?? 0,
          currentAverageCost: existing?.averageCost ?? 0,
          incomingQuantity: quantity,
          incomingUnitCost: unitCost,
        ),
        identity: {
          'factoryId': factoryId,
          'materialType': materialType.firestoreValue,
        },
        lastReceiptDate: transactionDate,
        isCreate: existing == null,
        replaceTotals: existingModel?.hasStoredTotals == false,
      ),
      SetOptions(merge: true),
    );
    batch.set(
      _transactionsCollection.doc(transactionId),
      StockTransactionModel.fromEntity(transaction).toFirestore(isCreate: true),
    );
    await batch.commit();

    return transaction;
  }

  Future<StockTransaction> recordStockOut({
    required String factoryId,
    required RawMaterialType materialType,
    required double quantity,
    required DateTime transactionDate,
    String? notes,
  }) async {
    final existingModel = await _findMaterialModel(
      factoryId: factoryId,
      materialType: materialType,
    );
    final existing = existingModel?.toEntity();

    if (existing == null || existing.id.isEmpty) {
      throw const RawMaterialStockException('No stock record found for this material.');
    }

    _stockService.validateStockOut(
      currentStock: existing.currentStock,
      quantity: quantity,
    );

    final transactionId = _uuid.v4();
    final transactionNumber = await _generateTransactionNumber(
      factoryId: factoryId,
      movementType: StockMovementType.stockOut,
    );

    final transaction = StockTransaction(
      id: transactionId,
      transactionNumber: transactionNumber,
      factoryId: factoryId,
      rawMaterialId: existing.id,
      materialType: materialType,
      movementType: StockMovementType.stockOut,
      quantity: quantity,
      transactionDate: transactionDate,
      notes: notes,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(
      _materialsCollection.doc(existing.id),
      buildStockMovementPayload(
        mirror: StockQuantityMirror.rawMaterial,
        quantityDelta: -quantity,
        // Issuing at the running average leaves the average untouched, which is
        // what the pre-S38 behaviour did by only lowering the quantity.
        valueDelta: -(quantity * existing.averageCost),
        projectedQuantity: existing.totalQuantity - quantity,
        projectedUnitCost: existing.averageCost,
        identity: {
          'factoryId': factoryId,
          'materialType': materialType.firestoreValue,
        },
        replaceTotals: existingModel?.hasStoredTotals == false,
      ),
      SetOptions(merge: true),
    );
    batch.set(
      _transactionsCollection.doc(transactionId),
      StockTransactionModel.fromEntity(transaction).toFirestore(isCreate: true),
    );
    await batch.commit();

    return transaction;
  }

  Future<StockTransaction> recordAdjustment({
    required String factoryId,
    required RawMaterialType materialType,
    required StockMovementType movementType,
    required double quantity,
    required DateTime transactionDate,
    required String reason,
    String? notes,
    double? unitCost,
    String? referenceNumber,
  }) async {
    if (movementType != StockMovementType.adjustmentIn &&
        movementType != StockMovementType.adjustmentOut) {
      throw const RawMaterialStockException('Invalid adjustment type.');
    }
    if (reason.trim().isEmpty) {
      throw const RawMaterialStockException('Reason is required.');
    }

    final existingModel = await _findMaterialModel(
      factoryId: factoryId,
      materialType: materialType,
    );
    final existing = existingModel?.toEntity();

    if (movementType == StockMovementType.adjustmentOut) {
      if (existing == null || existing.id.isEmpty) {
        throw const RawMaterialStockException(
          'No stock record found for this material.',
        );
      }
      _stockService.validateStockOut(
        currentStock: existing.currentStock,
        quantity: quantity,
      );
    }

    final materialId = existing?.id ?? _uuid.v4();
    final isAdjustmentIn = movementType == StockMovementType.adjustmentIn;
    final quantityDelta = isAdjustmentIn ? quantity : -quantity;

    double projectedUnitCost = existing?.averageCost ?? 0;
    double? effectiveUnitCost;

    if (isAdjustmentIn) {
      if ((existing?.currentStock ?? 0) <= 0 && unitCost == null) {
        throw const RawMaterialStockException(
          'Unit cost is required when adding stock to an empty material.',
        );
      }
      effectiveUnitCost = unitCost ?? existing?.averageCost ?? 0;
      projectedUnitCost = _stockService.calculateWeightedAverageCost(
        currentStock: existing?.currentStock ?? 0,
        currentAverageCost: existing?.averageCost ?? 0,
        incomingQuantity: quantity,
        incomingUnitCost: effectiveUnitCost,
      );
    } else {
      effectiveUnitCost = existing?.averageCost;
    }

    final valueDelta = isAdjustmentIn
        ? quantity * (effectiveUnitCost ?? 0)
        : -(quantity * (existing?.averageCost ?? 0));

    final transactionId = _uuid.v4();
    final transactionNumber = await _generateTransactionNumber(
      factoryId: factoryId,
      movementType: movementType,
    );

    final transaction = StockTransaction(
      id: transactionId,
      transactionNumber: transactionNumber,
      factoryId: factoryId,
      rawMaterialId: materialId,
      materialType: materialType,
      movementType: movementType,
      quantity: quantity,
      unitCost: effectiveUnitCost,
      totalCost: effectiveUnitCost == null ? null : effectiveUnitCost * quantity,
      transactionDate: transactionDate,
      referenceNumber: referenceNumber,
      notes: [
        reason.trim(),
        if (notes != null && notes.trim().isNotEmpty) notes.trim(),
      ].join('\n'),
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(
      _materialsCollection.doc(materialId),
      buildStockMovementPayload(
        mirror: StockQuantityMirror.rawMaterial,
        quantityDelta: quantityDelta,
        valueDelta: valueDelta,
        projectedQuantity: (existing?.totalQuantity ?? 0) + quantityDelta,
        projectedUnitCost: projectedUnitCost,
        identity: {
          'factoryId': factoryId,
          'materialType': materialType.firestoreValue,
        },
        lastReceiptDate: isAdjustmentIn ? transactionDate : null,
        isCreate: existing == null,
        replaceTotals: existingModel?.hasStoredTotals == false,
      ),
      SetOptions(merge: true),
    );
    batch.set(
      _transactionsCollection.doc(transactionId),
      StockTransactionModel.fromEntity(transaction).toFirestore(isCreate: true),
    );
    await batch.commit();

    return transaction;
  }

  Future<StockTransaction> recordCorrection({
    required StockTransaction original,
    required DateTime transactionDate,
    required String reason,
    String? notes,
  }) async {
    if (!StockCorrectionHelper.canCorrectStockTransaction(original)) {
      throw const RawMaterialStockException(
        'Production-linked entries must be corrected from the production batch.',
      );
    }

    final inverse =
        StockCorrectionHelper.inverseStockMovement(original.movementType);
    final correctionReason =
        '${StockCorrectionHelper.correctionReasonPrefix(original.transactionNumber)}'
        '${reason.trim().isEmpty ? '' : ' — ${reason.trim()}'}';

    return recordAdjustment(
      factoryId: original.factoryId,
      materialType: original.materialType,
      movementType: inverse,
      quantity: original.quantity,
      transactionDate: transactionDate,
      reason: correctionReason,
      notes: notes,
      unitCost: original.unitCost,
      referenceNumber: original.transactionNumber,
    );
  }

  Future<String> _generateTransactionNumber({
    required String factoryId,
    required StockMovementType movementType,
  }) {
    return _sequenceNumberService.allocate(
      factoryId: factoryId,
      sequence: movementType.documentSequence,
    );
  }
}
