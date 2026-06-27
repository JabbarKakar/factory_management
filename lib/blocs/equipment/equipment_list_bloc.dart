import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/equipment_repository.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/enums/equipment_enums.dart';

part 'equipment_list_event.dart';
part 'equipment_list_state.dart';

class EquipmentListBloc extends Bloc<EquipmentListEvent, EquipmentListState> {
  EquipmentListBloc({required EquipmentRepository repository})
      : _repository = repository,
        super(const EquipmentListState()) {
    on<EquipmentListWatchStarted>(_onWatchStarted);
    on<EquipmentListWatchStopped>(_onWatchStopped);
    on<EquipmentListSearchChanged>(_onSearchChanged);
    on<EquipmentListFilterChanged>(_onFilterChanged);
    on<_EquipmentListUpdated>(_onListUpdated);
    on<_EquipmentListStreamFailed>(_onStreamFailed);
  }

  final EquipmentRepository _repository;
  StreamSubscription<List<Equipment>>? _subscription;

  Future<void> _onWatchStarted(
    EquipmentListWatchStarted event,
    Emitter<EquipmentListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: EquipmentListStatus.loading,
        filter: event.initialFilter ?? state.filter,
      ),
    );
    await _subscription?.cancel();
    _subscription = _repository.watchEquipment(event.factoryId).listen(
          (equipment) => add(_EquipmentListUpdated(equipment)),
          onError: (_) => add(
            const _EquipmentListStreamFailed(
              'Could not load equipment. Please try again.',
            ),
          ),
        );
  }

  Future<void> _onWatchStopped(
    EquipmentListWatchStopped event,
    Emitter<EquipmentListState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _onSearchChanged(
    EquipmentListSearchChanged event,
    Emitter<EquipmentListState> emit,
  ) {
    emit(
      state.copyWith(
        searchQuery: event.query,
        visibleEquipment: _applyFilters(
          state.equipment,
          query: event.query,
          filter: state.filter,
        ),
      ),
    );
  }

  void _onFilterChanged(
    EquipmentListFilterChanged event,
    Emitter<EquipmentListState> emit,
  ) {
    emit(
      state.copyWith(
        filter: event.filter,
        visibleEquipment: _applyFilters(
          state.equipment,
          query: state.searchQuery,
          filter: event.filter,
        ),
      ),
    );
  }

  void _onListUpdated(
    _EquipmentListUpdated event,
    Emitter<EquipmentListState> emit,
  ) {
    final today = DateTime.now();
    final overdueCount = event.equipment
        .where((item) => item.isMaintenanceOverdue(today: today))
        .length;
    final dueSoonCount = event.equipment
        .where((item) => item.isMaintenanceDueSoon(today: today))
        .length;

    emit(
      state.copyWith(
        status: EquipmentListStatus.loaded,
        equipment: event.equipment,
        visibleEquipment: _applyFilters(
          event.equipment,
          query: state.searchQuery,
          filter: state.filter,
        ),
        maintenanceOverdueCount: overdueCount,
        maintenanceDueSoonCount: dueSoonCount,
        errorMessage: null,
      ),
    );
  }

  void _onStreamFailed(
    _EquipmentListStreamFailed event,
    Emitter<EquipmentListState> emit,
  ) {
    emit(
      state.copyWith(
        status: EquipmentListStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  List<Equipment> _applyFilters(
    List<Equipment> equipment, {
    required String query,
    required EquipmentListFilter filter,
  }) {
    final today = DateTime.now();
    final normalizedQuery = query.trim().toLowerCase();

    return equipment.where((item) {
      if (!filter.matches(
        status: item.status,
        nextMaintenanceDueDate: item.nextMaintenanceDueDate,
        today: DateTime(today.year, today.month, today.day),
      )) {
        return false;
      }

      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        item.name,
        item.equipmentNumber,
        item.brand,
        item.model,
        item.serialNumber,
        item.location,
        item.supplierName,
        item.category.label,
        item.status.label,
      ].whereType<String>().join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

final class _EquipmentListUpdated extends EquipmentListEvent {
  const _EquipmentListUpdated(this.equipment);

  final List<Equipment> equipment;

  @override
  List<Object?> get props => [equipment];
}

final class _EquipmentListStreamFailed extends EquipmentListEvent {
  const _EquipmentListStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
