import 'package:equatable/equatable.dart';

import '../enums/production_enums.dart';
import '../enums/raw_material_enums.dart';

class ProductionBatch extends Equatable {
  const ProductionBatch({
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

  StockUnit get materialUnit => rawMaterialType.unit;

  double get totalUsableSqFt => gradeASqFt + gradeBSqFt + gradeCSqFt;

  double get totalOutputSqFt => totalUsableSqFt + rejectSqFt;

  @override
  List<Object?> get props => [
        id,
        batchNumber,
        factoryId,
        productionDate,
        shift,
        rawMaterialType,
        rawMaterialId,
        materialConsumed,
        productType,
        marbleVariety,
        thickness,
        size,
        gradeASqFt,
        gradeBSqFt,
        gradeCSqFt,
        rejectSqFt,
        wasteTons,
        supervisorName,
        notes,
        stockTransactionId,
        materialCost,
        createdAt,
        updatedAt,
      ];
}
