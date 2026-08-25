import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/finished_good.dart';
import '../../domain/enums/inventory_enums.dart';
import '../../domain/enums/production_enums.dart';

class FinishedGoodModel {
  const FinishedGoodModel({
    required this.id,
    required this.factoryId,
    required this.skuKey,
    required this.productType,
    required this.marbleVariety,
    required this.grade,
    required this.totalQuantity,
    required this.totalValue,
    required this.reorderLevel,
    required this.createdAt,
    this.lastUnitCost = 0,
    this.hasStoredTotals = true,
    this.size,
    this.thickness,
    this.location,
    this.lastReceiptDate,
    this.updatedAt,
  });

  final String id;
  final String factoryId;
  final String skuKey;
  final ProductionProductType productType;
  final String marbleVariety;
  final String? size;
  final String? thickness;
  final FinishedGoodGrade grade;
  final double totalQuantity;
  final double totalValue;
  final double lastUnitCost;

  /// False when the document still only has the pre-S38 fields. See
  /// [RawMaterialModel.hasStoredTotals].
  final bool hasStoredTotals;

  final double reorderLevel;
  final String? location;
  final DateTime? lastReceiptDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  double get averageCost =>
      totalQuantity > 0 ? totalValue / totalQuantity : lastUnitCost;

  factory FinishedGoodModel.fromFirestore(String id, Map<String, dynamic> data) {
    // See RawMaterialModel.fromFirestore: pre-S38 documents only carry
    // currentQuantity/averageCost, so the totals are derived when absent.
    final legacyQuantity = (data['currentQuantity'] as num?)?.toDouble() ?? 0;
    final legacyUnitCost = (data['averageCost'] as num?)?.toDouble() ?? 0;
    final storedQuantity = (data['totalQuantity'] as num?)?.toDouble();
    final storedValue = (data['totalValue'] as num?)?.toDouble();

    return FinishedGoodModel(
      id: id,
      factoryId: data['factoryId'] as String? ?? 'default',
      skuKey: data['skuKey'] as String? ?? '',
      productType:
          ProductionProductType.fromString(data['productType'] as String?),
      marbleVariety: data['marbleVariety'] as String? ?? '',
      size: data['size'] as String?,
      thickness: data['thickness'] as String?,
      grade: FinishedGoodGrade.fromString(data['grade'] as String?),
      totalQuantity: storedQuantity ?? legacyQuantity,
      totalValue: storedValue ?? legacyQuantity * legacyUnitCost,
      lastUnitCost: legacyUnitCost,
      hasStoredTotals: storedQuantity != null && storedValue != null,
      reorderLevel: (data['reorderLevel'] as num?)?.toDouble() ?? 0,
      location: data['location'] as String?,
      lastReceiptDate:
          (data['lastReceiptDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'factoryId': factoryId,
      'skuKey': skuKey,
      'productType': productType.firestoreValue,
      'marbleVariety': marbleVariety,
      if (size != null && size!.isNotEmpty) 'size': size,
      if (thickness != null && thickness!.isNotEmpty) 'thickness': thickness,
      'grade': grade.firestoreValue,
      'totalQuantity': totalQuantity,
      'totalValue': totalValue,
      // Legacy mirrors — see RawMaterialModel.toFirestore.
      'currentQuantity': totalQuantity,
      'averageCost': averageCost,
      'reorderLevel': reorderLevel,
      if (location != null && location!.isNotEmpty) 'location': location,
      if (lastReceiptDate != null)
        'lastReceiptDate': Timestamp.fromDate(lastReceiptDate!),
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  FinishedGood toEntity() => FinishedGood(
        id: id,
        factoryId: factoryId,
        skuKey: skuKey,
        productType: productType,
        marbleVariety: marbleVariety,
        size: size,
        thickness: thickness,
        grade: grade,
        totalQuantity: totalQuantity,
        totalValue: totalValue,
        lastUnitCost: lastUnitCost,
        reorderLevel: reorderLevel,
        location: location,
        lastReceiptDate: lastReceiptDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory FinishedGoodModel.fromEntity(FinishedGood item) => FinishedGoodModel(
        id: item.id,
        factoryId: item.factoryId,
        skuKey: item.skuKey,
        productType: item.productType,
        marbleVariety: item.marbleVariety,
        size: item.size,
        thickness: item.thickness,
        grade: item.grade,
        totalQuantity: item.totalQuantity,
        totalValue: item.totalValue,
        lastUnitCost: item.lastUnitCost,
        reorderLevel: item.reorderLevel,
        location: item.location,
        lastReceiptDate: item.lastReceiptDate,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      );
}
