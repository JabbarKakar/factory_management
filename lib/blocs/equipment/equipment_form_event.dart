part of 'equipment_form_bloc.dart';

sealed class EquipmentFormEvent extends Equatable {
  const EquipmentFormEvent();

  @override
  List<Object?> get props => [];
}

final class EquipmentFormInitialized extends EquipmentFormEvent {
  const EquipmentFormInitialized({required this.factoryId});

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

final class EquipmentFormLoadRequested extends EquipmentFormEvent {
  const EquipmentFormLoadRequested(this.equipmentId);

  final String equipmentId;

  @override
  List<Object?> get props => [equipmentId];
}

final class EquipmentFormSubmitted extends EquipmentFormEvent {
  const EquipmentFormSubmitted(this.equipment);

  final Equipment equipment;

  @override
  List<Object?> get props => [equipment];
}

final class EquipmentFormDeleteRequested extends EquipmentFormEvent {
  const EquipmentFormDeleteRequested(this.equipmentId);

  final String equipmentId;

  @override
  List<Object?> get props => [equipmentId];
}
