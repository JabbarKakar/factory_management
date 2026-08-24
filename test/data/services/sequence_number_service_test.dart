import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:factory_management/data/services/sequence_number_service.dart';
import 'package:factory_management/domain/enums/document_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const factoryId = 'factory_a';
  final in2026 = DateTime(2026, 6, 15);

  late FakeFirebaseFirestore firestore;
  late SequenceNumberService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = SequenceNumberService(firestore: firestore);
  });

  Future<Map<String, dynamic>?> counterData(DocumentSequence sequence) async {
    final snapshot = await service
        .counterRef(factoryId: factoryId, sequence: sequence)
        .get();
    return snapshot.data();
  }

  group('allocate', () {
    test('starts at 0001 for an empty collection', () async {
      final number = await service.allocate(
        factoryId: factoryId,
        sequence: DocumentSequence.jobWorkOrder,
        now: in2026,
      );
      expect(number, 'JW-2026-0001');
    });

    test('increments on each call', () async {
      final numbers = <String>[];
      for (var i = 0; i < 3; i++) {
        numbers.add(
          await service.allocate(
            factoryId: factoryId,
            sequence: DocumentSequence.jobWorkOrder,
            now: in2026,
          ),
        );
      }
      expect(numbers, ['JW-2026-0001', 'JW-2026-0002', 'JW-2026-0003']);
    });

    // Parallel allocation is not covered here: fake_cloud_firestore runs
    // transaction bodies without isolation, so twenty concurrent callers all
    // read the same snapshot and every one is handed 0001. Contention has to be
    // verified against the emulator (see the S37 device test in
    // docs/MFMS_Phase2_Data_Integrity_Cost_Sprints.md).

    test('writes the counter document the migration reads', () async {
      await service.allocate(
        factoryId: factoryId,
        sequence: DocumentSequence.jobWorkOrder,
        now: in2026,
      );

      final data = await counterData(DocumentSequence.jobWorkOrder);
      expect(data, isNotNull);
      expect(data!['factoryId'], factoryId);
      expect(data['sequenceKey'], 'jobWorkOrder');
      expect(data['year'], 2026);
      expect(data['value'], 1);
    });

    test('keeps factories on separate series', () async {
      final first = await service.allocate(
        factoryId: 'factory_a',
        sequence: DocumentSequence.jobWorkOrder,
        now: in2026,
      );
      final second = await service.allocate(
        factoryId: 'factory_b',
        sequence: DocumentSequence.jobWorkOrder,
        now: in2026,
      );
      expect(first, 'JW-2026-0001');
      expect(second, 'JW-2026-0001');
    });

    test('restarts at 0001 in a new year', () async {
      await service.allocate(
        factoryId: factoryId,
        sequence: DocumentSequence.jobWorkOrder,
        now: in2026,
      );
      await service.allocate(
        factoryId: factoryId,
        sequence: DocumentSequence.jobWorkOrder,
        now: in2026,
      );

      final rolled = await service.allocate(
        factoryId: factoryId,
        sequence: DocumentSequence.jobWorkOrder,
        now: DateTime(2027, 1, 1),
      );
      expect(rolled, 'JW-2027-0001');
    });

    test('does not rescan history after the year rolls over', () async {
      // A 2026 document exists but the counter is already live, so the 2027
      // series must start at 1 rather than continuing from 2026's numbers.
      await firestore.collection('jobWorkOrders').add({
        'factoryId': factoryId,
        'jobWorkNumber': 'JW-2027-0500',
      });
      await service.allocate(
        factoryId: factoryId,
        sequence: DocumentSequence.jobWorkOrder,
        now: in2026,
      );

      final rolled = await service.allocate(
        factoryId: factoryId,
        sequence: DocumentSequence.jobWorkOrder,
        now: DateTime(2027, 3, 4),
      );
      expect(rolled, 'JW-2027-0001');
    });
  });

  group('first-use seeding', () {
    test('continues from the highest existing number', () async {
      for (final number in ['JW-2026-0001', 'JW-2026-0842', 'JW-2026-0099']) {
        await firestore.collection('jobWorkOrders').add({
          'factoryId': factoryId,
          'jobWorkNumber': number,
        });
      }

      final next = await service.allocate(
        factoryId: factoryId,
        sequence: DocumentSequence.jobWorkOrder,
        now: in2026,
      );
      expect(next, 'JW-2026-0843');
    });

    test('ignores documents from another factory', () async {
      await firestore.collection('jobWorkOrders').add({
        'factoryId': 'factory_b',
        'jobWorkNumber': 'JW-2026-0900',
      });

      final next = await service.allocate(
        factoryId: factoryId,
        sequence: DocumentSequence.jobWorkOrder,
        now: in2026,
      );
      expect(next, 'JW-2026-0001');
    });

    test('scans only once, not on every allocation', () async {
      await firestore.collection('jobWorkOrders').add({
        'factoryId': factoryId,
        'jobWorkNumber': 'JW-2026-0010',
      });

      final first = await service.allocate(
        factoryId: factoryId,
        sequence: DocumentSequence.jobWorkOrder,
        now: in2026,
      );
      // A document created after the seed must not pull the counter backwards.
      await firestore.collection('jobWorkOrders').add({
        'factoryId': factoryId,
        'jobWorkNumber': 'JW-2026-0003',
      });
      final second = await service.allocate(
        factoryId: factoryId,
        sequence: DocumentSequence.jobWorkOrder,
        now: in2026,
      );

      expect(first, 'JW-2026-0011');
      expect(second, 'JW-2026-0012');
    });

    test('separates series that share a collection', () async {
      await firestore.collection('stockTransactions').add({
        'factoryId': factoryId,
        'movementType': 'stockIn',
        'transactionNumber': 'STK-IN-2026-0005',
      });
      await firestore.collection('stockTransactions').add({
        'factoryId': factoryId,
        'movementType': 'stockOut',
        'transactionNumber': 'STK-OUT-2026-0099',
      });

      final stockIn = await service.allocate(
        factoryId: factoryId,
        sequence: DocumentSequence.rawMaterialStockIn,
        now: in2026,
      );
      final stockOut = await service.allocate(
        factoryId: factoryId,
        sequence: DocumentSequence.rawMaterialStockOut,
        now: in2026,
      );

      expect(stockIn, 'STK-IN-2026-0006');
      expect(stockOut, 'STK-OUT-2026-0100');
    });
  });

  group('seed', () {
    test('sets the counter so the next number follows it', () async {
      await service.seed(
        factoryId: factoryId,
        sequence: DocumentSequence.delivery,
        value: 77,
        year: 2026,
      );

      final next = await service.allocate(
        factoryId: factoryId,
        sequence: DocumentSequence.delivery,
        now: in2026,
      );
      expect(next, 'DEL-2026-0078');
    });

    test('refuses to move a counter backwards', () async {
      await service.seed(
        factoryId: factoryId,
        sequence: DocumentSequence.delivery,
        value: 77,
        year: 2026,
      );
      await service.seed(
        factoryId: factoryId,
        sequence: DocumentSequence.delivery,
        value: 5,
        year: 2026,
      );

      final data = await counterData(DocumentSequence.delivery);
      expect(data!['value'], 77);
    });
  });

  group('seedFromExistingDocuments', () {
    test('returns 0 and writes nothing when there is no history', () async {
      final highest = await service.seedFromExistingDocuments(
        factoryId: factoryId,
        sequence: DocumentSequence.expense,
        year: 2026,
      );

      expect(highest, 0);
      expect(await counterData(DocumentSequence.expense), isNull);
    });

    test('reads the number field declared on the sequence', () async {
      await firestore.collection('expenses').add({
        'factoryId': factoryId,
        'expenseNumber': 'EXP-2026-0031',
      });

      final highest = await service.seedFromExistingDocuments(
        factoryId: factoryId,
        sequence: DocumentSequence.expense,
        year: 2026,
      );

      expect(highest, 31);
      expect((await counterData(DocumentSequence.expense))!['value'], 31);
    });
  });

  test('counter ids are namespaced per factory and sequence', () {
    expect(
      SequenceNumberService.documentId(
        factoryId: 'factory_a',
        sequence: DocumentSequence.jobWorkOrder,
      ),
      'factory_a__jobWorkOrder',
    );
  });
}
