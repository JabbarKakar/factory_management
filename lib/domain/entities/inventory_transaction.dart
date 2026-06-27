import 'package:equatable/equatable.dart';

import '../enums/inventory_enums.dart';

class InventoryTransaction extends Equatable {
  const InventoryTransaction({
    required this.id,
    required this.transactionNumber,
    required this.factoryId,
    required this.finishedGoodId,
    required this.movementType,
    required this.quantity,
    required this.transactionDate,
    required this.createdAt,
    this.unitCost,
    this.totalCost,
    this.productionBatchId,
    this.productionBatchNumber,
    this.reason,
    this.notes,
  });

  final String id;
  final String transactionNumber;
  final String factoryId;
  final String finishedGoodId;
  final InventoryMovementType movementType;
  final double quantity;
  final double? unitCost;
  final double? totalCost;
  final DateTime transactionDate;
  final String? productionBatchId;
  final String? productionBatchNumber;
  final String? reason;
  final String? notes;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        transactionNumber,
        factoryId,
        finishedGoodId,
        movementType,
        quantity,
        unitCost,
        totalCost,
        transactionDate,
        productionBatchId,
        productionBatchNumber,
        reason,
        notes,
        createdAt,
      ];
}
