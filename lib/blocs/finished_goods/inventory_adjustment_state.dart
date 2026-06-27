part of 'inventory_adjustment_bloc.dart';

enum InventoryAdjustmentStatus { initial, ready, saving, saved, failure }

class InventoryAdjustmentState extends Equatable {
  const InventoryAdjustmentState({
    this.status = InventoryAdjustmentStatus.initial,
    this.factoryId,
    this.finishedGoodId,
    this.movementType,
    this.errorMessage,
  });

  final InventoryAdjustmentStatus status;
  final String? factoryId;
  final String? finishedGoodId;
  final InventoryMovementType? movementType;
  final String? errorMessage;

  InventoryAdjustmentState copyWith({
    InventoryAdjustmentStatus? status,
    String? factoryId,
    String? finishedGoodId,
    InventoryMovementType? movementType,
    String? errorMessage,
  }) {
    return InventoryAdjustmentState(
      status: status ?? this.status,
      factoryId: factoryId ?? this.factoryId,
      finishedGoodId: finishedGoodId ?? this.finishedGoodId,
      movementType: movementType ?? this.movementType,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        factoryId,
        finishedGoodId,
        movementType,
        errorMessage,
      ];
}
