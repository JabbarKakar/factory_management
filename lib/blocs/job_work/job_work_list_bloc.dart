import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/job_work_invoice_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/repositories/quality_check_repository.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/quality_check.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/quality_enums.dart';

part 'job_work_list_event.dart';
part 'job_work_list_state.dart';

class JobWorkListBloc extends Bloc<JobWorkListEvent, JobWorkListState> {
  JobWorkListBloc({
    required JobWorkRepository repository,
    required JobWorkInvoiceRepository invoiceRepository,
    required QualityCheckRepository qualityCheckRepository,
  })  : _repository = repository,
        _invoiceRepository = invoiceRepository,
        _qualityCheckRepository = qualityCheckRepository,
        super(const JobWorkListState()) {
    on<JobWorkListWatchStarted>(_onWatchStarted);
    on<JobWorkListSearchChanged>(_onSearchChanged);
    on<JobWorkListStageFilterChanged>(_onStageFilterChanged);
    on<_JobWorkListUpdated>(_onListUpdated);
    on<_JobWorkInvoicesUpdated>(_onInvoicesUpdated);
    on<_JobWorkQualityChecksUpdated>(_onQualityChecksUpdated);
    on<_JobWorkListStreamFailed>(_onStreamFailed);
  }

  final JobWorkRepository _repository;
  final JobWorkInvoiceRepository _invoiceRepository;
  final QualityCheckRepository _qualityCheckRepository;
  StreamSubscription<List<JobWorkOrder>>? _subscription;
  StreamSubscription<List<JobWorkInvoice>>? _invoicesSubscription;
  StreamSubscription<List<QualityCheck>>? _qualityChecksSubscription;

  Future<void> _onWatchStarted(
    JobWorkListWatchStarted event,
    Emitter<JobWorkListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: JobWorkListStatus.loading,
        stageFilter: event.initialFilter ?? state.stageFilter,
      ),
    );
    await _subscription?.cancel();
    await _invoicesSubscription?.cancel();
    await _qualityChecksSubscription?.cancel();

    _subscription = _repository.watchJobWorkOrders(event.factoryId).listen(
          (orders) => add(_JobWorkListUpdated(orders)),
          onError: (_) => add(
            const _JobWorkListStreamFailed(
              'Could not load job work orders. Please try again.',
            ),
          ),
        );

    _invoicesSubscription =
        _invoiceRepository.watchInvoicesForFactory(event.factoryId).listen(
      (invoices) => add(_JobWorkInvoicesUpdated(invoices)),
      onError: (_) {},
    );

    _qualityChecksSubscription = _qualityCheckRepository
        .watchQualityChecks(event.factoryId)
        .listen(
          (checks) => add(_JobWorkQualityChecksUpdated(checks)),
          onError: (_) {},
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
          stageFilter: event.stageFilter,
        ),
      ),
    );
  }

  void _onListUpdated(
    _JobWorkListUpdated event,
    Emitter<JobWorkListState> emit,
  ) {
    final jobWorkIdsWithQc = _jobWorkIdsWithQc(state.qualityChecks);
    emit(
      state.copyWith(
        status: JobWorkListStatus.loaded,
        orders: event.orders,
        jobWorkIdsWithQc: jobWorkIdsWithQc,
        awaitingQcCount: _awaitingQcCount(event.orders, jobWorkIdsWithQc),
        visibleOrders: _applyFilters(
          event.orders,
          query: state.searchQuery,
          stageFilter: state.stageFilter,
        ),
        errorMessage: null,
      ),
    );
  }

  void _onInvoicesUpdated(
    _JobWorkInvoicesUpdated event,
    Emitter<JobWorkListState> emit,
  ) {
    final invoicesByJobWorkId = {
      for (final invoice in event.invoices) invoice.jobWorkId: invoice,
    };
    emit(state.copyWith(invoicesByJobWorkId: invoicesByJobWorkId));
  }

  void _onQualityChecksUpdated(
    _JobWorkQualityChecksUpdated event,
    Emitter<JobWorkListState> emit,
  ) {
    final jobWorkIdsWithQc = _jobWorkIdsWithQc(event.checks);
    emit(
      state.copyWith(
        qualityChecks: event.checks,
        jobWorkIdsWithQc: jobWorkIdsWithQc,
        awaitingQcCount: _awaitingQcCount(state.orders, jobWorkIdsWithQc),
        visibleOrders: _applyFilters(
          state.orders,
          query: state.searchQuery,
          stageFilter: state.stageFilter,
        ),
        status: state.orders.isNotEmpty
            ? JobWorkListStatus.loaded
            : state.status,
      ),
    );
  }

  Set<String> _jobWorkIdsWithQc(List<QualityCheck> checks) {
    return checks
        .where((check) => check.referenceType == QcReferenceType.jobWork)
        .map((check) => check.referenceId)
        .toSet();
  }

  int _awaitingQcCount(List<JobWorkOrder> orders, Set<String> jobWorkIdsWithQc) {
    return orders
        .where(
          (order) =>
              order.status == JobWorkStatus.qc &&
              !jobWorkIdsWithQc.contains(order.id),
        )
        .length;
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
    required JobWorkListStageFilter stageFilter,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    final filtered = orders.where((order) {
      if (!stageFilter.matches(order.status)) return false;
      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        order.jobWorkNumber,
        order.customerName,
        order.marbleVariety,
        order.mineLocation,
        order.mineOwner,
        order.status.label,
        ...order.smallSizes,
        ...order.largeSizes,
        ...order.legacySizes,
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
    _invoicesSubscription?.cancel();
    _qualityChecksSubscription?.cancel();
    return super.close();
  }
}

final class _JobWorkInvoicesUpdated extends JobWorkListEvent {
  const _JobWorkInvoicesUpdated(this.invoices);

  final List<JobWorkInvoice> invoices;

  @override
  List<Object?> get props => [invoices];
}

final class _JobWorkQualityChecksUpdated extends JobWorkListEvent {
  const _JobWorkQualityChecksUpdated(this.checks);

  final List<QualityCheck> checks;

  @override
  List<Object?> get props => [checks];
}
