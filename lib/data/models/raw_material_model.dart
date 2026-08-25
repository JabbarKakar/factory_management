import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/raw_material.dart';
import '../../domain/enums/raw_material_enums.dart';

class RawMaterialModel {
  const RawMaterialModel({
    required this.id,
    required this.factoryId,
    required this.materialType,
    required this.totalQuantity,
    required this.totalValue,
    required this.reorderLevel,
    required this.createdAt,
    this.lastUnitCost = 0,
    this.hasStoredTotals = true,
    this.lastReceiptDate,
    this.updatedAt,
  });

  final String id;
  final String factoryId;
  final RawMaterialType materialType;
  final double totalQuantity;
  final double totalValue;
  final double lastUnitCost;

  /// False when the document still only has the pre-S38 fields, so the totals
  /// above were derived rather than read. Movement writes must seed the totals as
  /// literals in that case — see [buildStockMovementPayload].
  final bool hasStoredTotals;

  final double reorderLevel;
  final DateTime? lastReceiptDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  double get averageCost =>
      totalQuantity > 0 ? totalValue / totalQuantity : lastUnitCost;

  factory RawMaterialModel.fromFirestore(String id, Map<String, dynamic> data) {
    // Documents written before S38 only carry currentStock/averageCost. Deriving
    // the totals from them here means the app reads correctly whether or not the
    // backfill has run yet.
    final legacyQuantity = (data['currentStock'] as num?)?.toDouble() ?? 0;
    final legacyUnitCost = (data['averageCost'] as num?)?.toDouble() ?? 0;
    final storedQuantity = (data['totalQuantity'] as num?)?.toDouble();
    final storedValue = (data['totalValue'] as num?)?.toDouble();

    return RawMaterialModel(
      id: id,
      factoryId: data['factoryId'] as String? ?? 'default',
      materialType:
          RawMaterialType.fromString(data['materialType'] as String?),
      totalQuantity: storedQuantity ?? legacyQuantity,
      totalValue: storedValue ?? legacyQuantity * legacyUnitCost,
      lastUnitCost: legacyUnitCost,
      hasStoredTotals: storedQuantity != null && storedValue != null,
      reorderLevel: (data['reorderLevel'] as num?)?.toDouble() ?? 0,
      lastReceiptDate:
          (data['lastReceiptDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'factoryId': factoryId,
      'materialType': materialType.firestoreValue,
      'totalQuantity': totalQuantity,
      'totalValue': totalValue,
      // Legacy mirrors, kept during the deprecation window so an older build (or
      // an export) still reads a sensible stock position. Authoritative values
      // are totalQuantity/totalValue.
      'currentStock': totalQuantity,
      'averageCost': averageCost,
      'reorderLevel': reorderLevel,
      if (lastReceiptDate != null)
        'lastReceiptDate': Timestamp.fromDate(lastReceiptDate!),
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  RawMaterial toEntity() => RawMaterial(
        id: id,
        factoryId: factoryId,
        materialType: materialType,
        totalQuantity: totalQuantity,
        totalValue: totalValue,
        lastUnitCost: lastUnitCost,
        reorderLevel: reorderLevel,
        lastReceiptDate: lastReceiptDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory RawMaterialModel.fromEntity(RawMaterial material) =>
      RawMaterialModel(
        id: material.id,
        factoryId: material.factoryId,
        materialType: material.materialType,
        totalQuantity: material.totalQuantity,
        totalValue: material.totalValue,
        lastUnitCost: material.lastUnitCost,
        reorderLevel: material.reorderLevel,
        lastReceiptDate: material.lastReceiptDate,
        createdAt: material.createdAt,
        updatedAt: material.updatedAt,
      );
}
