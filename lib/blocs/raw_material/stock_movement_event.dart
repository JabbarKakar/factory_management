part of 'stock_movement_bloc.dart';

sealed class StockMovementEvent extends Equatable {
  const StockMovementEvent();

  @override
  List<Object?> get props => [];
}

final class StockMovementInitialized extends StockMovementEvent {
  const StockMovementInitialized({
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

final class StockMovementSubmitted extends StockMovementEvent {
  const StockMovementSubmitted({
    required this.quantity,
    required this.transactionDate,
    this.unitCost,
    this.supplierId,
    this.referenceNumber,
    this.notes,
  });

  final double quantity;
  final double? unitCost;
  final DateTime transactionDate;
  final String? supplierId;
  final String? referenceNumber;
  final String? notes;

  @override
  List<Object?> get props => [
        quantity,
        unitCost,
        transactionDate,
        supplierId,
        referenceNumber,
        notes,
      ];
}
