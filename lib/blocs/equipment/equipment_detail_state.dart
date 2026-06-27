part of 'equipment_detail_bloc.dart';

enum EquipmentDetailStatus { initial, loading, loaded, failure }

class EquipmentDetailState extends Equatable {
  const EquipmentDetailState({
    this.status = EquipmentDetailStatus.initial,
    this.equipment,
    this.maintenanceLogs = const [],
    this.errorMessage,
  });

  final EquipmentDetailStatus status;
  final Equipment? equipment;
  final List<MaintenanceLog> maintenanceLogs;
  final String? errorMessage;

  EquipmentDetailState copyWith({
    EquipmentDetailStatus? status,
    Equipment? equipment,
    List<MaintenanceLog>? maintenanceLogs,
    String? errorMessage,
  }) {
    return EquipmentDetailState(
      status: status ?? this.status,
      equipment: equipment ?? this.equipment,
      maintenanceLogs: maintenanceLogs ?? this.maintenanceLogs,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, equipment, maintenanceLogs, errorMessage];
}
