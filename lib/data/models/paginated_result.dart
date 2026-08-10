import 'package:cloud_firestore/cloud_firestore.dart';

/// Generic container class holding a paginated batch from Firestore.
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  static PaginatedResult<T> empty<T>() => const PaginatedResult(
        items: [],
        lastDocument: null,
        hasMore: false,
      );
}
