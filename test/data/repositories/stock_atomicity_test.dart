import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:factory_management/data/models/raw_material_model.dart';
import 'package:factory_management/data/repositories/raw_material_repository.dart';
import 'package:factory_management/data/services/raw_material_stock_service.dart';
import 'package:factory_management/data/services/stock_movement_payload.dart';
import 'package:factory_management/domain/enums/raw_material_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const factoryId = 'factory_a';
  const materialType = RawMaterialType.marbleBlocks;
  final today = DateTime(2026, 6, 15);

  late FakeFirebaseFirestore firestore;
  late RawMaterialRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = RawMaterialRepository(firestore: firestore);
  });

  Future<Map<String, dynamic>> materialData() async {
    final snapshot = await firestore
        .collection('rawMaterials')
        .where('factoryId', isEqualTo: factoryId)
        .get();
    expect(snapshot.docs, hasLength(1), reason: 'expected a single position');
    return snapshot.docs.first.data();
  }

  Future<String> seedLegacyMaterial({
    required double currentStock,
    required double averageCost,
    double reorderLevel = 5,
  }) async {
    final doc = firestore.collection('rawMaterials').doc('legacy-doc');
    // Deliberately without totalQuantity/totalValue: this is the pre-S38 shape.
    await doc.set({
      'factoryId': factoryId,
      'materialType': materialType.firestoreValue,
      'currentStock': currentStock,
      'averageCost': averageCost,
      'reorderLevel': reorderLevel,
      'createdAt': Timestamp.fromDate(DateTime(2026)),
    });
    return doc.id;
  }

  group('buildStockMovementPayload', () {
    test('moves the totals through increments, not literals', () {
      final payload = buildStockMovementPayload(
        mirror: StockQuantityMirror.rawMaterial,
        quantityDelta: 50,
        valueDelta: 25000,
        projectedQuantity: 150,
        projectedUnitCost: 480,
      );

      expect(payload['totalQuantity'], isA<FieldValue>());
      expect(payload['totalValue'], isA<FieldValue>());
      // The legacy mirrors stay literal — they are the best-effort copies.
      expect(payload['currentStock'], 150);
      expect(payload['averageCost'], 480);
    });

    test('writes literal totals when the document predates S38', () {
      final payload = buildStockMovementPayload(
        mirror: StockQuantityMirror.rawMaterial,
        quantityDelta: 50,
        valueDelta: 25000,
        projectedQuantity: 150,
        projectedUnitCost: 480,
        replaceTotals: true,
      );

      expect(payload['totalQuantity'], 150);
      expect(payload['totalValue'], 150 * 480);
    });

    test('uses the finished goods mirror field when asked', () {
      final payload = buildStockMovementPayload(
        mirror: StockQuantityMirror.finishedGood,
        quantityDelta: 10,
        valueDelta: 100,
        projectedQuantity: 10,
        projectedUnitCost: 10,
      );

      expect(payload.containsKey('currentQuantity'), isTrue);
      expect(payload.containsKey('currentStock'), isFalse);
    });
  });

  group('derived cost', () {
    test('average cost comes from the stored totals', () {
      final model = RawMaterialModel.fromFirestore('id', {
        'factoryId': factoryId,
        'materialType': materialType.firestoreValue,
        'totalQuantity': 80,
        'totalValue': 40000,
      });

      expect(model.averageCost, 500);
      expect(model.hasStoredTotals, isTrue);
    });

    test('pre-S38 documents keep their valuation and are flagged', () {
      final model = RawMaterialModel.fromFirestore('id', {
        'factoryId': factoryId,
        'materialType': materialType.firestoreValue,
        'currentStock': 100,
        'averageCost': 450,
      });

      expect(model.totalQuantity, 100);
      expect(model.totalValue, 45000);
      expect(model.averageCost, 450);
      expect(model.hasStoredTotals, isFalse);
    });

    test('an empty position remembers what it last cost', () {
      final model = RawMaterialModel.fromFirestore('id', {
        'factoryId': factoryId,
        'materialType': materialType.firestoreValue,
        'totalQuantity': 0,
        'totalValue': 0,
        'averageCost': 450,
      });

      expect(model.averageCost, 450);
      expect(model.toEntity().stockValue, 0);
    });
  });

  group('recordStockIn', () {
    test('creates the position and its weighted average', () async {
      await repository.recordStockIn(
        factoryId: factoryId,
        materialType: materialType,
        quantity: 50,
        unitCost: 400,
        transactionDate: today,
      );

      final data = await materialData();
      expect(data['totalQuantity'], 50);
      expect(data['totalValue'], 20000);
      expect(data['currentStock'], 50);
      expect(data['averageCost'], 400);
    });

    test('two receipts land exactly and average across both costs', () async {
      await repository.recordStockIn(
        factoryId: factoryId,
        materialType: materialType,
        quantity: 50,
        unitCost: 400,
        transactionDate: today,
      );
      await repository.recordStockIn(
        factoryId: factoryId,
        materialType: materialType,
        quantity: 30,
        unitCost: 600,
        transactionDate: today,
      );

      final data = await materialData();
      expect(data['totalQuantity'], 80);
      expect(data['totalValue'], 50 * 400 + 30 * 600);

      final model = RawMaterialModel.fromFirestore('id', data);
      expect(model.averageCost, (50 * 400 + 30 * 600) / 80);
    });

    // The regression that makes the backfill safe to run late: `increment` reads
    // an absent totalQuantity as 0, so a receipt against an un-migrated document
    // would otherwise wipe the stock that was already there.
    test('does not discard stock held only in the legacy fields', () async {
      await seedLegacyMaterial(currentStock: 100, averageCost: 450);

      await repository.recordStockIn(
        factoryId: factoryId,
        materialType: materialType,
        quantity: 50,
        unitCost: 400,
        transactionDate: today,
      );

      final data = await materialData();
      expect(data['totalQuantity'], 150);
      expect(data['totalValue'], 100 * 450 + 50 * 400);
    });

    test('leaves the reorder level alone', () async {
      await seedLegacyMaterial(
        currentStock: 10,
        averageCost: 100,
        reorderLevel: 7,
      );

      await repository.recordStockIn(
        factoryId: factoryId,
        materialType: materialType,
        quantity: 5,
        unitCost: 100,
        transactionDate: today,
      );

      expect((await materialData())['reorderLevel'], 7);
    });

    test('records a stock transaction for every receipt', () async {
      await repository.recordStockIn(
        factoryId: factoryId,
        materialType: materialType,
        quantity: 50,
        unitCost: 400,
        transactionDate: today,
      );

      final movements = await firestore.collection('stockTransactions').get();
      expect(movements.docs, hasLength(1));
      expect(movements.docs.first.data()['quantity'], 50);
    });
  });

  group('recordStockOut', () {
    setUp(() async {
      await repository.recordStockIn(
        factoryId: factoryId,
        materialType: materialType,
        quantity: 80,
        unitCost: 500,
        transactionDate: today,
      );
    });

    test('lowers quantity and value but not the unit cost', () async {
      await repository.recordStockOut(
        factoryId: factoryId,
        materialType: materialType,
        quantity: 30,
        transactionDate: today,
      );

      final data = await materialData();
      expect(data['totalQuantity'], 50);
      expect(data['totalValue'], 25000);
      expect(RawMaterialModel.fromFirestore('id', data).averageCost, 500);
    });

    test('rejects issuing more than is on hand', () async {
      await expectLater(
        repository.recordStockOut(
          factoryId: factoryId,
          materialType: materialType,
          quantity: 81,
          transactionDate: today,
        ),
        throwsA(isA<RawMaterialStockException>()),
      );

      expect((await materialData())['totalQuantity'], 80);
    });

    test('consuming everything leaves zero value and a remembered cost',
        () async {
      await repository.recordStockOut(
        factoryId: factoryId,
        materialType: materialType,
        quantity: 80,
        transactionDate: today,
      );

      final data = await materialData();
      expect(data['totalQuantity'], 0);
      expect(data['totalValue'], 0);
      expect(RawMaterialModel.fromFirestore('id', data).averageCost, 500);
    });
  });

  group('recordAdjustment', () {
    test('adjustment in re-averages against the given unit cost', () async {
      await repository.recordStockIn(
        factoryId: factoryId,
        materialType: materialType,
        quantity: 40,
        unitCost: 500,
        transactionDate: today,
      );

      await repository.recordAdjustment(
        factoryId: factoryId,
        materialType: materialType,
        movementType: StockMovementType.adjustmentIn,
        quantity: 10,
        transactionDate: today,
        reason: 'Found in yard',
        unitCost: 700,
      );

      final data = await materialData();
      expect(data['totalQuantity'], 50);
      expect(data['totalValue'], 40 * 500 + 10 * 700);
    });

    test('adjustment out holds the unit cost steady', () async {
      await repository.recordStockIn(
        factoryId: factoryId,
        materialType: materialType,
        quantity: 40,
        unitCost: 500,
        transactionDate: today,
      );

      await repository.recordAdjustment(
        factoryId: factoryId,
        materialType: materialType,
        movementType: StockMovementType.adjustmentOut,
        quantity: 15,
        transactionDate: today,
        reason: 'Breakage',
      );

      final data = await materialData();
      expect(data['totalQuantity'], 25);
      expect(RawMaterialModel.fromFirestore('id', data).averageCost, 500);
    });

    test('an issue and its correction return the position to where it started',
        () async {
      await repository.recordStockIn(
        factoryId: factoryId,
        materialType: materialType,
        quantity: 40,
        unitCost: 500,
        transactionDate: today,
      );
      final before = await materialData();

      final issue = await repository.recordStockOut(
        factoryId: factoryId,
        materialType: materialType,
        quantity: 10,
        transactionDate: today,
      );
      await repository.recordCorrection(
        original: issue,
        transactionDate: today,
        reason: 'Wrong entry',
      );

      final after = await materialData();
      expect(after['totalQuantity'], before['totalQuantity']);
      expect(after['totalValue'], before['totalValue']);
    });
  });

  group('weighted average service', () {
    final service = RawMaterialStockService();

    test('falls back to the incoming cost for an empty position', () {
      expect(
        service.calculateWeightedAverageCost(
          currentStock: 0,
          currentAverageCost: 999,
          incomingQuantity: 10,
          incomingUnitCost: 250,
        ),
        250,
      );
    });

    test('ignores a zero-quantity receipt', () {
      expect(
        service.calculateWeightedAverageCost(
          currentStock: 10,
          currentAverageCost: 300,
          incomingQuantity: 0,
          incomingUnitCost: 900,
        ),
        300,
      );
    });
  });
}
