part of 'raw_material_adjustment_bloc.dart';

abstract class RawMaterialAdjustmentEvent extends Equatable {
  const RawMaterialAdjustmentEvent();

  @override
  List<Object?> get props => [];
}

class RawMaterialAdjustmentInitialized extends RawMaterialAdjustmentEvent {
  const RawMaterialAdjustmentInitialized({
    required this.factoryId,
    required this.materialType,
    required this.movementType,
  });

  final String factoryId;
  final RawMaterialType materialType;
  final StockMovementType movementType;

  @override
  List<Object?> get props => [factoryId, materialType, movementType];
}

class RawMaterialAdjustmentSubmitted extends RawMaterialAdjustmentEvent {
  const RawMaterialAdjustmentSubmitted({
    required this.quantity,
    required this.transactionDate,
    required this.reason,
    this.unitCost,
    this.notes,
  });

  final double quantity;
  final DateTime transactionDate;
  final String reason;
  final double? unitCost;
  final String? notes;

  @override
  List<Object?> get props => [quantity, transactionDate, reason, unitCost, notes];
}
