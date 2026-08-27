import 'package:factory_management/core/observability/firestore_metrics.dart';
import 'package:factory_management/presentation/widgets/debug/firestore_metrics_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(FirestoreMetrics.instance.reset);

  /// Mirrors the real wiring in `app.dart`: the overlay is installed through
  /// `MaterialApp.builder`, which places it *above* the Navigator. Widgets that
  /// need an `Overlay` ancestor (such as `Draggable`) therefore cannot be used.
  Widget appWithOverlay() {
    return MaterialApp(
      home: const Scaffold(body: Text('app content')),
      builder: (context, child) => FirestoreMetricsOverlay(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  group('FirestoreMetricsOverlay', () {
    testWidgets('builds above the Navigator without an Overlay ancestor',
        (tester) async {
      await tester.pumpWidget(appWithOverlay());

      expect(tester.takeException(), isNull);
      expect(find.text('app content'), findsOneWidget);
    });

    testWidgets('shows recorded reads and writes in the collapsed pill',
        (tester) async {
      await tester.pumpWidget(appWithOverlay());

      FirestoreMetrics.instance.recordReads(
        collection: 'payments',
        documents: 42,
        fromCache: false,
      );
      FirestoreMetrics.instance.recordWrites(collection: 'payments');
      await tester.pump();

      expect(find.textContaining('R 42'), findsOneWidget);
      expect(find.textContaining('W 1'), findsOneWidget);
    });

    testWidgets('expands to a per-collection breakdown and resets',
        (tester) async {
      await tester.pumpWidget(appWithOverlay());

      FirestoreMetrics.instance.recordReads(
        collection: 'jobWorkLoads',
        documents: 7,
        fromCache: false,
      );
      await tester.pump();

      await tester.tap(find.textContaining('R 7'));
      await tester.pump();

      expect(find.text('Firestore usage'), findsOneWidget);
      expect(find.text('jobWorkLoads'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(find.text('No Firestore activity yet.'), findsOneWidget);
    });

    testWidgets('recording a listener during build does not throw',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(body: SizedBox.shrink()),
          builder: (context, child) => FirestoreMetricsOverlay(
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              FirestoreMetrics.instance.recordListenerAttach('payments');
              FirestoreMetrics.instance.recordReads(
                collection: 'payments',
                documents: 3,
                fromCache: false,
              );
              return const Scaffold(body: Text('during build'));
            },
          ),
          builder: (context, child) => FirestoreMetricsOverlay(
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('L 1'), findsOneWidget);
      expect(find.textContaining('R 3'), findsOneWidget);
    });

    testWidgets('can be dragged without throwing', (tester) async {
      await tester.pumpWidget(appWithOverlay());

      await tester.drag(find.textContaining('R 0'), const Offset(60, 120));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
