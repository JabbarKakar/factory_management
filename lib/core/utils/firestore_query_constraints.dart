import 'package:cloud_firestore/cloud_firestore.dart';

/// Applies an optional lower date bound and document cap to a factory-scoped
/// Firestore query.
///
/// When [from] is set, [dateField] is required and is also used for `orderBy`
/// (Firestore demands the inequality field be ordered). A [limit] without a
/// date window does not add `orderBy`, so existing single-field `factoryId`
/// indexes keep working for small catalog collections.
Query<Map<String, dynamic>> constrainFactoryQuery(
  Query<Map<String, dynamic>> query, {
  String? dateField,
  DateTime? from,
  int? limit,
  bool descending = true,
}) {
  var next = query;
  if (from != null) {
    if (dateField == null) {
      throw ArgumentError('dateField is required when from is set');
    }
    next = next.where(
      dateField,
      isGreaterThanOrEqualTo: Timestamp.fromDate(from),
    );
  }
  if (dateField != null && from != null) {
    next = next.orderBy(dateField, descending: descending);
  }
  if (limit != null) {
    next = next.limit(limit);
  }
  return next;
}
