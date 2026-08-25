import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:factory_management/data/services/stock_backfill_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const factoryId = 'factory_a';

  late FakeFirebaseFirestore firestore;
  late StockBackfillMigration migration;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    firestore = FakeFirebaseFirestore();
    migration = StockBackfillMigration(
      firestore: firestore,
      preferences: await SharedPreferences.getInstance(),
    );
  });

  Future<void> seedRawMaterial(
    String id, {
    required double currentStock,
    required double averageCost,
    String factory = factoryId,
    Map<String, dynamic> extra = const {},
  }) {
    return firestore.collection('rawMaterials').doc(id).set({
      'factoryId': factory,
      'materialType': 'marbleBlocks',
      'currentStock': currentStock,
      'averageCost': averageCost,
      ...extra,
    });
  }

  Future<Map<String, dynamic>> rawMaterial(String id) async {
    final doc = await firestore.collection('rawMaterials').doc(id).get();
    return doc.data()!;
  }

  test('derives the totals from the fields that were already there', () async {
    await seedRawMaterial('a', currentStock: 100, averageCost: 450);
    await firestore.collection('finishedGoods').doc('b').set({
      'factoryId': factoryId,
      'skuKey': 'slabs|white|||gradeA',
      'currentQuantity': 250,
      'averageCost': 32,
    });

    final report = await migration.run(factoryId);

    expect(report.rawMaterialsMigrated, 1);
    expect(report.finishedGoodsMigrated, 1);
    expect(report.isComplete, isTrue);

    final material = await rawMaterial('a');
    expect(material['totalQuantity'], 100);
    expect(material['totalValue'], 45000);

    final good =
        (await firestore.collection('finishedGoods').doc('b').get()).data()!;
    expect(good['totalQuantity'], 250);
    expect(good['totalValue'], 8000);
  });

  test('leaves the existing valuation untouched', () async {
    await seedRawMaterial('a', currentStock: 37.5, averageCost: 412.8);

    await migration.run(factoryId);

    final material = await rawMaterial('a');
    final derivedUnitCost =
        (material['totalValue'] as num) / (material['totalQuantity'] as num);
    expect(derivedUnitCost, closeTo(412.8, 0.0000001));
    expect(material['averageCost'], 412.8);
    expect(material['currentStock'], 37.5);
  });

  test('an empty position becomes zero on both totals', () async {
    await seedRawMaterial('a', currentStock: 0, averageCost: 450);

    await migration.run(factoryId);

    final material = await rawMaterial('a');
    expect(material['totalQuantity'], 0);
    expect(material['totalValue'], 0);
  });

  test('is idempotent', () async {
    await seedRawMaterial('a', currentStock: 100, averageCost: 450);

    final first = await migration.run(factoryId);
    final second = await migration.run(factoryId);

    expect(first.migrated, 1);
    expect(second.migrated, 0);
    expect((await rawMaterial('a'))['totalQuantity'], 100);
  });

  test('does not overwrite totals a movement already wrote', () async {
    await seedRawMaterial(
      'a',
      currentStock: 100,
      averageCost: 450,
      extra: {'totalQuantity': 150, 'totalValue': 65000},
    );

    final report = await migration.run(factoryId);

    expect(report.migrated, 0);
    final material = await rawMaterial('a');
    expect(material['totalQuantity'], 150);
    expect(material['totalValue'], 65000);
  });

  test('ignores other factories', () async {
    await seedRawMaterial('mine', currentStock: 10, averageCost: 100);
    await seedRawMaterial(
      'theirs',
      currentStock: 20,
      averageCost: 200,
      factory: 'factory_b',
    );

    await migration.run(factoryId);

    expect((await rawMaterial('mine'))['totalQuantity'], 10);
    expect((await rawMaterial('theirs')).containsKey('totalQuantity'), isFalse);
  });

  test('does not stamp updatedAt, since no position changed', () async {
    await seedRawMaterial('a', currentStock: 100, averageCost: 450);

    await migration.run(factoryId);

    expect((await rawMaterial('a')).containsKey('updatedAt'), isFalse);
  });

  group('runIfNeeded', () {
    test('runs once per factory and then short-circuits', () async {
      await seedRawMaterial('a', currentStock: 100, averageCost: 450);

      final first = await migration.runIfNeeded(factoryId);
      await seedRawMaterial('b', currentStock: 5, averageCost: 10);
      final second = await migration.runIfNeeded(factoryId);

      expect(first.migrated, 1);
      expect(second.migrated, 0);
      // 'b' is left to the self-seeding write path rather than re-scanned.
      expect((await rawMaterial('b')).containsKey('totalQuantity'), isFalse);
    });

    test('still runs for a different factory', () async {
      await seedRawMaterial('mine', currentStock: 10, averageCost: 100);
      await seedRawMaterial(
        'theirs',
        currentStock: 20,
        averageCost: 200,
        factory: 'factory_b',
      );

      await migration.runIfNeeded(factoryId);
      final other = await migration.runIfNeeded('factory_b');

      expect(other.migrated, 1);
    });
  });
}
