import 'package:factory_management/core/observability/firestore_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final metrics = FirestoreMetrics.instance;

  setUp(metrics.reset);

  group('FirestoreMetrics', () {
    test('separates server reads from cached reads', () {
      metrics.recordReads(
        collection: 'payments',
        documents: 12,
        fromCache: false,
      );
      metrics.recordReads(
        collection: 'payments',
        documents: 5,
        fromCache: true,
      );

      expect(metrics.totalServerReads, 12);
      expect(metrics.totalCachedReads, 5);
      expect(metrics.breakdown.single.totalReads, 17);
    });

    test('attributes reads to the right collection', () {
      metrics.recordReads(
        collection: 'jobWorkLoads',
        documents: 30,
        fromCache: false,
      );
      metrics.recordReads(
        collection: 'customers',
        documents: 4,
        fromCache: false,
      );

      final byName = {
        for (final entry in metrics.breakdown) entry.collection: entry,
      };
      expect(byName['jobWorkLoads']!.serverReads, 30);
      expect(byName['customers']!.serverReads, 4);
    });

    test('breakdown is ordered by total reads descending', () {
      metrics.recordReads(collection: 'a', documents: 3, fromCache: false);
      metrics.recordReads(collection: 'b', documents: 99, fromCache: false);
      metrics.recordReads(collection: 'c', documents: 40, fromCache: false);

      expect(
        metrics.breakdown.map((entry) => entry.collection).toList(),
        ['b', 'c', 'a'],
      );
    });

    test('counts listener attaches and query executions separately', () {
      metrics.recordListenerAttach('expenses');
      metrics.recordListenerAttach('expenses');
      metrics.recordQueryExecution('expenses');

      expect(metrics.totalListenerAttaches, 2);
      expect(metrics.totalQueryExecutions, 1);
      expect(metrics.totalServerReads, 0);
    });

    test('counts writes independently of reads', () {
      metrics.recordWrites(collection: 'payments', documents: 3);
      metrics.recordWrites(collection: 'payments');

      expect(metrics.totalWrites, 4);
      expect(metrics.totalServerReads, 0);
    });

    test('ignores non-positive document counts', () {
      metrics.recordReads(collection: 'noop', documents: 0, fromCache: false);
      metrics.recordWrites(collection: 'noop', documents: 0);

      expect(metrics.breakdown, isEmpty);
    });

    test('reset clears every counter', () {
      metrics.recordReads(collection: 'x', documents: 7, fromCache: false);
      metrics.recordWrites(collection: 'x');
      metrics.recordListenerAttach('x');

      metrics.reset();

      expect(metrics.totalServerReads, 0);
      expect(metrics.totalWrites, 0);
      expect(metrics.totalListenerAttaches, 0);
      expect(metrics.breakdown, isEmpty);
    });

    test('revision advances so the overlay rebuilds', () {
      final before = metrics.revision.value;
      metrics.recordReads(collection: 'x', documents: 1, fromCache: false);
      expect(metrics.revision.value, greaterThan(before));
    });

    test('summary line reports every counter', () {
      metrics.recordReads(collection: 'x', documents: 2, fromCache: false);
      metrics.recordReads(collection: 'x', documents: 1, fromCache: true);
      metrics.recordWrites(collection: 'x');
      metrics.recordListenerAttach('x');
      metrics.recordQueryExecution('x');

      expect(
        metrics.summaryLine(),
        'reads(server)=2 reads(cache)=1 writes=1 listeners=1 queries=1',
      );
    });
  });
}
