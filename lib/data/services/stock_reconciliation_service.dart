import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/observability/tracked_firestore.dart';
import '../../domain/enums/inventory_enums.dart';
import '../../domain/enums/raw_material_enums.dart';
import '../models/finished_good_model.dart';
import '../models/raw_material_model.dart';

/// One stock position, with its recorded level next to the level its own
/// movement history implies.
@immutable
class StockReconciliationRow {
  const StockReconciliationRow({
    required this.id,
    required this.label,
    required this.unitLabel,
    required this.recordedQuantity,
    required this.ledgerQuantity,
    required this.movementCount,
    required this.recordedValue,
    required this.unitCost,
    required this.hasStoredTotals,
  });

  final String id;
  final String label;
  final String unitLabel;

  /// `totalQuantity` as held on the stock document.
  final double recordedQuantity;

  /// Signed sum of every movement recorded against this position.
  final double ledgerQuantity;

  final int movementCount;
  final double recordedValue;
  final double unitCost;

  /// False while the document still predates S38.
  final bool hasStoredTotals;

  double get drift => recordedQuantity - ledgerQuantity;

  bool get isBalanced => drift.abs() <= 0.01;

  /// A position with no movements at all cannot be reconciled — it was seeded or
  /// imported as an opening balance, so drift is expected rather than a fault.
  bool get isUnattributable => movementCount == 0 && recordedQuantity != 0;
}

@immutable
class StockReconciliationReport {
  const StockReconciliationReport({
    required this.rawMaterials,
    required this.finishedGoods,
    required this.generatedAt,
  });

  final List<StockReconciliationRow> rawMaterials;
  final List<StockReconciliationRow> finishedGoods;
  final DateTime generatedAt;

  List<StockReconciliationRow> get all => [...rawMaterials, ...finishedGoods];

  List<StockReconciliationRow> get drifting => all
      .where((row) => !row.isBalanced && !row.isUnattributable)
      .toList();

  List<StockReconciliationRow> get unmigrated =>
      all.where((row) => !row.hasStoredTotals).toList();

  int get openingBalanceCount => all.where((row) => row.isUnattributable).length;
}

/// Recomputes every stock level from its movement history so drift is visible and
/// attributable.
///
/// This reads whole collections on purpose — it is a diagnostic, not something to
/// put on a hot path.
class StockReconciliationService {
  StockReconciliationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<StockReconciliationReport> run(String factoryId) async {
    final materials = await trackedCollection(_firestore, 'rawMaterials')
        .where('factoryId', isEqualTo: factoryId)
        .get();
    final stockMovements = await trackedCollection(
      _firestore,
      'stockTransactions',
    ).where('factoryId', isEqualTo: factoryId).get();
    final goods = await trackedCollection(_firestore, 'finishedGoods')
        .where('factoryId', isEqualTo: factoryId)
        .get();
    final inventoryMovements = await trackedCollection(
      _firestore,
      'inventoryTransactions',
    ).where('factoryId', isEqualTo: factoryId).get();

    final materialLedger = _ledger(
      docs: stockMovements.docs,
      ownerField: 'rawMaterialId',
      isInbound: (data) =>
          StockMovementType.fromString(data['movementType'] as String?)
              .isInbound,
    );
    final goodsLedger = _ledger(
      docs: inventoryMovements.docs,
      ownerField: 'finishedGoodId',
      isInbound: (data) =>
          InventoryMovementType.fromString(data['movementType'] as String?)
              .isInbound,
    );

    final materialRows = materials.docs.map((doc) {
      final model = RawMaterialModel.fromFirestore(doc.id, doc.data());
      final ledger = materialLedger[doc.id];
      return StockReconciliationRow(
        id: doc.id,
        label: model.materialType.label,
        unitLabel: model.materialType.unit.label,
        recordedQuantity: model.totalQuantity,
        ledgerQuantity: ledger?.quantity ?? 0,
        movementCount: ledger?.count ?? 0,
        recordedValue: model.totalValue,
        unitCost: model.averageCost,
        hasStoredTotals: model.hasStoredTotals,
      );
    }).toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    final goodsRows = goods.docs.map((doc) {
      final model = FinishedGoodModel.fromFirestore(doc.id, doc.data());
      final ledger = goodsLedger[doc.id];
      return StockReconciliationRow(
        id: doc.id,
        label: model.toEntity().displaySubtitle,
        unitLabel: 'sq. ft',
        recordedQuantity: model.totalQuantity,
        ledgerQuantity: ledger?.quantity ?? 0,
        movementCount: ledger?.count ?? 0,
        recordedValue: model.totalValue,
        unitCost: model.averageCost,
        hasStoredTotals: model.hasStoredTotals,
      );
    }).toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    return StockReconciliationReport(
      rawMaterials: materialRows,
      finishedGoods: goodsRows,
      generatedAt: DateTime.now(),
    );
  }

  Map<String, ({double quantity, int count})> _ledger({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required String ownerField,
    required bool Function(Map<String, dynamic> data) isInbound,
  }) {
    final ledger = <String, ({double quantity, int count})>{};

    for (final doc in docs) {
      final data = doc.data();
      final ownerId = data[ownerField] as String?;
      if (ownerId == null || ownerId.isEmpty) continue;

      final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;
      final signed = isInbound(data) ? quantity : -quantity;
      final current = ledger[ownerId];
      ledger[ownerId] = (
        quantity: (current?.quantity ?? 0) + signed,
        count: (current?.count ?? 0) + 1,
      );
    }

    return ledger;
  }
}
