import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/production_repository.dart';
import '../../domain/entities/production_batch.dart';
import '../../domain/enums/production_enums.dart';

part 'production_list_event.dart';
part 'production_list_state.dart';

class ProductionListBloc extends Bloc<ProductionListEvent, ProductionListState> {
  ProductionListBloc({required ProductionRepository repository})
      : _repository = repository,
        super(const ProductionListState()) {
    on<ProductionListWatchStarted>(_onWatchStarted);
    on<ProductionListSearchChanged>(_onSearchChanged);
    on<ProductionListFilterChanged>(_onFilterChanged);
    on<_ProductionListUpdated>(_onListUpdated);
    on<_ProductionListStreamFailed>(_onStreamFailed);
  }

  final ProductionRepository _repository;
  StreamSubscription<List<ProductionBatch>>? _subscription;

  Future<void> _onWatchStarted(
    ProductionListWatchStarted event,
    Emitter<ProductionListState> emit,
  ) async {
    emit(state.copyWith(status: ProductionListStatus.loading));
    await _subscription?.cancel();
    _subscription = _repository.watchBatches(event.factoryId).listen(
          (batches) => add(_ProductionListUpdated(batches)),
          onError: (_) => add(
            const _ProductionListStreamFailed(
              'Could not load production batches. Please try again.',
            ),
          ),
        );
  }

  void _onSearchChanged(
    ProductionListSearchChanged event,
    Emitter<ProductionListState> emit,
  ) {
    emit(_applyFilters(state, searchQuery: event.query));
  }

  void _onFilterChanged(
    ProductionListFilterChanged event,
    Emitter<ProductionListState> emit,
  ) {
    emit(_applyFilters(state, filter: event.filter));
  }

  void _onListUpdated(
    _ProductionListUpdated event,
    Emitter<ProductionListState> emit,
  ) {
    emit(
      _applyFilters(
        state.copyWith(
          status: ProductionListStatus.loaded,
          batches: event.batches,
          errorMessage: null,
        ),
      ),
    );
  }

  void _onStreamFailed(
    _ProductionListStreamFailed event,
    Emitter<ProductionListState> emit,
  ) {
    emit(
      state.copyWith(
        status: ProductionListStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  ProductionListState _applyFilters(
    ProductionListState current, {
    String? searchQuery,
    ProductionListFilter? filter,
  }) {
    final query = searchQuery ?? current.searchQuery;
    final activeFilter = filter ?? current.filter;
    final normalizedQuery = query.trim().toLowerCase();
    final now = DateTime.now();

    final visible = current.batches.where((batch) {
      if (activeFilter == ProductionListFilter.thisMonth) {
        final date = batch.productionDate;
        if (date.year != now.year || date.month != now.month) return false;
      }
      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        batch.batchNumber,
        batch.productType.label,
        batch.marbleVariety,
        batch.rawMaterialType.label,
        batch.supervisorName,
        batch.shift.label,
      ].whereType<String>().join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList();

    final monthTotalSqFt = current.batches
        .where((batch) {
          final date = batch.productionDate;
          return date.year == now.year && date.month == now.month;
        })
        .fold<double>(0, (sum, batch) => sum + batch.totalUsableSqFt);

    return current.copyWith(
      searchQuery: query,
      filter: activeFilter,
      visibleBatches: visible,
      monthTotalSqFt: monthTotalSqFt,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
