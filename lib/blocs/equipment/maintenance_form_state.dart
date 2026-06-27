part of 'maintenance_form_bloc.dart';

enum MaintenanceFormStatus {
  initial,
  loading,
  ready,
  saving,
  saved,
  failure,
}

class MaintenanceFormState extends Equatable {
  const MaintenanceFormState({
    this.status = MaintenanceFormStatus.initial,
    this.equipment,
    this.errorMessage,
  });

  final MaintenanceFormStatus status;
  final Equipment? equipment;
  final String? errorMessage;

  MaintenanceFormState copyWith({
    MaintenanceFormStatus? status,
    Equipment? equipment,
    String? errorMessage,
  }) {
    return MaintenanceFormState(
      status: status ?? this.status,
      equipment: equipment ?? this.equipment,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, equipment, errorMessage];
}
