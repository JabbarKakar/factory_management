part of 'equipment_form_bloc.dart';

enum EquipmentFormStatus {
  initial,
  loading,
  ready,
  saving,
  saved,
  deleted,
  failure,
}

class EquipmentFormState extends Equatable {
  const EquipmentFormState({
    this.status = EquipmentFormStatus.initial,
    this.equipment,
    this.errorMessage,
    this.isEditing = false,
  });

  final EquipmentFormStatus status;
  final Equipment? equipment;
  final String? errorMessage;
  final bool isEditing;

  EquipmentFormState copyWith({
    EquipmentFormStatus? status,
    Equipment? equipment,
    String? errorMessage,
    bool? isEditing,
  }) {
    return EquipmentFormState(
      status: status ?? this.status,
      equipment: equipment ?? this.equipment,
      errorMessage: errorMessage,
      isEditing: isEditing ?? this.isEditing,
    );
  }

  @override
  List<Object?> get props => [status, equipment, errorMessage, isEditing];
}
