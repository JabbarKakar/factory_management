part of 'equipment_list_bloc.dart';

sealed class EquipmentListEvent extends Equatable {
  const EquipmentListEvent();

  @override
  List<Object?> get props => [];
}

final class EquipmentListWatchStarted extends EquipmentListEvent {
  const EquipmentListWatchStarted(this.factoryId, {this.initialFilter});

  final String factoryId;
  final EquipmentListFilter? initialFilter;

  @override
  List<Object?> get props => [factoryId, initialFilter];
}

final class EquipmentListWatchStopped extends EquipmentListEvent {
  const EquipmentListWatchStopped();
}

final class EquipmentListSearchChanged extends EquipmentListEvent {
  const EquipmentListSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class EquipmentListFilterChanged extends EquipmentListEvent {
  const EquipmentListFilterChanged(this.filter);

  final EquipmentListFilter filter;

  @override
  List<Object?> get props => [filter];
}
