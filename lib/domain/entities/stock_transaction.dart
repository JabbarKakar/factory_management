import 'package:equatable/equatable.dart';

import '../enums/raw_material_enums.dart';

class StockTransaction extends Equatable {
  const StockTransaction({
    required this.id,
    required this.transactionNumber,
    required this.factoryId,
    required this.rawMaterialId,
    required this.materialType,
    required this.movementType,
    required this.quantity,
    required this.transactionDate,
    required this.createdAt,
    this.unitCost,
    this.totalCost,
    this.supplierId,
    this.referenceNumber,
    this.notes,
  });

  final String id;
  final String transactionNumber;
  final String factoryId;
  final String rawMaterialId;
  final RawMaterialType materialType;
  final StockMovementType movementType;
  final double quantity;
  final double? unitCost;
  final double? totalCost;
  final DateTime transactionDate;
  final String? supplierId;
  final String? referenceNumber;
  final String? notes;
  final DateTime createdAt;

  StockUnit get unit => materialType.unit;

  @override
  List<Object?> get props => [
        id,
        transactionNumber,
        factoryId,
        rawMaterialId,
        materialType,
        movementType,
        quantity,
        unitCost,
        totalCost,
        transactionDate,
        supplierId,
        referenceNumber,
        notes,
        createdAt,
      ];
}
