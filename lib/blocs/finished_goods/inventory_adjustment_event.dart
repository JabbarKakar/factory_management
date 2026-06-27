part of 'inventory_adjustment_bloc.dart';

abstract class InventoryAdjustmentEvent extends Equatable {
  const InventoryAdjustmentEvent();

  @override
  List<Object?> get props => [];
}

class InventoryAdjustmentInitialized extends InventoryAdjustmentEvent {
  const InventoryAdjustmentInitialized({
    required this.factoryId,
    required this.finishedGoodId,
    required this.movementType,
  });

  final String factoryId;
  final String finishedGoodId;
  final InventoryMovementType movementType;

  @override
  List<Object?> get props => [factoryId, finishedGoodId, movementType];
}

class InventoryAdjustmentSubmitted extends InventoryAdjustmentEvent {
  const InventoryAdjustmentSubmitted({
    required this.quantity,
    required this.transactionDate,
    required this.reason,
    this.notes,
  });

  final double quantity;
  final DateTime transactionDate;
  final String reason;
  final String? notes;

  @override
  List<Object?> get props => [quantity, transactionDate, reason, notes];
}
