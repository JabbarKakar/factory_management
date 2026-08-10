import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/paginated_result.dart';

/// Reusable helper class for executing Firestore cursor-based pagination queries.
abstract final class FirestorePaginator {
  /// Fetches a single page of documents from Firestore given a base [query].
  ///
  /// - Applies `.orderBy(orderByField, descending: descending)`
  /// - Applies `.startAfterDocument(startAfter)` if [startAfter] is provided
  /// - Applies `.limit(limit)` (defaults to 20)
  static Future<PaginatedResult<T>> fetchPage<T>({
    required Query<Map<String, dynamic>> query,
    required T Function(String id, Map<String, dynamic> data) mapDoc,
    required String orderByField,
    bool descending = true,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    var q = query.orderBy(orderByField, descending: descending);

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    q = q.limit(limit);

    final snapshot = await q.get();
    final items = snapshot.docs
        .map((doc) => mapDoc(doc.id, doc.data()))
        .toList();

    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    final hasMore = snapshot.docs.length == limit;

    return PaginatedResult<T>(
      items: items,
      lastDocument: lastDoc,
      hasMore: hasMore,
    );
  }
}
