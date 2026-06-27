part of 'equipment_detail_bloc.dart';

sealed class EquipmentDetailEvent extends Equatable {
  const EquipmentDetailEvent();

  @override
  List<Object?> get props => [];
}

final class EquipmentDetailWatchStarted extends EquipmentDetailEvent {
  const EquipmentDetailWatchStarted(this.equipmentId);

  final String equipmentId;

  @override
  List<Object?> get props => [equipmentId];
}

final class EquipmentDetailWatchStopped extends EquipmentDetailEvent {
  const EquipmentDetailWatchStopped();
}
