// `Query` and `CollectionReference` are annotated `@sealed` to discourage
// third-party implementations. Delegation is still safe here because every
// member forwards to a real SDK object and no private SDK state is
// reconstructed — the same approach `fake_cloud_firestore` uses. The trade-off
// is that a `cloud_firestore` upgrade adding a member will fail this file at
// compile time, which is a loud, contained failure rather than a silent one.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_metrics.dart';

/// Returns a read-tracking view of [name] when instrumentation is enabled.
///
/// In release builds the raw [CollectionReference] is returned, so there is no
/// wrapper on the hot path.
///
/// Only *query* reads are tracked. [CollectionReference.doc] intentionally
/// returns the real, unwrapped [DocumentReference] because `Transaction.set`
/// and `WriteBatch.set` type-check their argument against the SDK's private
/// reference classes and would throw on a wrapper.
CollectionReference<Map<String, dynamic>> trackedCollection(
  FirebaseFirestore firestore,
  String name,
) {
  final reference = firestore.collection(name);
  if (!FirestoreMetrics.enabled) return reference;
  return TrackedCollectionReference(reference, name);
}

/// Delegating [Query] that records document reads against a collection name.
class TrackedQuery implements Query<Map<String, dynamic>> {
  TrackedQuery(this._query, this._collection);

  final Query<Map<String, dynamic>> _query;
  final String _collection;

  TrackedQuery _wrap(Query<Map<String, dynamic>> query) =>
      TrackedQuery(query, _collection);

  @override
  FirebaseFirestore get firestore => _query.firestore;

  @override
  Map<String, dynamic> get parameters => _query.parameters;

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    FirestoreMetrics.instance.recordQueryExecution(_collection);
    final snapshot = await _query.get(options);
    FirestoreMetrics.instance.recordReads(
      collection: _collection,
      documents: snapshot.docs.length,
      fromCache: snapshot.metadata.isFromCache,
    );
    return snapshot;
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    FirestoreMetrics.instance.recordListenerAttach(_collection);
    // Firestore bills every document in a listener's first snapshot, then only
    // the changed documents on each later snapshot.
    var isFirstSnapshot = true;
    return _query
        .snapshots(
          includeMetadataChanges: includeMetadataChanges,
          source: source,
        )
        .map((snapshot) {
          final documents = isFirstSnapshot
              ? snapshot.docs.length
              : snapshot.docChanges.length;
          isFirstSnapshot = false;
          FirestoreMetrics.instance.recordReads(
            collection: _collection,
            documents: documents,
            fromCache: snapshot.metadata.isFromCache,
          );
          return snapshot;
        });
  }

  @override
  Query<Map<String, dynamic>> endAtDocument(DocumentSnapshot documentSnapshot) =>
      _wrap(_query.endAtDocument(documentSnapshot));

  @override
  Query<Map<String, dynamic>> endAt(Iterable<Object?> values) =>
      _wrap(_query.endAt(values));

  @override
  Query<Map<String, dynamic>> endBeforeDocument(
    DocumentSnapshot documentSnapshot,
  ) =>
      _wrap(_query.endBeforeDocument(documentSnapshot));

  @override
  Query<Map<String, dynamic>> endBefore(Iterable<Object?> values) =>
      _wrap(_query.endBefore(values));

  @override
  Query<Map<String, dynamic>> limit(int limit) => _wrap(_query.limit(limit));

  @override
  Query<Map<String, dynamic>> limitToLast(int limit) =>
      _wrap(_query.limitToLast(limit));

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) =>
      _wrap(_query.orderBy(field, descending: descending));

  @override
  Query<Map<String, dynamic>> startAfterDocument(
    DocumentSnapshot documentSnapshot,
  ) =>
      _wrap(_query.startAfterDocument(documentSnapshot));

  @override
  Query<Map<String, dynamic>> startAfter(Iterable<Object?> values) =>
      _wrap(_query.startAfter(values));

  @override
  Query<Map<String, dynamic>> startAtDocument(
    DocumentSnapshot documentSnapshot,
  ) =>
      _wrap(_query.startAtDocument(documentSnapshot));

  @override
  Query<Map<String, dynamic>> startAt(Iterable<Object?> values) =>
      _wrap(_query.startAt(values));

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) =>
      _wrap(
        _query.where(
          field,
          isEqualTo: isEqualTo,
          isNotEqualTo: isNotEqualTo,
          isLessThan: isLessThan,
          isLessThanOrEqualTo: isLessThanOrEqualTo,
          isGreaterThan: isGreaterThan,
          isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
          arrayContains: arrayContains,
          arrayContainsAny: arrayContainsAny,
          whereIn: whereIn,
          whereNotIn: whereNotIn,
          isNull: isNull,
        ),
      );

  @override
  Query<R> withConverter<R>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  }) =>
      _query.withConverter<R>(
        fromFirestore: fromFirestore,
        toFirestore: toFirestore,
      );

  @override
  AggregateQuery count() => _query.count();

  @override
  AggregateQuery aggregate(
    AggregateField aggregateField1, [
    AggregateField? aggregateField2,
    AggregateField? aggregateField3,
    AggregateField? aggregateField4,
    AggregateField? aggregateField5,
    AggregateField? aggregateField6,
    AggregateField? aggregateField7,
    AggregateField? aggregateField8,
    AggregateField? aggregateField9,
    AggregateField? aggregateField10,
    AggregateField? aggregateField11,
    AggregateField? aggregateField12,
    AggregateField? aggregateField13,
    AggregateField? aggregateField14,
    AggregateField? aggregateField15,
    AggregateField? aggregateField16,
    AggregateField? aggregateField17,
    AggregateField? aggregateField18,
    AggregateField? aggregateField19,
    AggregateField? aggregateField20,
    AggregateField? aggregateField21,
    AggregateField? aggregateField22,
    AggregateField? aggregateField23,
    AggregateField? aggregateField24,
    AggregateField? aggregateField25,
    AggregateField? aggregateField26,
    AggregateField? aggregateField27,
    AggregateField? aggregateField28,
    AggregateField? aggregateField29,
    AggregateField? aggregateField30,
  ]) =>
      _query.aggregate(
        aggregateField1,
        aggregateField2,
        aggregateField3,
        aggregateField4,
        aggregateField5,
        aggregateField6,
        aggregateField7,
        aggregateField8,
        aggregateField9,
        aggregateField10,
        aggregateField11,
        aggregateField12,
        aggregateField13,
        aggregateField14,
        aggregateField15,
        aggregateField16,
        aggregateField17,
        aggregateField18,
        aggregateField19,
        aggregateField20,
        aggregateField21,
        aggregateField22,
        aggregateField23,
        aggregateField24,
        aggregateField25,
        aggregateField26,
        aggregateField27,
        aggregateField28,
        aggregateField29,
        aggregateField30,
      );
}

/// Delegating [CollectionReference] that tracks query reads and `add` writes.
class TrackedCollectionReference extends TrackedQuery
    implements CollectionReference<Map<String, dynamic>> {
  TrackedCollectionReference(this._reference, String collection)
      : super(_reference, collection);

  final CollectionReference<Map<String, dynamic>> _reference;

  @override
  String get id => _reference.id;

  @override
  String get path => _reference.path;

  @override
  DocumentReference<Map<String, dynamic>>? get parent => _reference.parent;

  /// Returns the real reference so it stays valid inside batches and
  /// transactions, which type-check against the SDK's private classes.
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _reference.doc(path);

  @override
  CollectionReference<R> withConverter<R>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  }) =>
      _reference.withConverter<R>(
        fromFirestore: fromFirestore,
        toFirestore: toFirestore,
      );

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(
    Map<String, dynamic> data,
  ) async {
    final reference = await _reference.add(data);
    FirestoreMetrics.instance.recordWrites(collection: _collection);
    return reference;
  }
}
