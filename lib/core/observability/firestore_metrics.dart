import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Per-collection Firestore usage counters.
class CollectionMetrics {
  CollectionMetrics(this.collection);

  final String collection;

  /// Documents billed as reads from the server.
  int serverReads = 0;

  /// Documents served from the local cache (not billed).
  int cachedReads = 0;

  /// Documents written (set / update / delete / add).
  int writes = 0;

  /// Number of `snapshots()` subscriptions opened.
  int listenerAttaches = 0;

  /// Number of one-shot `get()` calls.
  int queryExecutions = 0;

  int get totalReads => serverReads + cachedReads;
}

/// Debug-only counter for Firestore document reads and writes.
///
/// Firestore bills per document, so these counters mirror the billing model:
/// a new listener bills every document in its first snapshot, then only the
/// changed documents on each later snapshot.
///
/// Tracking is compiled out of release builds via [enabled]; every recording
/// method is a no-op when disabled.
class FirestoreMetrics {
  FirestoreMetrics._();

  static final FirestoreMetrics instance = FirestoreMetrics._();

  /// Instrumentation is debug-only; release builds pay no overhead.
  static bool get enabled => kDebugMode;

  final Map<String, CollectionMetrics> _byCollection = {};

  /// Bumped on every recorded event so the overlay can rebuild.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  DateTime _since = DateTime.now();
  DateTime get since => _since;

  bool _notifyScheduled = false;

  int get totalServerReads =>
      _byCollection.values.fold(0, (sum, m) => sum + m.serverReads);

  int get totalCachedReads =>
      _byCollection.values.fold(0, (sum, m) => sum + m.cachedReads);

  int get totalWrites =>
      _byCollection.values.fold(0, (sum, m) => sum + m.writes);

  int get totalListenerAttaches =>
      _byCollection.values.fold(0, (sum, m) => sum + m.listenerAttaches);

  int get totalQueryExecutions =>
      _byCollection.values.fold(0, (sum, m) => sum + m.queryExecutions);

  /// Collections with any recorded activity, most reads first.
  List<CollectionMetrics> get breakdown {
    final list = _byCollection.values.toList()
      ..sort((a, b) => b.totalReads.compareTo(a.totalReads));
    return list;
  }

  CollectionMetrics _entry(String collection) =>
      _byCollection.putIfAbsent(collection, () => CollectionMetrics(collection));

  void recordReads({
    required String collection,
    required int documents,
    required bool fromCache,
  }) {
    if (!enabled || documents <= 0) return;
    final entry = _entry(collection);
    if (fromCache) {
      entry.cachedReads += documents;
    } else {
      entry.serverReads += documents;
    }
    _notify();
  }

  void recordQueryExecution(String collection) {
    if (!enabled) return;
    _entry(collection).queryExecutions++;
    _notify();
  }

  void recordListenerAttach(String collection) {
    if (!enabled) return;
    _entry(collection).listenerAttaches++;
    _notify();
  }

  void recordWrites({required String collection, int documents = 1}) {
    if (!enabled || documents <= 0) return;
    _entry(collection).writes += documents;
    _notify();
  }

  void reset() {
    if (!enabled) return;
    _byCollection.clear();
    _since = DateTime.now();
    _notify();
  }

  /// Single-line summary for logs and for pasting into the measurement log.
  String summaryLine() {
    return 'reads(server)=$totalServerReads '
        'reads(cache)=$totalCachedReads '
        'writes=$totalWrites '
        'listeners=$totalListenerAttaches '
        'queries=$totalQueryExecutions';
  }

  /// Bumps [revision] so the overlay rebuilds.
  ///
  /// Screens attach `snapshots()` listeners while they are still building
  /// (`StreamBuilder` / `watch*` in `build`). Notifying immediately would call
  /// `setState` on the overlay's [ValueListenableBuilder] during that build.
  /// Counters still update synchronously; only the overlay rebuild is deferred
  /// and coalesced to the end of the frame.
  void _notify() {
    SchedulerBinding? binding;
    try {
      binding = SchedulerBinding.instance;
    } catch (_) {
      binding = null;
    }
    if (binding != null &&
        (binding.schedulerPhase == SchedulerPhase.persistentCallbacks ||
            binding.schedulerPhase == SchedulerPhase.midFrameMicrotasks)) {
      if (_notifyScheduled) return;
      _notifyScheduled = true;
      binding.addPostFrameCallback((_) {
        _notifyScheduled = false;
        revision.value++;
      });
      return;
    }
    revision.value++;
  }
}
