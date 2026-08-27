import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/observability/tracked_firestore.dart';
import '../../domain/entities/finished_good.dart';
import '../../domain/entities/inventory_transaction.dart';
import '../../domain/entities/production_batch.dart';
import '../../domain/enums/document_sequence.dart';
import '../../domain/enums/inventory_enums.dart';
import '../models/finished_good_model.dart';
import '../models/inventory_transaction_model.dart';
import '../services/finished_goods_stock_service.dart';
import '../services/sequence_number_service.dart';
import '../services/stock_correction_helper.dart';
import '../services/stock_movement_payload.dart';

class FinishedGoodsRepository {
  FinishedGoodsRepository({
    FirebaseFirestore? firestore,
    FinishedGoodsStockService? stockService,
    SequenceNumberService? sequenceNumberService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _stockService = stockService ?? FinishedGoodsStockService(),
        _sequenceNumberService =
            sequenceNumberService ?? SequenceNumberService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final FinishedGoodsStockService _stockService;
  final SequenceNumberService _sequenceNumberService;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _goodsCollection =>
      trackedCollection(_firestore, 'finishedGoods');

  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      trackedCollection(_firestore, 'inventoryTransactions');

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

  Future<List<FinishedGood>> getFinishedGoods(String factoryId) async {
    final snapshot =
        await _goodsCollection.where('factoryId', isEqualTo: factoryId).get();
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
    final model = await _findBySkuKey(factoryId: factoryId, skuKey: skuKey);
    return model?.toEntity();
  }

  /// Same lookup as [getBySkuKey], but keeps the model so write paths can see
  /// whether the document already stores its totals.
  Future<FinishedGoodModel?> _findBySkuKey({
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
    return FinishedGoodModel.fromFirestore(doc.id, doc.data());
  }

  Future<InventoryTransaction?> getTransaction(String id) async {
    final doc = await _transactionsCollection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return InventoryTransactionModel.fromFirestore(
      doc.id,
      doc.data()!,
    ).toEntity();
  }

  Future<void> reverseProductionBatchReceipts({
    required WriteBatch writeBatch,
    required String productionBatchId,
  }) async {
    final snapshot = await _transactionsCollection
        .where('productionBatchId', isEqualTo: productionBatchId)
        .get();

    for (final doc in snapshot.docs) {
      final transaction = InventoryTransactionModel.fromFirestore(
        doc.id,
        doc.data(),
      ).toEntity();

      final goodDoc = await _goodsCollection.doc(transaction.finishedGoodId).get();
      if (!goodDoc.exists || goodDoc.data() == null) {
        writeBatch.delete(doc.reference);
        continue;
      }

      final goodModel = FinishedGoodModel.fromFirestore(
        goodDoc.id,
        goodDoc.data()!,
      );
      final good = goodModel.toEntity();
      final newQuantity = good.totalQuantity - transaction.quantity;
      if (newQuantity < -0.001) {
        throw FinishedGoodsStockException(
          'Cannot update batch: ${good.displaySubtitle} stock was already used '
          '(${good.currentQuantity.toStringAsFixed(2)} sq. ft available).',
        );
      }

      // Back the receipt out at the cost it came in at, so the SKU's running
      // average returns to what it was before this batch.
      final reversedValue = transaction.totalCost ??
          transaction.quantity * (transaction.unitCost ?? 0);
      final projectedValue = good.totalValue - reversedValue;

      // The SKU document is decremented rather than deleted when it empties: a
      // delete based on this read would discard stock another device received in
      // the meantime, and an empty SKU is already a normal state elsewhere.
      writeBatch.set(
        goodDoc.reference,
        buildStockMovementPayload(
          mirror: StockQuantityMirror.finishedGood,
          quantityDelta: -transaction.quantity,
          valueDelta: -reversedValue,
          projectedQuantity: newQuantity,
          projectedUnitCost: newQuantity > 0.001
              ? projectedValue / newQuantity
              : good.averageCost,
          replaceTotals: !goodModel.hasStoredTotals,
        ),
        SetOptions(merge: true),
      );

      writeBatch.delete(doc.reference);
    }
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

    for (final receipt in activeReceipts) {

      final skuKey = buildFinishedGoodSkuKey(
        productType: batch.productType,
        marbleVariety: batch.marbleVariety,
        grade: receipt.grade,
        size: batch.size,
        thickness: batch.thickness,
      );

      final existingModel = await _findBySkuKey(
        factoryId: batch.factoryId,
        skuKey: skuKey,
      );
      final existing = existingModel?.toEntity();

      final itemId = existing?.id ?? _uuid.v4();

      final transactionId = _uuid.v4();
      final transactionNumber = await _generateTransactionNumber(
        factoryId: batch.factoryId,
        movementType: InventoryMovementType.productionIn,
      );

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
        buildStockMovementPayload(
          mirror: StockQuantityMirror.finishedGood,
          quantityDelta: receipt.quantity,
          valueDelta: unitCostPerSqFt * receipt.quantity,
          projectedQuantity: (existing?.totalQuantity ?? 0) + receipt.quantity,
          projectedUnitCost: _stockService.calculateWeightedAverageCost(
            currentQuantity: existing?.currentQuantity ?? 0,
            currentAverageCost: existing?.averageCost ?? 0,
            incomingQuantity: receipt.quantity,
            incomingUnitCost: unitCostPerSqFt,
          ),
          identity: {
            'factoryId': batch.factoryId,
            'skuKey': skuKey,
            'productType': batch.productType.firestoreValue,
            'marbleVariety': batch.marbleVariety,
            'grade': receipt.grade.firestoreValue,
            if (batch.size != null && batch.size!.isNotEmpty)
              'size': batch.size,
            if (batch.thickness != null && batch.thickness!.isNotEmpty)
              'thickness': batch.thickness,
          },
          lastReceiptDate: batch.productionDate,
          isCreate: existing == null,
          replaceTotals: existingModel?.hasStoredTotals == false,
        ),
        SetOptions(merge: true),
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

    final existingModel = FinishedGoodModel.fromFirestore(doc.id, doc.data()!);
    final existing = existingModel.toEntity();

    if (movementType == InventoryMovementType.adjustmentOut) {
      _stockService.validateStockOut(
        currentQuantity: existing.currentQuantity,
        quantity: quantity,
      );
    }

    final isAdjustmentIn = movementType == InventoryMovementType.adjustmentIn;
    final quantityDelta = isAdjustmentIn ? quantity : -quantity;

    final double effectiveUnitCost;
    double projectedUnitCost = existing.averageCost;

    if (isAdjustmentIn) {
      if (existing.currentQuantity <= 0 && unitCost == null) {
        throw const FinishedGoodsStockException(
          'Unit cost is required when adding stock to an empty SKU.',
        );
      }

      effectiveUnitCost = unitCost ?? existing.averageCost;
      projectedUnitCost = _stockService.calculateWeightedAverageCost(
        currentQuantity: existing.currentQuantity,
        currentAverageCost: existing.averageCost,
        incomingQuantity: quantity,
        incomingUnitCost: effectiveUnitCost,
      );
    } else {
      effectiveUnitCost = existing.averageCost;
    }

    final valueDelta = quantity * effectiveUnitCost * (isAdjustmentIn ? 1 : -1);

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
    writeBatch.set(
      _goodsCollection.doc(finishedGoodId),
      buildStockMovementPayload(
        mirror: StockQuantityMirror.finishedGood,
        quantityDelta: quantityDelta,
        valueDelta: valueDelta,
        projectedQuantity: existing.totalQuantity + quantityDelta,
        projectedUnitCost: projectedUnitCost,
        lastReceiptDate: isAdjustmentIn ? transactionDate : null,
        replaceTotals: !existingModel.hasStoredTotals,
      ),
      SetOptions(merge: true),
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

  Future<InventoryTransaction> recordCorrection({
    required InventoryTransaction original,
    required DateTime transactionDate,
    required String reason,
    String? notes,
  }) async {
    if (!StockCorrectionHelper.canCorrectInventoryTransaction(original)) {
      throw const FinishedGoodsStockException(
        'Production receipts must be corrected from the production batch.',
      );
    }

    final inverse =
        StockCorrectionHelper.inverseInventoryMovement(original.movementType);
    final correctionReason =
        '${StockCorrectionHelper.correctionReasonPrefix(original.transactionNumber)}'
        '${reason.trim().isEmpty ? '' : ' — ${reason.trim()}'}';

    return recordAdjustment(
      factoryId: original.factoryId,
      finishedGoodId: original.finishedGoodId,
      movementType: inverse,
      quantity: original.quantity,
      transactionDate: transactionDate,
      reason: correctionReason,
      notes: notes,
      unitCost: original.unitCost,
    );
  }

  Future<String> _generateTransactionNumber({
    required String factoryId,
    required InventoryMovementType movementType,
  }) {
    return _sequenceNumberService.allocate(
      factoryId: factoryId,
      sequence: movementType.documentSequence,
    );
  }
}
