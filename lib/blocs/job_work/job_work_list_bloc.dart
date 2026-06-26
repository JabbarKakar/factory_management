import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/job_work_repository.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/enums/job_work_enums.dart';

part 'job_work_list_event.dart';
part 'job_work_list_state.dart';

class JobWorkListBloc extends Bloc<JobWorkListEvent, JobWorkListState> {
  JobWorkListBloc({required JobWorkRepository repository})
      : _repository = repository,
        super(const JobWorkListState()) {
    on<JobWorkListWatchStarted>(_onWatchStarted);
    on<JobWorkListSearchChanged>(_onSearchChanged);
    on<JobWorkListStatusFilterChanged>(_onStatusFilterChanged);
    on<JobWorkListStageFilterChanged>(_onStageFilterChanged);
    on<_JobWorkListUpdated>(_onListUpdated);
    on<_JobWorkListStreamFailed>(_onStreamFailed);
  }

  final JobWorkRepository _repository;
  StreamSubscription<List<JobWorkOrder>>? _subscription;

  Future<void> _onWatchStarted(
    JobWorkListWatchStarted event,
    Emitter<JobWorkListState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkListStatus.loading));
    await _subscription?.cancel();
    _subscription = _repository.watchJobWorkOrders(event.factoryId).listen(
          (orders) => add(_JobWorkListUpdated(orders)),
          onError: (_) => add(
            const _JobWorkListStreamFailed(
              'Could not load job work orders. Please try again.',
            ),
          ),
        );
  }

  void _onSearchChanged(
    JobWorkListSearchChanged event,
    Emitter<JobWorkListState> emit,
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
    JobWorkListStatusFilterChanged event,
    Emitter<JobWorkListState> emit,
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
    JobWorkListStageFilterChanged event,
    Emitter<JobWorkListState> emit,
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
    _JobWorkListUpdated event,
    Emitter<JobWorkListState> emit,
  ) {
    emit(
      state.copyWith(
        status: JobWorkListStatus.loaded,
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
    _JobWorkListStreamFailed event,
    Emitter<JobWorkListState> emit,
  ) {
    emit(
      state.copyWith(
        status: JobWorkListStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  List<JobWorkOrder> _applyFilters(
    List<JobWorkOrder> orders, {
    required String query,
    required bool showActiveOnly,
    required JobWorkListStageFilter stageFilter,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final stageStatus = stageFilter.status;

    return orders.where((order) {
      if (showActiveOnly && !order.status.isActive) return false;
      if (stageStatus != null && order.status != stageStatus) return false;

      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        order.jobWorkNumber,
        order.customerName,
        order.marbleVariety,
        order.status.label,
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
