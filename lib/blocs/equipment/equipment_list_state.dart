part of 'equipment_list_bloc.dart';

enum EquipmentListStatus { initial, loading, loaded, failure }

class EquipmentListState extends Equatable {
  const EquipmentListState({
    this.status = EquipmentListStatus.initial,
    this.equipment = const [],
    this.visibleEquipment = const [],
    this.searchQuery = '',
    this.filter = EquipmentListFilter.all,
    this.maintenanceOverdueCount = 0,
    this.maintenanceDueSoonCount = 0,
    this.errorMessage,
  });

  final EquipmentListStatus status;
  final List<Equipment> equipment;
  final List<Equipment> visibleEquipment;
  final String searchQuery;
  final EquipmentListFilter filter;
  final int maintenanceOverdueCount;
  final int maintenanceDueSoonCount;
  final String? errorMessage;

  EquipmentListState copyWith({
    EquipmentListStatus? status,
    List<Equipment>? equipment,
    List<Equipment>? visibleEquipment,
    String? searchQuery,
    EquipmentListFilter? filter,
    int? maintenanceOverdueCount,
    int? maintenanceDueSoonCount,
    String? errorMessage,
  }) {
    return EquipmentListState(
      status: status ?? this.status,
      equipment: equipment ?? this.equipment,
      visibleEquipment: visibleEquipment ?? this.visibleEquipment,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      maintenanceOverdueCount:
          maintenanceOverdueCount ?? this.maintenanceOverdueCount,
      maintenanceDueSoonCount:
          maintenanceDueSoonCount ?? this.maintenanceDueSoonCount,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        equipment,
        visibleEquipment,
        searchQuery,
        filter,
        maintenanceOverdueCount,
        maintenanceDueSoonCount,
        errorMessage,
      ];
}
