import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/firebase_emulator_config.dart';
import '../../core/observability/tracked_firestore.dart';
import '../../domain/enums/document_sequence.dart';

class SequenceNumberException implements Exception {
  const SequenceNumberException(this.message, {this.isRetryable = false});

  final String message;

  /// True when the allocation failed for a transient reason (offline, or a
  /// contention retry budget exhausted) and the same call can simply be retried.
  final bool isRetryable;

  @override
  String toString() => message;
}

/// Thrown out of the allocation transaction when the counter does not exist yet,
/// so the caller can seed it from history and retry. Rolling the transaction
/// back is deliberate: nothing has been written at that point.
class _CounterMissing implements Exception {
  const _CounterMissing();
}

/// Issues document numbers such as `JW-2026-0001` from per-factory counter
/// documents.
///
/// Replaces the old `collection.get().docs.length + 1` approach, which read the
/// whole collection on every create and handed the same number to two
/// concurrent callers. Each allocation is a single transaction on one document:
/// one read, one write, regardless of how many documents already exist.
///
/// Counters live at `counters/{factoryId}__{sequenceKey}` and hold the last
/// issued value for the stored year.
class SequenceNumberService {
  SequenceNumberService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'counters';

  CollectionReference<Map<String, dynamic>> get _counters =>
      trackedCollection(_firestore, collectionName);

  static String documentId({
    required String factoryId,
    required DocumentSequence sequence,
  }) =>
      '${factoryId}__${sequence.key}';

  DocumentReference<Map<String, dynamic>> counterRef({
    required String factoryId,
    required DocumentSequence sequence,
  }) =>
      _counters.doc(documentId(factoryId: factoryId, sequence: sequence));

  /// Reserves and returns the next number for [sequence].
  ///
  /// The number is consumed even if the caller later fails to save its
  /// document, so gaps in the series are expected and harmless. Duplicates are
  /// not: that is the trade this makes.
  ///
  /// On the very first call for a factory the counter is seeded from the numbers
  /// already in the collection, so switching an existing deployment over does
  /// not restart the series at `0001`. That scan happens once per sequence.
  ///
  /// Throws [SequenceNumberException] when offline — a transaction cannot run
  /// against the local cache, so the caller must surface a "needs connection"
  /// message rather than invent a number.
  Future<String> allocate({
    required String factoryId,
    required DocumentSequence sequence,
    DateTime? now,
  }) async {
    final year = (now ?? DateTime.now()).year;
    try {
      int value;
      try {
        value = await _runAllocation(
          factoryId: factoryId,
          sequence: sequence,
          year: year,
          requireExisting: true,
        );
      } on _CounterMissing {
        await seedFromExistingDocuments(
          factoryId: factoryId,
          sequence: sequence,
          year: year,
        );
        value = await _runAllocation(
          factoryId: factoryId,
          sequence: sequence,
          year: year,
          requireExisting: false,
        );
      }
      return sequence.format(year: year, value: value);
    } on FirebaseException catch (error) {
      throw _translate(error, sequence);
    }
  }

  Future<int> _runAllocation({
    required String factoryId,
    required DocumentSequence sequence,
    required int year,
    required bool requireExisting,
  }) {
    final ref = counterRef(factoryId: factoryId, sequence: sequence);
    return _firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(ref);
      if (requireExisting && !snapshot.exists) throw const _CounterMissing();
      final next = _lastIssued(snapshot.data(), year) + 1;
      transaction.set(ref, {
        'factoryId': factoryId,
        'sequenceKey': sequence.key,
        'year': year,
        'value': next,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return next;
    });
  }

  /// Scans [sequence]'s collection and points its counter at the highest number
  /// already issued for [year]. Returns that value (0 when nothing matched).
  ///
  /// Costs one full read of that collection, which is why it runs only when the
  /// counter is absent.
  Future<int> seedFromExistingDocuments({
    required String factoryId,
    required DocumentSequence sequence,
    required int year,
  }) async {
    Query<Map<String, dynamic>> query =
        trackedCollection(_firestore, sequence.collection)
            .where('factoryId', isEqualTo: factoryId);
    final filterField = sequence.filterField;
    final filterValue = sequence.filterValue;
    if (filterField != null && filterValue != null) {
      query = query.where(filterField, isEqualTo: filterValue);
    }

    final snapshot = await query.get();
    final highest = sequence.highestIssued(
      year: year,
      numbers: snapshot.docs
          .map((doc) => doc.data()[sequence.numberField])
          .whereType<String>(),
    );
    if (highest > 0) {
      await seed(
        factoryId: factoryId,
        sequence: sequence,
        value: highest,
        year: year,
      );
    }
    return highest;
  }

  /// Points [sequence] at [value] so the next allocation returns `value + 1`.
  ///
  /// Only moves the counter forward: a stale or duplicate seed run cannot
  /// rewind a live counter and start re-issuing numbers.
  Future<void> seed({
    required String factoryId,
    required DocumentSequence sequence,
    required int value,
    required int year,
  }) async {
    final ref = counterRef(factoryId: factoryId, sequence: sequence);
    try {
      await _firestore.runTransaction<void>((transaction) async {
        final snapshot = await transaction.get(ref);
        if (_lastIssued(snapshot.data(), year) >= value) return;
        transaction.set(ref, {
          'factoryId': factoryId,
          'sequenceKey': sequence.key,
          'year': year,
          'value': value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (error) {
      throw _translate(error, sequence);
    }
  }

  /// Last issued value for [year], or 0 when the counter is absent or stale.
  int _lastIssued(Map<String, dynamic>? data, int year) {
    if (data == null) return 0;
    // A counter from a previous year restarts the series rather than continuing
    // it, which is what makes `JW-2027-0001` follow `JW-2026-0842`.
    if ((data['year'] as num?)?.toInt() != year) return 0;
    return (data['value'] as num?)?.toInt() ?? 0;
  }

  SequenceNumberException _translate(
    FirebaseException error,
    DocumentSequence sequence,
  ) {
    const offlineCodes = {
      'unavailable',
      'deadline-exceeded',
      'failed-precondition',
    };
    if (offlineCodes.contains(error.code)) {
      if (FirebaseEmulatorConfig.enabled) {
        return SequenceNumberException(
          'Cannot reach the local Firebase emulators, so a new '
          '${sequence.prefix} number cannot be reserved. This debug build does '
          'not talk to production. Stop the app and relaunch with '
          '--dart-define=USE_PROD_FIREBASE=true.',
          isRetryable: true,
        );
      }
      return SequenceNumberException(
        'Cannot create a new ${sequence.prefix} number while offline. '
        'Reconnect and try again.',
        isRetryable: true,
      );
    }
    if (error.code == 'permission-denied') {
      return SequenceNumberException(
        'You do not have permission to create a new ${sequence.prefix} number.',
      );
    }
    return SequenceNumberException(
      'Could not reserve a ${sequence.prefix} number (${error.code}). '
      'Please try again.',
      isRetryable: true,
    );
  }
}
