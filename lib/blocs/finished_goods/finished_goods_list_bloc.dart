import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/finished_goods_repository.dart';
import '../../domain/entities/finished_good.dart';
import '../../domain/enums/inventory_enums.dart';

part 'finished_goods_list_event.dart';
part 'finished_goods_list_state.dart';

class FinishedGoodsListBloc
    extends Bloc<FinishedGoodsListEvent, FinishedGoodsListState> {
  FinishedGoodsListBloc({required FinishedGoodsRepository repository})
      : _repository = repository,
        super(const FinishedGoodsListState()) {
    on<FinishedGoodsListWatchStarted>(_onWatchStarted);
    on<FinishedGoodsListSearchChanged>(_onSearchChanged);
    on<FinishedGoodsListFilterChanged>(_onFilterChanged);
    on<_FinishedGoodsListUpdated>(_onListUpdated);
    on<_FinishedGoodsListStreamFailed>(_onStreamFailed);
  }

  final FinishedGoodsRepository _repository;
  StreamSubscription<List<FinishedGood>>? _subscription;

  Future<void> _onWatchStarted(
    FinishedGoodsListWatchStarted event,
    Emitter<FinishedGoodsListState> emit,
  ) async {
    emit(state.copyWith(status: FinishedGoodsListStatus.loading));
    await _subscription?.cancel();
    _subscription = _repository.watchFinishedGoods(event.factoryId).listen(
          (items) => add(_FinishedGoodsListUpdated(items)),
          onError: (_) => add(
            const _FinishedGoodsListStreamFailed(
              'Could not load finished goods inventory.',
            ),
          ),
        );
  }

  void _onSearchChanged(
    FinishedGoodsListSearchChanged event,
    Emitter<FinishedGoodsListState> emit,
  ) {
    emit(_applyFilters(state, searchQuery: event.query));
  }

  void _onFilterChanged(
    FinishedGoodsListFilterChanged event,
    Emitter<FinishedGoodsListState> emit,
  ) {
    emit(_applyFilters(state, filter: event.filter));
  }

  void _onListUpdated(
    _FinishedGoodsListUpdated event,
    Emitter<FinishedGoodsListState> emit,
  ) {
    emit(
      _applyFilters(
        state.copyWith(
          status: FinishedGoodsListStatus.loaded,
          items: event.items,
          errorMessage: null,
        ),
      ),
    );
  }

  void _onStreamFailed(
    _FinishedGoodsListStreamFailed event,
    Emitter<FinishedGoodsListState> emit,
  ) {
    emit(
      state.copyWith(
        status: FinishedGoodsListStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  FinishedGoodsListState _applyFilters(
    FinishedGoodsListState current, {
    String? searchQuery,
    FinishedGoodsListFilter? filter,
  }) {
    final query = searchQuery ?? current.searchQuery;
    final activeFilter = filter ?? current.filter;
    final normalizedQuery = query.trim().toLowerCase();

    final visible = current.items.where((item) {
      if (activeFilter == FinishedGoodsListFilter.inStock && !item.hasStock) {
        return false;
      }
      if (activeFilter == FinishedGoodsListFilter.lowStock && !item.isLowStock) {
        return false;
      }
      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        item.productType.label,
        item.marbleVariety,
        item.grade.label,
        item.size,
        item.thickness,
        item.location,
      ].whereType<String>().join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList();

    final totalStockValue =
        current.items.fold<double>(0, (sum, item) => sum + item.stockValue);
    final lowStockCount =
        current.items.where((item) => item.isLowStock).length;

    return current.copyWith(
      searchQuery: query,
      filter: activeFilter,
      visibleItems: visible,
      totalStockValue: totalStockValue,
      lowStockCount: lowStockCount,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
