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
    on<SalesOrderListStatusFilterChanged>(_onStatusFilterChanged);
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
    emit(state.copyWith(status: SalesOrderListStatus.loading));
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
          showActiveOnly: state.showActiveOnly,
          stageFilter: state.stageFilter,
        ),
      ),
    );
  }

  void _onStatusFilterChanged(
    SalesOrderListStatusFilterChanged event,
    Emitter<SalesOrderListState> emit,
  ) {
    emit(
      state.copyWith(
        showActiveOnly: event.showActiveOnly,
        visibleOrders: _applyFilters(
          state.orders,
          query: state.searchQuery,
          showActiveOnly: event.showActiveOnly,
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
          showActiveOnly: state.showActiveOnly,
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
          showActiveOnly: state.showActiveOnly,
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
    required bool showActiveOnly,
    required SalesListFilter stageFilter,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final stageStatus = stageFilter.status;

    return orders.where((order) {
      if (showActiveOnly && !order.status.isActive) return false;
      if (stageStatus != null && order.status != stageStatus) return false;

      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        order.orderNumber,
        order.customerName,
        order.status.label,
        ...order.lineItems.map((item) => item.marbleVariety),
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
