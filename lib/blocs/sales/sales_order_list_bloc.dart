import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/sales_order_repository.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/sales_enums.dart';

part 'sales_order_list_event.dart';
part 'sales_order_list_state.dart';

class SalesOrderListBloc extends Bloc<SalesOrderListEvent, SalesOrderListState> {
  SalesOrderListBloc({required SalesOrderRepository repository})
      : _repository = repository,
        super(const SalesOrderListState()) {
    on<SalesOrderListWatchStarted>(_onWatchStarted);
    on<SalesOrderListSearchChanged>(_onSearchChanged);
    on<SalesOrderListStageFilterChanged>(_onStageFilterChanged);
    on<_SalesOrderListUpdated>(_onListUpdated);
    on<_SalesOrderListStreamFailed>(_onStreamFailed);
  }

  final SalesOrderRepository _repository;
  StreamSubscription<List<SalesOrder>>? _subscription;

  Future<void> _onWatchStarted(
    SalesOrderListWatchStarted event,
    Emitter<SalesOrderListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SalesOrderListStatus.loading,
        stageFilter: event.initialFilter ?? state.stageFilter,
      ),
    );
    await _subscription?.cancel();
    _subscription = _repository.watchSalesOrders(event.factoryId).listen(
          (orders) => add(_SalesOrderListUpdated(orders)),
          onError: (_) => add(
            const _SalesOrderListStreamFailed(
              'Could not load sales orders. Please try again.',
            ),
          ),
        );
  }

  void _onSearchChanged(
    SalesOrderListSearchChanged event,
    Emitter<SalesOrderListState> emit,
  ) {
    emit(
      state.copyWith(
        searchQuery: event.query,
        visibleOrders: _applyFilters(
          state.orders,
          query: event.query,
          stageFilter: state.stageFilter,
        ),
      ),
    );
  }

  void _onStageFilterChanged(
    SalesOrderListStageFilterChanged event,
    Emitter<SalesOrderListState> emit,
  ) {
    emit(
      state.copyWith(
        stageFilter: event.stageFilter,
        visibleOrders: _applyFilters(
          state.orders,
          query: state.searchQuery,
          stageFilter: event.stageFilter,
        ),
      ),
    );
  }

  void _onListUpdated(
    _SalesOrderListUpdated event,
    Emitter<SalesOrderListState> emit,
  ) {
    emit(
      state.copyWith(
        status: SalesOrderListStatus.loaded,
        orders: event.orders,
        visibleOrders: _applyFilters(
          event.orders,
          query: state.searchQuery,
          stageFilter: state.stageFilter,
        ),
        errorMessage: null,
      ),
    );
  }

  void _onStreamFailed(
    _SalesOrderListStreamFailed event,
    Emitter<SalesOrderListState> emit,
  ) {
    emit(
      state.copyWith(
        status: SalesOrderListStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  List<SalesOrder> _applyFilters(
    List<SalesOrder> orders, {
    required String query,
    required SalesListFilter stageFilter,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    final filtered = orders.where((order) {
      if (!stageFilter.matches(order.status)) return false;
      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        order.orderNumber,
        order.customerName,
        order.status.label,
        ...order.lineItems.map((item) => item.marbleVariety),
      ].join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList();

    filtered.sort((a, b) {
      final rankCompare = a.status.listSortRank.compareTo(b.status.listSortRank);
      if (rankCompare != 0) return rankCompare;
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
