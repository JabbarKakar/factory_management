part of 'raw_material_adjustment_bloc.dart';

enum RawMaterialAdjustmentStatus {
  initial,
  ready,
  saving,
  saved,
  failure,
}

class RawMaterialAdjustmentState extends Equatable {
  const RawMaterialAdjustmentState({
    this.status = RawMaterialAdjustmentStatus.initial,
    this.factoryId,
    this.materialType,
    this.movementType,
    this.errorMessage,
  });

  final RawMaterialAdjustmentStatus status;
  final String? factoryId;
  final RawMaterialType? materialType;
  final StockMovementType? movementType;
  final String? errorMessage;

  RawMaterialAdjustmentState copyWith({
    RawMaterialAdjustmentStatus? status,
    String? factoryId,
    RawMaterialType? materialType,
    StockMovementType? movementType,
    String? errorMessage,
  }) {
    return RawMaterialAdjustmentState(
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
