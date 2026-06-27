import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/finished_good.dart';
import '../../domain/entities/inventory_transaction.dart';
import '../../domain/entities/production_batch.dart';
import '../../domain/enums/inventory_enums.dart';
import '../models/finished_good_model.dart';
import '../models/inventory_transaction_model.dart';
import '../services/finished_goods_stock_service.dart';

class FinishedGoodsRepository {
  FinishedGoodsRepository({
    FirebaseFirestore? firestore,
    FinishedGoodsStockService? stockService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _stockService = stockService ?? FinishedGoodsStockService();

  final FirebaseFirestore _firestore;
  final FinishedGoodsStockService _stockService;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _goodsCollection =>
      _firestore.collection('finishedGoods');

  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _firestore.collection('inventoryTransactions');

  Stream<List<FinishedGood>> watchFinishedGoods(String factoryId) {
    return _goodsCollection
        .where('factoryId', isEqualTo: factoryId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map(
                (doc) => FinishedGoodModel.fromFirestore(
                  doc.id,
                  doc.data(),
                ).toEntity(),
              )
              .toList();
          items.sort((a, b) {
            final product = a.productType.label.compareTo(b.productType.label);
            if (product != 0) return product;
            final variety = a.marbleVariety.compareTo(b.marbleVariety);
            if (variety != 0) return variety;
            return a.grade.index.compareTo(b.grade.index);
          });
          return items;
        });
  }

  Stream<FinishedGood?> watchFinishedGood(String id) {
    return _goodsCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return FinishedGoodModel.fromFirestore(doc.id, doc.data()!).toEntity();
    });
  }

  Stream<List<InventoryTransaction>> watchTransactions({
    required String factoryId,
    required String finishedGoodId,
  }) {
    return _transactionsCollection
        .where('factoryId', isEqualTo: factoryId)
        .where('finishedGoodId', isEqualTo: finishedGoodId)
        .snapshots()
        .map((snapshot) {
          final transactions = snapshot.docs
              .map(
                (doc) => InventoryTransactionModel.fromFirestore(
                  doc.id,
                  doc.data(),
                ).toEntity(),
              )
              .toList();
          transactions.sort(
            (a, b) => b.transactionDate.compareTo(a.transactionDate),
          );
          return transactions;
        });
  }

  Future<FinishedGood?> getBySkuKey({
    required String factoryId,
    required String skuKey,
  }) async {
    final snapshot = await _goodsCollection
        .where('factoryId', isEqualTo: factoryId)
        .where('skuKey', isEqualTo: skuKey)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return FinishedGoodModel.fromFirestore(doc.id, doc.data()).toEntity();
  }

  Future<void> receiveFromProductionBatch({
    required WriteBatch writeBatch,
    required ProductionBatch batch,
  }) async {
    final totalOutput = batch.totalOutputSqFt;
    if (totalOutput <= 0) return;

    final unitCostPerSqFt = (batch.materialCost ?? 0) / totalOutput;
    final receipts = <({FinishedGoodGrade grade, double quantity})>[
      (grade: FinishedGoodGrade.gradeA, quantity: batch.gradeASqFt),
      (grade: FinishedGoodGrade.gradeB, quantity: batch.gradeBSqFt),
      (grade: FinishedGoodGrade.gradeC, quantity: batch.gradeCSqFt),
      (grade: FinishedGoodGrade.reject, quantity: batch.rejectSqFt),
    ];

    final activeReceipts =
        receipts.where((receipt) => receipt.quantity > 0).toList();
    if (activeReceipts.isEmpty) return;

    final baseCount = await _transactionCount(
      factoryId: batch.factoryId,
      movementType: InventoryMovementType.productionIn,
    );
    var transactionOffset = 0;

    for (final receipt in activeReceipts) {

      final skuKey = buildFinishedGoodSkuKey(
        productType: batch.productType,
        marbleVariety: batch.marbleVariety,
        grade: receipt.grade,
        size: batch.size,
        thickness: batch.thickness,
      );

      final existing = await getBySkuKey(
        factoryId: batch.factoryId,
        skuKey: skuKey,
      );

      final itemId = existing?.id ?? _uuid.v4();
      final newQuantity = (existing?.currentQuantity ?? 0) + receipt.quantity;
      final newAverageCost = _stockService.calculateWeightedAverageCost(
        currentQuantity: existing?.currentQuantity ?? 0,
        currentAverageCost: existing?.averageCost ?? 0,
        incomingQuantity: receipt.quantity,
        incomingUnitCost: unitCostPerSqFt,
      );

      final item = FinishedGood(
        id: itemId,
        factoryId: batch.factoryId,
        skuKey: skuKey,
        productType: batch.productType,
        marbleVariety: batch.marbleVariety,
        size: batch.size,
        thickness: batch.thickness,
        grade: receipt.grade,
        currentQuantity: newQuantity,
        reorderLevel: existing?.reorderLevel ?? 0,
        averageCost: newAverageCost,
        location: existing?.location,
        lastReceiptDate: batch.productionDate,
        createdAt: existing?.createdAt ?? DateTime.now(),
      );

      final transactionId = _uuid.v4();
      final transactionNumber = _formatTransactionNumber(
        movementType: InventoryMovementType.productionIn,
        sequence: baseCount + transactionOffset,
      );
      transactionOffset++;

      final transaction = InventoryTransaction(
        id: transactionId,
        transactionNumber: transactionNumber,
        factoryId: batch.factoryId,
        finishedGoodId: itemId,
        movementType: InventoryMovementType.productionIn,
        quantity: receipt.quantity,
        unitCost: unitCostPerSqFt,
        totalCost: unitCostPerSqFt * receipt.quantity,
        transactionDate: batch.productionDate,
        productionBatchId: batch.id,
        productionBatchNumber: batch.batchNumber,
        createdAt: DateTime.now(),
      );

      writeBatch.set(
        _goodsCollection.doc(itemId),
        FinishedGoodModel.fromEntity(item).toFirestore(isCreate: existing == null),
        SetOptions(merge: existing != null),
      );
      writeBatch.set(
        _transactionsCollection.doc(transactionId),
        InventoryTransactionModel.fromEntity(transaction).toFirestore(
          isCreate: true,
        ),
      );
    }
  }

  Future<void> updateReorderLevel({
    required String finishedGoodId,
    required double reorderLevel,
  }) async {
    await _goodsCollection.doc(finishedGoodId).update({
      'reorderLevel': reorderLevel,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateLocation({
    required String finishedGoodId,
    required String? location,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (location == null || location.trim().isEmpty) {
      updates['location'] = FieldValue.delete();
    } else {
      updates['location'] = location.trim();
    }
    await _goodsCollection.doc(finishedGoodId).update(updates);
  }

  Future<InventoryTransaction> recordAdjustment({
    required String factoryId,
    required String finishedGoodId,
    required InventoryMovementType movementType,
    required double quantity,
    required DateTime transactionDate,
    required String reason,
    String? notes,
    double? unitCost,
  }) async {
    if (movementType == InventoryMovementType.productionIn) {
      throw const FinishedGoodsStockException('Invalid adjustment type.');
    }
    if (reason.trim().isEmpty) {
      throw const FinishedGoodsStockException('Reason is required.');
    }

    final doc = await _goodsCollection.doc(finishedGoodId).get();
    if (!doc.exists || doc.data() == null) {
      throw const FinishedGoodsStockException('Stock item not found.');
    }

    final existing =
        FinishedGoodModel.fromFirestore(doc.id, doc.data()!).toEntity();

    if (movementType == InventoryMovementType.adjustmentOut) {
      _stockService.validateStockOut(
        currentQuantity: existing.currentQuantity,
        quantity: quantity,
      );
    }

    final delta = movementType == InventoryMovementType.adjustmentIn
        ? quantity
        : -quantity;
    final newQuantity = existing.currentQuantity + delta;

    final double effectiveUnitCost;
    double newAverageCost = existing.averageCost;

    if (movementType == InventoryMovementType.adjustmentIn) {
      if (existing.currentQuantity <= 0 && unitCost == null) {
        throw const FinishedGoodsStockException(
          'Unit cost is required when adding stock to an empty SKU.',
        );
      }

      effectiveUnitCost = unitCost ?? existing.averageCost;
      newAverageCost = _stockService.calculateWeightedAverageCost(
        currentQuantity: existing.currentQuantity,
        currentAverageCost: existing.averageCost,
        incomingQuantity: quantity,
        incomingUnitCost: effectiveUnitCost,
      );
    } else {
      effectiveUnitCost = existing.averageCost;
    }

    final item = existing.copyWith(
      currentQuantity: newQuantity,
      averageCost: newAverageCost,
      lastReceiptDate: movementType == InventoryMovementType.adjustmentIn
          ? transactionDate
          : existing.lastReceiptDate,
    );

    final transactionId = _uuid.v4();
    final transactionNumber = await _generateTransactionNumber(
      factoryId: factoryId,
      movementType: movementType,
    );

    final transaction = InventoryTransaction(
      id: transactionId,
      transactionNumber: transactionNumber,
      factoryId: factoryId,
      finishedGoodId: finishedGoodId,
      movementType: movementType,
      quantity: quantity,
      unitCost: effectiveUnitCost,
      totalCost: effectiveUnitCost * quantity,
      transactionDate: transactionDate,
      reason: reason.trim(),
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      createdAt: DateTime.now(),
    );

    final writeBatch = _firestore.batch();
    writeBatch.update(
      _goodsCollection.doc(finishedGoodId),
      FinishedGoodModel.fromEntity(item).toFirestore(),
    );
    writeBatch.set(
      _transactionsCollection.doc(transactionId),
      InventoryTransactionModel.fromEntity(transaction).toFirestore(
        isCreate: true,
      ),
    );
    await writeBatch.commit();

    return transaction;
  }

  Future<String> _generateTransactionNumber({
    required String factoryId,
    required InventoryMovementType movementType,
  }) async {
    final sequence = await _transactionCount(
      factoryId: factoryId,
      movementType: movementType,
    );
    return _formatTransactionNumber(
      movementType: movementType,
      sequence: sequence,
    );
  }

  Future<int> _transactionCount({
    required String factoryId,
    required InventoryMovementType movementType,
  }) async {
    final snapshot = await _transactionsCollection
        .where('factoryId', isEqualTo: factoryId)
        .where('movementType', isEqualTo: movementType.firestoreValue)
        .get();
    return snapshot.docs.length + 1;
  }

  String _formatTransactionNumber({
    required InventoryMovementType movementType,
    required int sequence,
  }) {
    final year = DateTime.now().year;
    final prefix = switch (movementType) {
      InventoryMovementType.productionIn => 'INV-IN',
      InventoryMovementType.adjustmentIn => 'INV-ADJ-IN',
      InventoryMovementType.adjustmentOut => 'INV-ADJ-OUT',
    };
    return '$prefix-$year-${sequence.toString().padLeft(4, '0')}';
  }
}
