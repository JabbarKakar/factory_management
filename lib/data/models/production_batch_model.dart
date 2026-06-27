import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/production_batch.dart';
import '../../domain/enums/production_enums.dart';
import '../../domain/enums/raw_material_enums.dart';

class ProductionBatchModel {
  const ProductionBatchModel({
    required this.id,
    required this.batchNumber,
    required this.factoryId,
    required this.productionDate,
    required this.shift,
    required this.rawMaterialType,
    required this.rawMaterialId,
    required this.materialConsumed,
    required this.productType,
    required this.marbleVariety,
    required this.gradeASqFt,
    required this.gradeBSqFt,
    required this.gradeCSqFt,
    required this.rejectSqFt,
    required this.createdAt,
    this.thickness,
    this.size,
    this.wasteTons,
    this.supervisorName,
    this.notes,
    this.stockTransactionId,
    this.materialCost,
    this.updatedAt,
  });

  final String id;
  final String batchNumber;
  final String factoryId;
  final DateTime productionDate;
  final ProductionShift shift;
  final RawMaterialType rawMaterialType;
  final String rawMaterialId;
  final double materialConsumed;
  final ProductionProductType productType;
  final String marbleVariety;
  final String? thickness;
  final String? size;
  final double gradeASqFt;
  final double gradeBSqFt;
  final double gradeCSqFt;
  final double rejectSqFt;
  final double? wasteTons;
  final String? supervisorName;
  final String? notes;
  final String? stockTransactionId;
  final double? materialCost;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory ProductionBatchModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return ProductionBatchModel(
      id: id,
      batchNumber: data['batchNumber'] as String? ?? '',
      factoryId: data['factoryId'] as String? ?? 'default',
      productionDate:
          (data['productionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shift: ProductionShift.fromString(data['shift'] as String?),
      rawMaterialType:
          RawMaterialType.fromString(data['rawMaterialType'] as String?),
      rawMaterialId: data['rawMaterialId'] as String? ?? '',
      materialConsumed: (data['materialConsumed'] as num?)?.toDouble() ?? 0,
      productType:
          ProductionProductType.fromString(data['productType'] as String?),
      marbleVariety: data['marbleVariety'] as String? ?? '',
      thickness: data['thickness'] as String?,
      size: data['size'] as String?,
      gradeASqFt: (data['gradeASqFt'] as num?)?.toDouble() ?? 0,
      gradeBSqFt: (data['gradeBSqFt'] as num?)?.toDouble() ?? 0,
      gradeCSqFt: (data['gradeCSqFt'] as num?)?.toDouble() ?? 0,
      rejectSqFt: (data['rejectSqFt'] as num?)?.toDouble() ?? 0,
      wasteTons: (data['wasteTons'] as num?)?.toDouble(),
      supervisorName: data['supervisorName'] as String?,
      notes: data['notes'] as String?,
      stockTransactionId: data['stockTransactionId'] as String?,
      materialCost: (data['materialCost'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'batchNumber': batchNumber,
      'factoryId': factoryId,
      'productionDate': Timestamp.fromDate(productionDate),
      'shift': shift.firestoreValue,
      'rawMaterialType': rawMaterialType.firestoreValue,
      'rawMaterialId': rawMaterialId,
      'materialConsumed': materialConsumed,
      'productType': productType.firestoreValue,
      'marbleVariety': marbleVariety,
      if (thickness != null && thickness!.isNotEmpty) 'thickness': thickness,
      if (size != null && size!.isNotEmpty) 'size': size,
      'gradeASqFt': gradeASqFt,
      'gradeBSqFt': gradeBSqFt,
      'gradeCSqFt': gradeCSqFt,
      'rejectSqFt': rejectSqFt,
      if (wasteTons != null) 'wasteTons': wasteTons,
      if (supervisorName != null && supervisorName!.isNotEmpty)
        'supervisorName': supervisorName,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (stockTransactionId != null && stockTransactionId!.isNotEmpty)
        'stockTransactionId': stockTransactionId,
      if (materialCost != null) 'materialCost': materialCost,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ProductionBatch toEntity() => ProductionBatch(
        id: id,
        batchNumber: batchNumber,
        factoryId: factoryId,
        productionDate: productionDate,
        shift: shift,
        rawMaterialType: rawMaterialType,
        rawMaterialId: rawMaterialId,
        materialConsumed: materialConsumed,
        productType: productType,
        marbleVariety: marbleVariety,
        thickness: thickness,
        size: size,
        gradeASqFt: gradeASqFt,
        gradeBSqFt: gradeBSqFt,
        gradeCSqFt: gradeCSqFt,
        rejectSqFt: rejectSqFt,
        wasteTons: wasteTons,
        supervisorName: supervisorName,
        notes: notes,
        stockTransactionId: stockTransactionId,
        materialCost: materialCost,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory ProductionBatchModel.fromEntity(ProductionBatch batch) =>
      ProductionBatchModel(
        id: batch.id,
        batchNumber: batch.batchNumber,
        factoryId: batch.factoryId,
        productionDate: batch.productionDate,
        shift: batch.shift,
        rawMaterialType: batch.rawMaterialType,
        rawMaterialId: batch.rawMaterialId,
        materialConsumed: batch.materialConsumed,
        productType: batch.productType,
        marbleVariety: batch.marbleVariety,
        thickness: batch.thickness,
        size: batch.size,
        gradeASqFt: batch.gradeASqFt,
        gradeBSqFt: batch.gradeBSqFt,
        gradeCSqFt: batch.gradeCSqFt,
        rejectSqFt: batch.rejectSqFt,
        wasteTons: batch.wasteTons,
        supervisorName: batch.supervisorName,
        notes: batch.notes,
        stockTransactionId: batch.stockTransactionId,
        materialCost: batch.materialCost,
        createdAt: batch.createdAt,
        updatedAt: batch.updatedAt,
      );
}
