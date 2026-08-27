import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/observability/tracked_firestore.dart';
import '../../domain/entities/dashboard_monthly_rollup.dart';
import '../models/dashboard_monthly_rollup_model.dart';

class DashboardRollupRepository {
  DashboardRollupRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      trackedCollection(_firestore, 'dashboardRollups');

  DocumentReference<Map<String, dynamic>> docFor({
    required String factoryId,
    required DateTime month,
  }) {
    return _collection.doc(DashboardRollupIds.docId(factoryId, month));
  }

  Future<void> increment({
    required String factoryId,
    required DateTime date,
    required DashboardRollupDelta delta,
  }) async {
    if (delta.isEmpty) return;
    final month = DashboardRollupIds.monthStart(date);
    await docFor(factoryId: factoryId, month: month).set(
      {
        'factoryId': factoryId,
        'yearMonth': DashboardRollupIds.yearMonth(month),
        'year': month.year,
        'month': month.month,
        if (delta.income != 0) 'income': FieldValue.increment(delta.income),
        if (delta.incomeSales != 0)
          'incomeSales': FieldValue.increment(delta.incomeSales),
        if (delta.incomeJobWork != 0)
          'incomeJobWork': FieldValue.increment(delta.incomeJobWork),
        if (delta.expenses != 0) 'expenses': FieldValue.increment(delta.expenses),
        if (delta.stockCutSmallSqFt != 0)
          'stockCutSmallSqFt': FieldValue.increment(delta.stockCutSmallSqFt),
        if (delta.stockCutLargeSqFt != 0)
          'stockCutLargeSqFt': FieldValue.increment(delta.stockCutLargeSqFt),
        if (delta.stockCutSmallAmount != 0)
          'stockCutSmallAmount': FieldValue.increment(delta.stockCutSmallAmount),
        if (delta.stockCutLargeAmount != 0)
          'stockCutLargeAmount': FieldValue.increment(delta.stockCutLargeAmount),
        if (delta.salesSmallSqFt != 0)
          'salesSmallSqFt': FieldValue.increment(delta.salesSmallSqFt),
        if (delta.salesLargeSqFt != 0)
          'salesLargeSqFt': FieldValue.increment(delta.salesLargeSqFt),
        if (delta.salesSmallAmount != 0)
          'salesSmallAmount': FieldValue.increment(delta.salesSmallAmount),
        if (delta.salesLargeAmount != 0)
          'salesLargeAmount': FieldValue.increment(delta.salesLargeAmount),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> replaceMonth(DashboardMonthlyRollup rollup) async {
    await _collection.doc(rollup.id).set({
      ...DashboardMonthlyRollupModel(rollup: rollup).toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<DashboardMonthlyRollup>> getRange({
    required String factoryId,
    required DateTime from,
    required DateTime to,
  }) async {
    final months = <DateTime>[];
    var cursor = DashboardRollupIds.monthStart(from);
    final last = DashboardRollupIds.monthStart(to);
    while (!cursor.isAfter(last)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    final snapshots = await Future.wait(
      months.map(
        (month) => docFor(factoryId: factoryId, month: month).get(),
      ),
    );

    return snapshots
        .where((snapshot) => snapshot.exists && snapshot.data() != null)
        .map(
          (snapshot) => DashboardMonthlyRollupModel.fromFirestore(
            snapshot.id,
            snapshot.data()!,
          ).toEntity(),
        )
        .toList();
  }
}
