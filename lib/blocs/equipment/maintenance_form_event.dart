part of 'maintenance_form_bloc.dart';

sealed class MaintenanceFormEvent extends Equatable {
  const MaintenanceFormEvent();

  @override
  List<Object?> get props => [];
}

final class MaintenanceFormInitialized extends MaintenanceFormEvent {
  const MaintenanceFormInitialized(this.equipmentId);

  final String equipmentId;

  @override
  List<Object?> get props => [equipmentId];
}

final class MaintenanceFormSubmitted extends MaintenanceFormEvent {
  const MaintenanceFormSubmitted(this.log);

  final MaintenanceLog log;

  @override
  List<Object?> get props => [log];
}
