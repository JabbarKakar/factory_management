part of 'raw_material_detail_bloc.dart';

sealed class RawMaterialDetailEvent extends Equatable {
  const RawMaterialDetailEvent();

  @override
  List<Object?> get props => [];
}

final class RawMaterialDetailWatchStarted extends RawMaterialDetailEvent {
  const RawMaterialDetailWatchStarted({
    required this.factoryId,
    required this.materialType,
  });

  final String factoryId;
  final RawMaterialType materialType;

  @override
  List<Object?> get props => [factoryId, materialType];
}

final class RawMaterialDetailWatchStopped extends RawMaterialDetailEvent {
  const RawMaterialDetailWatchStopped();
}

final class RawMaterialReorderLevelUpdated extends RawMaterialDetailEvent {
  const RawMaterialReorderLevelUpdated(this.reorderLevel);

  final double reorderLevel;

  @override
  List<Object?> get props => [reorderLevel];
}
