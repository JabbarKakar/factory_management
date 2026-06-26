import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/raw_material.dart';
import '../../domain/enums/raw_material_enums.dart';

class RawMaterialModel {
  const RawMaterialModel({
    required this.id,
    required this.factoryId,
    required this.materialType,
    required this.currentStock,
    required this.reorderLevel,
    required this.averageCost,
    required this.createdAt,
    this.lastReceiptDate,
    this.updatedAt,
  });

  final String id;
  final String factoryId;
  final RawMaterialType materialType;
  final double currentStock;
  final double reorderLevel;
  final double averageCost;
  final DateTime? lastReceiptDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory RawMaterialModel.fromFirestore(String id, Map<String, dynamic> data) {
    return RawMaterialModel(
      id: id,
      factoryId: data['factoryId'] as String? ?? 'default',
      materialType:
          RawMaterialType.fromString(data['materialType'] as String?),
      currentStock: (data['currentStock'] as num?)?.toDouble() ?? 0,
      reorderLevel: (data['reorderLevel'] as num?)?.toDouble() ?? 0,
      averageCost: (data['averageCost'] as num?)?.toDouble() ?? 0,
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
      'currentStock': currentStock,
      'reorderLevel': reorderLevel,
      'averageCost': averageCost,
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
        currentStock: currentStock,
        reorderLevel: reorderLevel,
        averageCost: averageCost,
        lastReceiptDate: lastReceiptDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory RawMaterialModel.fromEntity(RawMaterial material) =>
      RawMaterialModel(
        id: material.id,
        factoryId: material.factoryId,
        materialType: material.materialType,
        currentStock: material.currentStock,
        reorderLevel: material.reorderLevel,
        averageCost: material.averageCost,
        lastReceiptDate: material.lastReceiptDate,
        createdAt: material.createdAt,
        updatedAt: material.updatedAt,
      );
}
