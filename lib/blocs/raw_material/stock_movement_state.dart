part of 'stock_movement_bloc.dart';

enum StockMovementStatus { initial, ready, saving, saved, failure }

class StockMovementState extends Equatable {
  const StockMovementState({
    this.status = StockMovementStatus.initial,
    this.factoryId,
    this.materialType,
    this.movementType,
    this.errorMessage,
  });

  final StockMovementStatus status;
  final String? factoryId;
  final RawMaterialType? materialType;
  final StockMovementType? movementType;
  final String? errorMessage;

  StockMovementState copyWith({
    StockMovementStatus? status,
    String? factoryId,
    RawMaterialType? materialType,
    StockMovementType? movementType,
    String? errorMessage,
  }) {
    return StockMovementState(
      status: status ?? this.status,
      factoryId: factoryId ?? this.factoryId,
      materialType: materialType ?? this.materialType,
      movementType: movementType ?? this.movementType,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        factoryId,
        materialType,
        movementType,
        errorMessage,
      ];
}
