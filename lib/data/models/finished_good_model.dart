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
    required this.currentQuantity,
    required this.reorderLevel,
    required this.averageCost,
    required this.createdAt,
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
  final double currentQuantity;
  final double reorderLevel;
  final double averageCost;
  final String? location;
  final DateTime? lastReceiptDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory FinishedGoodModel.fromFirestore(String id, Map<String, dynamic> data) {
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
      currentQuantity: (data['currentQuantity'] as num?)?.toDouble() ?? 0,
      reorderLevel: (data['reorderLevel'] as num?)?.toDouble() ?? 0,
      averageCost: (data['averageCost'] as num?)?.toDouble() ?? 0,
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
      'currentQuantity': currentQuantity,
      'reorderLevel': reorderLevel,
      'averageCost': averageCost,
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
        currentQuantity: currentQuantity,
        reorderLevel: reorderLevel,
        averageCost: averageCost,
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
        currentQuantity: item.currentQuantity,
        reorderLevel: item.reorderLevel,
        averageCost: item.averageCost,
        location: item.location,
        lastReceiptDate: item.lastReceiptDate,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      );
}
