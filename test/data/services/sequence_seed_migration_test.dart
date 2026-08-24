import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:factory_management/data/services/sequence_number_service.dart';
import 'package:factory_management/data/services/sequence_seed_migration.dart';
import 'package:factory_management/domain/enums/document_sequence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const factoryId = 'factory_a';
  final in2026 = DateTime(2026, 6, 15);

  late FakeFirebaseFirestore firestore;
  late SequenceNumberService service;
  late SequenceSeedMigration migration;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    firestore = FakeFirebaseFirestore();
    service = SequenceNumberService(firestore: firestore);
    migration = SequenceSeedMigration(
      sequenceNumberService: service,
      preferences: await SharedPreferences.getInstance(),
    );
  });

  test('seeds every sequence that has history', () async {
    await firestore.collection('jobWorkOrders').add({
      'factoryId': factoryId,
      'jobWorkNumber': 'JW-2026-0042',
    });
    await firestore.collection('salesInvoices').add({
      'factoryId': factoryId,
      'invoiceNumber': 'INV-2026-0007',
    });

    final report = await migration.run(factoryId, now: in2026);

    expect(report.isComplete, isTrue);
    expect(report.seeded[DocumentSequence.jobWorkOrder], 42);
    expect(report.seeded[DocumentSequence.salesInvoice], 7);
    expect(report.seeded, hasLength(2));
    expect(
      report.skipped,
      hasLength(DocumentSequence.values.length - 2),
    );
  });

  test('the next allocation continues the seeded series', () async {
    await firestore.collection('jobWorkOrders').add({
      'factoryId': factoryId,
      'jobWorkNumber': 'JW-2026-0042',
    });
    await migration.run(factoryId, now: in2026);

    final next = await service.allocate(
      factoryId: factoryId,
      sequence: DocumentSequence.jobWorkOrder,
      now: in2026,
    );
    expect(next, 'JW-2026-0043');
  });

  test('leaves a live counter alone', () async {
    await service.seed(
      factoryId: factoryId,
      sequence: DocumentSequence.jobWorkOrder,
      value: 900,
      year: 2026,
    );
    await firestore.collection('jobWorkOrders').add({
      'factoryId': factoryId,
      'jobWorkNumber': 'JW-2026-0042',
    });

    final report = await migration.run(factoryId, now: in2026);

    expect(report.seeded, isEmpty);
    expect(report.skipped, contains(DocumentSequence.jobWorkOrder));
    final next = await service.allocate(
      factoryId: factoryId,
      sequence: DocumentSequence.jobWorkOrder,
      now: in2026,
    );
    expect(next, 'JW-2026-0901');
  });

  test('runIfNeeded does the work once per factory', () async {
    await firestore.collection('jobWorkOrders').add({
      'factoryId': factoryId,
      'jobWorkNumber': 'JW-2026-0042',
    });

    final first = await migration.runIfNeeded(factoryId);
    expect(first.seeded[DocumentSequence.jobWorkOrder], 42);

    final second = await migration.runIfNeeded(factoryId);
    expect(second.seeded, isEmpty);
    expect(second.skipped, isEmpty, reason: 'should short-circuit, not rescan');
  });

  test('runIfNeeded retries on the next launch after a failure', () async {
    final failing = SequenceSeedMigration(
      sequenceNumberService: _ThrowingSequenceNumberService(firestore),
      preferences: await SharedPreferences.getInstance(),
    );

    final report = await failing.runIfNeeded(factoryId);
    expect(report.isComplete, isFalse);
    expect(report.failed, hasLength(DocumentSequence.values.length));

    // Flag not set, so a healthy run still happens later.
    final retried = await migration.runIfNeeded(factoryId);
    expect(retried.isComplete, isTrue);
  });
}

class _ThrowingSequenceNumberService extends SequenceNumberService {
  _ThrowingSequenceNumberService(FakeFirebaseFirestore firestore)
      : super(firestore: firestore);

  @override
  Future<int> seedFromExistingDocuments({
    required String factoryId,
    required DocumentSequence sequence,
    required int year,
  }) async {
    throw const SequenceNumberException('scan failed');
  }
}
