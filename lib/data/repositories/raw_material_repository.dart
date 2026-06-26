import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/raw_material.dart';
import '../../domain/entities/stock_transaction.dart';
import '../../domain/enums/raw_material_enums.dart';
import '../models/raw_material_model.dart';
import '../models/stock_transaction_model.dart';
import '../services/raw_material_stock_service.dart';

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

  Future<String> _generateTransactionNumber({
    required String factoryId,
    required StockMovementType movementType,
  }) async {
    final year = DateTime.now().year;
    final prefix = movementType == StockMovementType.stockIn ? 'STK-IN' : 'STK-OUT';
    final snapshot = await _transactionsCollection
        .where('factoryId', isEqualTo: factoryId)
        .where('movementType', isEqualTo: movementType.firestoreValue)
        .get();
    final count = snapshot.docs.length + 1;
    return '$prefix-$year-${count.toString().padLeft(4, '0')}';
  }
}
