import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/observability/tracked_firestore.dart';

@immutable
class StockBackfillReport {
  const StockBackfillReport({
    this.rawMaterialsMigrated = 0,
    this.finishedGoodsMigrated = 0,
    this.failures = const {},
  });

  static const StockBackfillReport empty = StockBackfillReport();

  /// Documents that gained `totalQuantity`/`totalValue` on this run.
  final int rawMaterialsMigrated;
  final int finishedGoodsMigrated;

  /// Collection name to failure reason, for collections that could not be read
  /// or written.
  final Map<String, String> failures;

  bool get isComplete => failures.isEmpty;

  int get migrated => rawMaterialsMigrated + finishedGoodsMigrated;

  @override
  String toString() => 'rawMaterials=$rawMaterialsMigrated '
      'finishedGoods=$finishedGoodsMigrated'
      '${failures.isEmpty ? '' : ' errors=$failures'}';
}

/// Gives every existing stock document the `totalQuantity`/`totalValue` pair that
/// S38 treats as the source of truth.
///
/// The totals are derived from the fields that were already there
/// (`quantity × averageCost`), so a document's valuation is unchanged — that is
/// what the reconciliation screen checks.
///
/// Movement writes seed the totals themselves when they meet a document that
/// predates S38, so this migration is an optimisation rather than a
/// prerequisite: it converts everything in one pass instead of leaving the first
/// movement per document to do a read-modify-write.
class StockBackfillMigration {
  StockBackfillMigration({
    FirebaseFirestore? firestore,
    SharedPreferences? preferences,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _preferences = preferences;

  static const _prefKeyPrefix = 'stock_totals_backfill_v1_';

  /// Firestore caps a write batch at 500 operations.
  static const _commitChunkSize = 400;

  final FirebaseFirestore _firestore;
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  /// Runs once per factory per install; retries on the next launch if a
  /// collection failed.
  Future<StockBackfillReport> runIfNeeded(String factoryId) async {
    final prefs = await _prefs;
    final key = '$_prefKeyPrefix$factoryId';
    if (prefs.getBool(key) == true) return StockBackfillReport.empty;

    final report = await run(factoryId);
    debugPrint('StockBackfillMigration: $report');

    if (report.isComplete) {
      await prefs.setBool(key, true);
    }
    return report;
  }

  Future<StockBackfillReport> run(String factoryId) async {
    final failures = <String, String>{};

    final rawMaterials = await _backfill(
      collection: 'rawMaterials',
      factoryId: factoryId,
      legacyQuantityField: 'currentStock',
      failures: failures,
    );
    final finishedGoods = await _backfill(
      collection: 'finishedGoods',
      factoryId: factoryId,
      legacyQuantityField: 'currentQuantity',
      failures: failures,
    );

    return StockBackfillReport(
      rawMaterialsMigrated: rawMaterials,
      finishedGoodsMigrated: finishedGoods,
      failures: failures,
    );
  }

  Future<int> _backfill({
    required String collection,
    required String factoryId,
    required String legacyQuantityField,
    required Map<String, String> failures,
  }) async {
    try {
      final snapshot = await trackedCollection(_firestore, collection)
          .where('factoryId', isEqualTo: factoryId)
          .get();

      final pending = <DocumentReference<Map<String, dynamic>>,
          Map<String, dynamic>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['totalQuantity'] != null && data['totalValue'] != null) {
          continue;
        }

        final quantity = (data[legacyQuantityField] as num?)?.toDouble() ?? 0;
        final unitCost = (data['averageCost'] as num?)?.toDouble() ?? 0;
        pending[doc.reference] = {
          'totalQuantity': quantity,
          'totalValue': quantity * unitCost,
        };
      }

      // `updatedAt` is deliberately untouched: this is a schema fill, not a stock
      // movement, and nothing about the position changed.
      final entries = pending.entries.toList();
      for (var start = 0; start < entries.length; start += _commitChunkSize) {
        final chunk = entries.skip(start).take(_commitChunkSize);
        final batch = _firestore.batch();
        for (final entry in chunk) {
          batch.update(entry.key, entry.value);
        }
        await batch.commit();
      }

      return entries.length;
    } catch (error) {
      failures[collection] = error.toString();
      return 0;
    }
  }
}
