import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/delivery_repository.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/enums/delivery_enums.dart';

part 'delivery_list_event.dart';
part 'delivery_list_state.dart';

class DeliveryListBloc extends Bloc<DeliveryListEvent, DeliveryListState> {
  DeliveryListBloc({required DeliveryRepository repository})
      : _repository = repository,
        super(const DeliveryListState()) {
    on<DeliveryListWatchStarted>(_onWatchStarted);
    on<DeliveryListFetchNext>(_onFetchNext);
    on<DeliveryListWatchStopped>(_onWatchStopped);
    on<DeliveryListSearchChanged>(_onSearchChanged);
    on<DeliveryListFilterChanged>(_onFilterChanged);
    on<_DeliveryListUpdated>(_onListUpdated);
    on<_DeliveryListStreamFailed>(_onStreamFailed);
  }

  final DeliveryRepository _repository;
  String? _driverEmployeeId;

  Future<void> _onWatchStarted(
    DeliveryListWatchStarted event,
    Emitter<DeliveryListState> emit,
  ) async {
    final filter = event.initialFilter ?? state.filter;
    _driverEmployeeId = event.driverEmployeeId;
    emit(
      state.copyWith(
        status: DeliveryListStatus.loading,
        isLoadingInitial: true,
        factoryId: event.factoryId,
        filter: filter,
        clearLastDocument: true,
        hasMoreData: true,
        deliveries: const [],
        visibleDeliveries: const [],
      ),
    );

    try {
      final paginated = await _repository.fetchDeliveriesPage(
        factoryId: event.factoryId,
        limit: 20,
      );

      final visible = _applyFilters(
        paginated.items,
        query: state.searchQuery,
        filter: filter,
        driverEmployeeId: _driverEmployeeId,
      );

      emit(
        state.copyWith(
          status: DeliveryListStatus.loaded,
          isLoadingInitial: false,
          deliveries: paginated.items,
          visibleDeliveries: visible,
          lastDocument: paginated.lastDocument,
          hasMoreData: paginated.hasMore,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: DeliveryListStatus.failure,
          isLoadingInitial: false,
          errorMessage: 'Could not load deliveries. Please try again.',
        ),
      );
    }
  }

  Future<void> _onFetchNext(
    DeliveryListFetchNext event,
    Emitter<DeliveryListState> emit,
  ) async {
    if (state.isLoadingMore ||
        state.isLoadingInitial ||
        !state.hasMoreData ||
        state.factoryId.isEmpty) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    try {
      final paginated = await _repository.fetchDeliveriesPage(
        factoryId: state.factoryId,
        startAfter: state.lastDocument,
        limit: 20,
      );

      final combined = [...state.deliveries, ...paginated.items];
      final visible = _applyFilters(
        combined,
        query: state.searchQuery,
        filter: state.filter,
        driverEmployeeId: _driverEmployeeId,
      );

      emit(
        state.copyWith(
          isLoadingMore: false,
          deliveries: combined,
          visibleDeliveries: visible,
          lastDocument: paginated.lastDocument,
          hasMoreData: paginated.hasMore,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onWatchStopped(
    DeliveryListWatchStopped event,
    Emitter<DeliveryListState> emit,
  ) async {}

  void _onSearchChanged(
    DeliveryListSearchChanged event,
    Emitter<DeliveryListState> emit,
  ) {
    emit(
      state.copyWith(
        searchQuery: event.query,
        visibleDeliveries: _applyFilters(
          state.deliveries,
          query: event.query,
          filter: state.filter,
          driverEmployeeId: _driverEmployeeId,
        ),
      ),
    );
  }

  void _onFilterChanged(
    DeliveryListFilterChanged event,
    Emitter<DeliveryListState> emit,
  ) {
    emit(
      state.copyWith(
        filter: event.filter,
        visibleDeliveries: _applyFilters(
          state.deliveries,
          query: state.searchQuery,
          filter: event.filter,
          driverEmployeeId: _driverEmployeeId,
        ),
      ),
    );
  }

  void _onListUpdated(
    _DeliveryListUpdated event,
    Emitter<DeliveryListState> emit,
  ) {
    emit(
      state.copyWith(
        status: DeliveryListStatus.loaded,
        deliveries: event.deliveries,
        visibleDeliveries: _applyFilters(
          event.deliveries,
          query: state.searchQuery,
          filter: state.filter,
          driverEmployeeId: _driverEmployeeId,
        ),
        errorMessage: null,
      ),
    );
  }

  void _onStreamFailed(
    _DeliveryListStreamFailed event,
    Emitter<DeliveryListState> emit,
  ) {
    emit(
      state.copyWith(
        status: DeliveryListStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  List<Delivery> _applyFilters(
    List<Delivery> deliveries, {
    required String query,
    required DeliveryListFilter filter,
    String? driverEmployeeId,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    return deliveries.where((delivery) {
      if (driverEmployeeId != null &&
          driverEmployeeId.isNotEmpty &&
          delivery.driverEmployeeId != driverEmployeeId) {
        return false;
      }
      if (filter == DeliveryListFilter.overdue) {
        if (!delivery.isDispatchOverdue()) return false;
      } else if (!filter.matches(delivery.status)) {
        return false;
      }
      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        delivery.deliveryNumber,
        delivery.salesOrderNumber,
        delivery.customerName,
        delivery.deliveryAddress,
        delivery.vehicleNumber,
        delivery.driverName,
        delivery.loadingSupervisor,
        delivery.receiverName,
        delivery.status.label,
      ].whereType<String>().join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList();
  }
}

final class _DeliveryListUpdated extends DeliveryListEvent {
  const _DeliveryListUpdated(this.deliveries);

  final List<Delivery> deliveries;

  @override
  List<Object?> get props => [deliveries];
}

final class _DeliveryListStreamFailed extends DeliveryListEvent {
  const _DeliveryListStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
