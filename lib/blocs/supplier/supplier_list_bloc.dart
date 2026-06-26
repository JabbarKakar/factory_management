import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/supplier_repository.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/enums/supplier_enums.dart';

part 'supplier_list_event.dart';
part 'supplier_list_state.dart';

class SupplierListBloc extends Bloc<SupplierListEvent, SupplierListState> {
  SupplierListBloc({required SupplierRepository repository})
      : _repository = repository,
        super(const SupplierListState()) {
    on<SupplierListWatchStarted>(_onWatchStarted);
    on<SupplierListWatchStopped>(_onWatchStopped);
    on<SupplierListSearchChanged>(_onSearchChanged);
    on<SupplierListFilterChanged>(_onFilterChanged);
    on<_SupplierListUpdated>(_onListUpdated);
    on<_SupplierListStreamFailed>(_onStreamFailed);
  }

  final SupplierRepository _repository;
  StreamSubscription<List<Supplier>>? _subscription;

  Future<void> _onWatchStarted(
    SupplierListWatchStarted event,
    Emitter<SupplierListState> emit,
  ) async {
    emit(state.copyWith(status: SupplierListStatus.loading));
    await _subscription?.cancel();
    _subscription = _repository.watchSuppliers(event.factoryId).listen(
          (suppliers) => add(_SupplierListUpdated(suppliers)),
          onError: (_) => add(
            const _SupplierListStreamFailed(
              'Could not load suppliers. Please try again.',
            ),
          ),
        );
  }

  Future<void> _onWatchStopped(
    SupplierListWatchStopped event,
    Emitter<SupplierListState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _onSearchChanged(
    SupplierListSearchChanged event,
    Emitter<SupplierListState> emit,
  ) {
    final visible = _applyFilters(
      state.suppliers,
      query: event.query,
      supplierType: state.supplierTypeFilter,
    );
    emit(
      state.copyWith(
        searchQuery: event.query,
        visibleSuppliers: visible,
      ),
    );
  }

  void _onFilterChanged(
    SupplierListFilterChanged event,
    Emitter<SupplierListState> emit,
  ) {
    final visible = _applyFilters(
      state.suppliers,
      query: state.searchQuery,
      supplierType: event.supplierType,
    );
    emit(
      state.copyWith(
        supplierTypeFilter: event.supplierType,
        clearSupplierTypeFilter: event.supplierType == null,
        visibleSuppliers: visible,
      ),
    );
  }

  void _onListUpdated(
    _SupplierListUpdated event,
    Emitter<SupplierListState> emit,
  ) {
    final visible = _applyFilters(
      event.suppliers,
      query: state.searchQuery,
      supplierType: state.supplierTypeFilter,
    );
    emit(
      state.copyWith(
        status: SupplierListStatus.loaded,
        suppliers: event.suppliers,
        visibleSuppliers: visible,
        errorMessage: null,
      ),
    );
  }

  void _onStreamFailed(
    _SupplierListStreamFailed event,
    Emitter<SupplierListState> emit,
  ) {
    emit(
      state.copyWith(
        status: SupplierListStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  List<Supplier> _applyFilters(
    List<Supplier> suppliers, {
    required String query,
    SupplierType? supplierType,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    return suppliers.where((supplier) {
      final matchesType =
          supplierType == null || supplier.supplierType == supplierType;

      if (!matchesType) return false;
      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        supplier.name,
        supplier.supplierNumber,
        supplier.phone,
        supplier.phoneSecondary,
        supplier.contactPersonName,
        supplier.city,
        supplier.materialsSupplied,
        supplier.supplierType.label,
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

final class _SupplierListUpdated extends SupplierListEvent {
  const _SupplierListUpdated(this.suppliers);

  final List<Supplier> suppliers;

  @override
  List<Object?> get props => [suppliers];
}

final class _SupplierListStreamFailed extends SupplierListEvent {
  const _SupplierListStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
