import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/raw_material.dart';
import '../../domain/entities/stock_transaction.dart';
import '../../domain/enums/raw_material_enums.dart';
import '../models/raw_material_model.dart';
import '../models/stock_transaction_model.dart';
import '../services/raw_material_stock_service.dart';
import '../services/stock_correction_helper.dart';

class RawMaterialRepository {
  RawMaterialRepository({
    FirebaseFirestore? firestore,
    RawMaterialStockService? stockService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _stockService = stockService ?? RawMaterialStockService();

  final FirebaseFirestore _firestore;
  final RawMaterialStockService _stockService;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _materialsCollection =>
      _firestore.collection('rawMaterials');

  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _firestore.collection('stockTransactions');

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

  Future<RawMaterial?> getMaterialByType({
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
    return RawMaterialModel.fromFirestore(doc.id, doc.data()).toEntity();
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
    final existing = await getMaterialByType(
      factoryId: factoryId,
      materialType: materialType,
    );

    final materialId = existing?.id ?? _uuid.v4();
    final newStock = (existing?.currentStock ?? 0) + quantity;
    final newAverageCost = _stockService.calculateWeightedAverageCost(
      currentStock: existing?.currentStock ?? 0,
      currentAverageCost: existing?.averageCost ?? 0,
      incomingQuantity: quantity,
      incomingUnitCost: unitCost,
    );

    final material = RawMaterial(
      id: materialId,
      factoryId: factoryId,
      materialType: materialType,
      currentStock: newStock,
      reorderLevel: existing?.reorderLevel ?? 0,
      averageCost: newAverageCost,
      lastReceiptDate: transactionDate,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

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
    final materialModel = RawMaterialModel.fromEntity(material);
    batch.set(
      _materialsCollection.doc(materialId),
      materialModel.toFirestore(isCreate: existing == null),
      SetOptions(merge: existing != null),
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
    final existing = await getMaterialByType(
      factoryId: factoryId,
      materialType: materialType,
    );

    if (existing == null || existing.id.isEmpty) {
      throw const RawMaterialStockException('No stock record found for this material.');
    }

    _stockService.validateStockOut(
      currentStock: existing.currentStock,
      quantity: quantity,
    );

    final newStock = existing.currentStock - quantity;
    final material = existing.copyWith(currentStock: newStock);

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
    batch.update(
      _materialsCollection.doc(existing.id),
      RawMaterialModel.fromEntity(material).toFirestore(),
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

    final existing = await getMaterialByType(
      factoryId: factoryId,
      materialType: materialType,
    );

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
    final delta = movementType == StockMovementType.adjustmentIn
        ? quantity
        : -quantity;
    final newStock = (existing?.currentStock ?? 0) + delta;

    double newAverageCost = existing?.averageCost ?? 0;
    double? effectiveUnitCost;

    if (movementType == StockMovementType.adjustmentIn) {
      if ((existing?.currentStock ?? 0) <= 0 && unitCost == null) {
        throw const RawMaterialStockException(
          'Unit cost is required when adding stock to an empty material.',
        );
      }
      effectiveUnitCost = unitCost ?? existing?.averageCost ?? 0;
      newAverageCost = _stockService.calculateWeightedAverageCost(
        currentStock: existing?.currentStock ?? 0,
        currentAverageCost: existing?.averageCost ?? 0,
        incomingQuantity: quantity,
        incomingUnitCost: effectiveUnitCost,
      );
    } else {
      effectiveUnitCost = existing?.averageCost;
    }

    final material = RawMaterial(
      id: materialId,
      factoryId: factoryId,
      materialType: materialType,
      currentStock: newStock,
      reorderLevel: existing?.reorderLevel ?? 0,
      averageCost: newAverageCost,
      lastReceiptDate: movementType == StockMovementType.adjustmentIn
          ? transactionDate
          : existing?.lastReceiptDate,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

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
    final materialModel = RawMaterialModel.fromEntity(material);
    batch.set(
      _materialsCollection.doc(materialId),
      materialModel.toFirestore(isCreate: existing == null),
      SetOptions(merge: existing != null),
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
  }) async {
    final year = DateTime.now().year;
    final prefix = switch (movementType) {
      StockMovementType.stockIn => 'STK-IN',
      StockMovementType.stockOut => 'STK-OUT',
      StockMovementType.adjustmentIn => 'STK-ADJ-IN',
      StockMovementType.adjustmentOut => 'STK-ADJ-OUT',
    };
    final snapshot = await _transactionsCollection
        .where('factoryId', isEqualTo: factoryId)
        .where('movementType', isEqualTo: movementType.firestoreValue)
        .get();
    final count = snapshot.docs.length + 1;
    return '$prefix-$year-${count.toString().padLeft(4, '0')}';
  }
}
