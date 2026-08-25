import 'package:cloud_firestore/cloud_firestore.dart';

/// Names the pre-S38 quantity field that each stock collection still mirrors.
enum StockQuantityMirror {
  rawMaterial('currentStock'),
  finishedGood('currentQuantity');

  const StockQuantityMirror(this.field);

  final String field;
}

/// Builds the Firestore payload for a single stock movement.
///
/// Quantity and value move through `FieldValue.increment`, which is what makes
/// concurrent movements safe: the server adds each delta to whatever it holds, so
/// two devices recording against the same material both land, and the write still
/// applies from the local cache while offline (decision A1).
///
/// [projectedQuantity] and [projectedUnitCost] are computed on the client and
/// written only as legacy mirrors. They can lag when writes overlap, which is
/// exactly why `totalQuantity`/`totalValue` are the fields everything reads.
///
/// Always apply this with `SetOptions(merge: true)`: fields the caller leaves out
/// (`reorderLevel`, `location`, …) must keep whatever the document already has.
///
/// Set [replaceTotals] when the target document predates S38 and therefore has no
/// `totalQuantity` field. `increment` would read that absent field as 0 and so
/// silently discard the existing stock, so the totals are written as literals for
/// that one movement instead. This write is not concurrency-safe — it is the same
/// read-modify-write the sprint removes — but it happens at most once per
/// document, and every movement after it increments.
Map<String, dynamic> buildStockMovementPayload({
  required StockQuantityMirror mirror,
  required double quantityDelta,
  required double valueDelta,
  required double projectedQuantity,
  required double projectedUnitCost,
  Map<String, dynamic> identity = const <String, dynamic>{},
  DateTime? lastReceiptDate,
  bool isCreate = false,
  bool replaceTotals = false,
}) {
  return <String, dynamic>{
    ...identity,
    'totalQuantity': replaceTotals
        ? projectedQuantity
        : FieldValue.increment(quantityDelta),
    'totalValue': replaceTotals
        ? projectedQuantity * projectedUnitCost
        : FieldValue.increment(valueDelta),
    mirror.field: projectedQuantity,
    'averageCost': projectedUnitCost,
    if (lastReceiptDate != null)
      'lastReceiptDate': Timestamp.fromDate(lastReceiptDate),
    if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
