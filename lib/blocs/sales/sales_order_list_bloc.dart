import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../core/events/entity_reactive_event_bus.dart';
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
    on<SalesOrderListFetchNext>(_onFetchNext);
    on<SalesOrderListSearchChanged>(_onSearchChanged);
    on<SalesOrderListStageFilterChanged>(_onStageFilterChanged);
    on<_SalesOrderListUpdated>(_onListUpdated);
    on<_SalesOrderListStreamFailed>(_onStreamFailed);
  }

  final SalesOrderRepository _repository;
  StreamSubscription<EntityMutationEvent<SalesOrder>>? _salesEventSub;

  SalesOrderStatus? _statusFilterForSales(SalesListFilter filter) {
    return switch (filter) {
      SalesListFilter.received => SalesOrderStatus.received,
      SalesListFilter.ready => SalesOrderStatus.ready,
      SalesListFilter.partiallyDispatched =>
        SalesOrderStatus.partiallyDispatched,
      SalesListFilter.delivered => SalesOrderStatus.delivered,
      SalesListFilter.invoiced => SalesOrderStatus.invoiced,
      SalesListFilter.closed => SalesOrderStatus.closed,
      SalesListFilter.cancelled => SalesOrderStatus.cancelled,
      _ => null,
    };
  }

  Future<void> _onWatchStarted(
    SalesOrderListWatchStarted event,
    Emitter<SalesOrderListState> emit,
  ) async {
    _salesEventSub?.cancel();
    _salesEventSub =
        EntityReactiveEventBus.instance.on<SalesOrder>().listen((evt) {
      if (evt.type == EntityMutationType.created) {
        final updated = [
          evt.entity,
          ...state.orders.where((o) => o.id != evt.entity.id),
        ];
        add(_SalesOrderListUpdated(updated));
      } else if (evt.type == EntityMutationType.updated) {
        final updated = state.orders
            .map((o) => o.id == evt.entity.id ? evt.entity : o)
            .toList();
        add(_SalesOrderListUpdated(updated));
      } else if (evt.type == EntityMutationType.deleted) {
        final updated =
            state.orders.where((o) => o.id != evt.entity.id).toList();
        add(_SalesOrderListUpdated(updated));
      }
    });
    final stageFilter = event.initialFilter ?? state.stageFilter;
    emit(
      state.copyWith(
        status: SalesOrderListStatus.loading,
        isLoadingInitial: true,
        factoryId: event.factoryId,
        stageFilter: stageFilter,
        clearLastDocument: true,
        hasMoreData: true,
        orders: const [],
        visibleOrders: const [],
      ),
    );

    try {
      final paginated = await _repository.fetchSalesOrdersPage(
        factoryId: event.factoryId,
        statusFilter: _statusFilterForSales(stageFilter),
        limit: 20,
      );

      final visible = _applyFilters(
        paginated.items,
        query: state.searchQuery,
        stageFilter: stageFilter,
      );

      emit(
        state.copyWith(
          status: SalesOrderListStatus.loaded,
          isLoadingInitial: false,
          orders: paginated.items,
          visibleOrders: visible,
          lastDocument: paginated.lastDocument,
          hasMoreData: paginated.hasMore,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SalesOrderListStatus.failure,
          isLoadingInitial: false,
          errorMessage: 'Could not load sales orders. Please try again.',
        ),
      );
    }
  }

  Future<void> _onFetchNext(
    SalesOrderListFetchNext event,
    Emitter<SalesOrderListState> emit,
  ) async {
    if (state.isLoadingMore ||
        state.isLoadingInitial ||
        !state.hasMoreData ||
        state.factoryId.isEmpty) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    try {
      final paginated = await _repository.fetchSalesOrdersPage(
        factoryId: state.factoryId,
        startAfter: state.lastDocument,
        statusFilter: _statusFilterForSales(state.stageFilter),
        limit: 20,
      );

      final combined = [...state.orders, ...paginated.items];
      final visible = _applyFilters(
        combined,
        query: state.searchQuery,
        stageFilter: state.stageFilter,
      );

      emit(
        state.copyWith(
          isLoadingMore: false,
          orders: combined,
          visibleOrders: visible,
          lastDocument: paginated.lastDocument,
          hasMoreData: paginated.hasMore,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
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
    _salesEventSub?.cancel();
    return super.close();
  }
}
