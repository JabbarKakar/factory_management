import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/raw_material_repository.dart';
import '../../domain/entities/raw_material.dart';
import '../../domain/enums/raw_material_enums.dart';

part 'raw_material_list_event.dart';
part 'raw_material_list_state.dart';

class RawMaterialListBloc extends Bloc<RawMaterialListEvent, RawMaterialListState> {
  RawMaterialListBloc({required RawMaterialRepository repository})
      : _repository = repository,
        super(const RawMaterialListState()) {
    on<RawMaterialListWatchStarted>(_onWatchStarted);
    on<RawMaterialListWatchStopped>(_onWatchStopped);
    on<RawMaterialListSearchChanged>(_onSearchChanged);
    on<RawMaterialListFilterChanged>(_onFilterChanged);
    on<_RawMaterialListUpdated>(_onListUpdated);
    on<_RawMaterialListStreamFailed>(_onStreamFailed);
  }

  final RawMaterialRepository _repository;
  StreamSubscription<List<RawMaterial>>? _subscription;
  String? _factoryId;

  Future<void> _onWatchStarted(
    RawMaterialListWatchStarted event,
    Emitter<RawMaterialListState> emit,
  ) async {
    _factoryId = event.factoryId;
    emit(state.copyWith(status: RawMaterialListStatus.loading));
    await _subscription?.cancel();
    _subscription = _repository.watchMaterials(event.factoryId).listen(
          (materials) => add(_RawMaterialListUpdated(materials)),
          onError: (_) => add(
            const _RawMaterialListStreamFailed(
              'Could not load raw material stock.',
            ),
          ),
        );
  }

  Future<void> _onWatchStopped(
    RawMaterialListWatchStopped event,
    Emitter<RawMaterialListState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _onSearchChanged(
    RawMaterialListSearchChanged event,
    Emitter<RawMaterialListState> emit,
  ) {
    final visible = _applyFilters(
      state.materials,
      query: event.query,
      filter: state.filter,
    );
    emit(state.copyWith(searchQuery: event.query, visibleMaterials: visible));
  }

  void _onFilterChanged(
    RawMaterialListFilterChanged event,
    Emitter<RawMaterialListState> emit,
  ) {
    final visible = _applyFilters(
      state.materials,
      query: state.searchQuery,
      filter: event.filter,
    );
    emit(state.copyWith(filter: event.filter, visibleMaterials: visible));
  }

  void _onListUpdated(
    _RawMaterialListUpdated event,
    Emitter<RawMaterialListState> emit,
  ) {
    final factoryId = _factoryId;
    if (factoryId == null) return;

    final merged = _mergeWithCatalog(factoryId, event.materials);
    final visible = _applyFilters(
      merged,
      query: state.searchQuery,
      filter: state.filter,
    );
    final lowStockCount = merged.where((material) => material.isLowStock).length;

    emit(
      state.copyWith(
        status: RawMaterialListStatus.loaded,
        materials: merged,
        visibleMaterials: visible,
        lowStockCount: lowStockCount,
        errorMessage: null,
      ),
    );
  }

  void _onStreamFailed(
    _RawMaterialListStreamFailed event,
    Emitter<RawMaterialListState> emit,
  ) {
    emit(
      state.copyWith(
        status: RawMaterialListStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  List<RawMaterial> _mergeWithCatalog(
    String factoryId,
    List<RawMaterial> loaded,
  ) {
    return RawMaterialType.values.map((type) {
      for (final material in loaded) {
        if (material.materialType == type) return material;
      }
      return RawMaterial.placeholder(factoryId: factoryId, materialType: type);
    }).toList();
  }

  List<RawMaterial> _applyFilters(
    List<RawMaterial> materials, {
    required String query,
    required RawMaterialListFilter filter,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    return materials.where((material) {
      final matchesFilter = switch (filter) {
        RawMaterialListFilter.all => true,
        RawMaterialListFilter.lowStock => material.isLowStock,
        RawMaterialListFilter.inStock => material.hasStock,
      };

      if (!matchesFilter) return false;
      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        material.materialType.label,
        material.unit.label,
      ].join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

final class _RawMaterialListUpdated extends RawMaterialListEvent {
  const _RawMaterialListUpdated(this.materials);

  final List<RawMaterial> materials;

  @override
  List<Object?> get props => [materials];
}

final class _RawMaterialListStreamFailed extends RawMaterialListEvent {
  const _RawMaterialListStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
