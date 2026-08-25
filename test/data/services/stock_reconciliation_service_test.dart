import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:factory_management/data/services/stock_reconciliation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const factoryId = 'factory_a';

  late FakeFirebaseFirestore firestore;
  late StockReconciliationService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = StockReconciliationService(firestore: firestore);
  });

  Future<void> seedMaterial({
    required String id,
    required double totalQuantity,
    double totalValue = 0,
  }) {
    return firestore.collection('rawMaterials').doc(id).set({
      'factoryId': factoryId,
      'materialType': 'marbleBlocks',
      'totalQuantity': totalQuantity,
      'totalValue': totalValue,
    });
  }

  Future<void> seedMovement({
    required String materialId,
    required String movementType,
    required double quantity,
  }) {
    return firestore.collection('stockTransactions').add({
      'factoryId': factoryId,
      'rawMaterialId': materialId,
      'materialType': 'marbleBlocks',
      'movementType': movementType,
      'quantity': quantity,
    });
  }

  test('a position matching its movements is balanced', () async {
    await seedMaterial(id: 'a', totalQuantity: 70, totalValue: 35000);
    await seedMovement(
      materialId: 'a',
      movementType: 'stockIn',
      quantity: 100,
    );
    await seedMovement(
      materialId: 'a',
      movementType: 'stockOut',
      quantity: 30,
    );

    final report = await service.run(factoryId);
    final row = report.rawMaterials.single;

    expect(row.ledgerQuantity, 70);
    expect(row.movementCount, 2);
    expect(row.isBalanced, isTrue);
    expect(report.drifting, isEmpty);
  });

  test('adjustments count with the right sign', () async {
    await seedMaterial(id: 'a', totalQuantity: 15);
    await seedMovement(
      materialId: 'a',
      movementType: 'adjustmentIn',
      quantity: 20,
    );
    await seedMovement(
      materialId: 'a',
      movementType: 'adjustmentOut',
      quantity: 5,
    );

    final report = await service.run(factoryId);
    expect(report.rawMaterials.single.ledgerQuantity, 15);
  });

  test('drift is reported with its size', () async {
    await seedMaterial(id: 'a', totalQuantity: 130);
    await seedMovement(materialId: 'a', movementType: 'stockIn', quantity: 100);
    await seedMovement(materialId: 'a', movementType: 'stockIn', quantity: 80);

    final report = await service.run(factoryId);
    final row = report.rawMaterials.single;

    expect(row.isBalanced, isFalse);
    expect(row.drift, -50);
    expect(report.drifting, hasLength(1));
  });

  test('a position with no movements is called out separately', () async {
    await seedMaterial(id: 'a', totalQuantity: 100);

    final report = await service.run(factoryId);
    final row = report.rawMaterials.single;

    expect(row.isUnattributable, isTrue);
    expect(report.openingBalanceCount, 1);
    // An opening balance is not counted as a fault.
    expect(report.drifting, isEmpty);
  });

  test('documents predating S38 are listed as unmigrated', () async {
    await firestore.collection('rawMaterials').doc('a').set({
      'factoryId': factoryId,
      'materialType': 'marbleBlocks',
      'currentStock': 100,
      'averageCost': 450,
    });

    final report = await service.run(factoryId);

    expect(report.unmigrated, hasLength(1));
    expect(report.rawMaterials.single.recordedQuantity, 100);
    expect(report.rawMaterials.single.unitCost, 450);
  });

  test('finished goods reconcile against inventory transactions', () async {
    await firestore.collection('finishedGoods').doc('sku').set({
      'factoryId': factoryId,
      'skuKey': 'slabs|white|||gradeA',
      'marbleVariety': 'White',
      'grade': 'gradeA',
      'totalQuantity': 180,
      'totalValue': 5400,
    });
    await firestore.collection('inventoryTransactions').add({
      'factoryId': factoryId,
      'finishedGoodId': 'sku',
      'movementType': 'productionIn',
      'quantity': 200,
    });
    await firestore.collection('inventoryTransactions').add({
      'factoryId': factoryId,
      'finishedGoodId': 'sku',
      'movementType': 'adjustmentOut',
      'quantity': 20,
    });

    final report = await service.run(factoryId);
    final row = report.finishedGoods.single;

    expect(row.ledgerQuantity, 180);
    expect(row.isBalanced, isTrue);
  });

  test('another factory is not mixed in', () async {
    await seedMaterial(id: 'mine', totalQuantity: 10);
    await firestore.collection('rawMaterials').doc('theirs').set({
      'factoryId': 'factory_b',
      'materialType': 'marbleBlocks',
      'totalQuantity': 999,
    });

    final report = await service.run(factoryId);
    expect(report.rawMaterials, hasLength(1));
    expect(report.rawMaterials.single.id, 'mine');
  });
}
