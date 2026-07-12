import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/job_work_collection_repository.dart';
import '../../data/repositories/job_work_invoice_repository.dart';
import '../../data/repositories/job_work_load_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/repositories/quality_check_repository.dart';
import '../../data/services/job_work_collection_quantity_helper.dart';
import '../../data/services/job_work_load_production_helper.dart';
import '../../domain/entities/job_work_collection.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/job_work_load.dart';
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
    required JobWorkCollectionRepository collectionRepository,
    required JobWorkLoadRepository loadRepository,
    required QualityCheckRepository qualityCheckRepository,
  })  : _repository = repository,
        _invoiceRepository = invoiceRepository,
        _collectionRepository = collectionRepository,
        _loadRepository = loadRepository,
        _qualityCheckRepository = qualityCheckRepository,
        super(const JobWorkListState()) {
    on<JobWorkListWatchStarted>(_onWatchStarted);
    on<JobWorkListSearchChanged>(_onSearchChanged);
    on<JobWorkListStageFilterChanged>(_onStageFilterChanged);
    on<_JobWorkListUpdated>(_onListUpdated);
    on<_JobWorkInvoicesUpdated>(_onInvoicesUpdated);
    on<_JobWorkQualityChecksUpdated>(_onQualityChecksUpdated);
    on<_JobWorkCollectionsUpdated>(_onCollectionsUpdated);
    on<_JobWorkLoadsUpdated>(_onLoadsUpdated);
    on<_JobWorkListStreamFailed>(_onStreamFailed);
  }

  final JobWorkRepository _repository;
  final JobWorkInvoiceRepository _invoiceRepository;
  final JobWorkCollectionRepository _collectionRepository;
  final JobWorkLoadRepository _loadRepository;
  final QualityCheckRepository _qualityCheckRepository;
  StreamSubscription<List<JobWorkOrder>>? _subscription;
  StreamSubscription<List<JobWorkInvoice>>? _invoicesSubscription;
  StreamSubscription<List<QualityCheck>>? _qualityChecksSubscription;
  StreamSubscription<List<JobWorkCollection>>? _collectionsSubscription;
  StreamSubscription<List<JobWorkLoad>>? _loadsSubscription;

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
    await _collectionsSubscription?.cancel();
    await _loadsSubscription?.cancel();

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

    _collectionsSubscription = _collectionRepository
        .watchCollections(event.factoryId)
        .listen(
          (collections) => add(_JobWorkCollectionsUpdated(collections)),
          onError: (_) {},
        );

    _loadsSubscription = _loadRepository.watchLoads(event.factoryId).listen(
          (loads) => add(_JobWorkLoadsUpdated(loads)),
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
          collections: state.collections,
          loads: state.loads,
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
          collections: state.collections,
          loads: state.loads,
        ),
      ),
    );
  }

  void _onListUpdated(
    _JobWorkListUpdated event,
    Emitter<JobWorkListState> emit,
  ) {
    final jobWorkIdsWithQc = _jobWorkIdsWithQc(state.qualityChecks);
    final loadIdsWithQc = _loadIdsWithQc(state.qualityChecks);
    emit(
      state.copyWith(
        status: JobWorkListStatus.loaded,
        orders: event.orders,
        jobWorkIdsWithQc: jobWorkIdsWithQc,
        loadIdsWithQc: loadIdsWithQc,
        awaitingQcCount: JobWorkLoadProductionHelper.awaitingQcCount(
          orders: event.orders,
          loads: state.loads,
          loadIdsWithQc: loadIdsWithQc,
          jobWorkIdsWithQc: jobWorkIdsWithQc,
        ),
        visibleOrders: _applyFilters(
          event.orders,
          query: state.searchQuery,
          stageFilter: state.stageFilter,
          collections: state.collections,
          loads: state.loads,
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
    final loadIdsWithQc = _loadIdsWithQc(event.checks);
    emit(
      state.copyWith(
        qualityChecks: event.checks,
        jobWorkIdsWithQc: jobWorkIdsWithQc,
        loadIdsWithQc: loadIdsWithQc,
        awaitingQcCount: JobWorkLoadProductionHelper.awaitingQcCount(
          orders: state.orders,
          loads: state.loads,
          loadIdsWithQc: loadIdsWithQc,
          jobWorkIdsWithQc: jobWorkIdsWithQc,
        ),
        visibleOrders: _applyFilters(
          state.orders,
          query: state.searchQuery,
          stageFilter: state.stageFilter,
          collections: state.collections,
          loads: state.loads,
        ),
        status: state.orders.isNotEmpty
            ? JobWorkListStatus.loaded
            : state.status,
      ),
    );
  }

  void _onCollectionsUpdated(
    _JobWorkCollectionsUpdated event,
    Emitter<JobWorkListState> emit,
  ) {
    emit(
      state.copyWith(
        collections: event.collections,
        visibleOrders: _applyFilters(
          state.orders,
          query: state.searchQuery,
          stageFilter: state.stageFilter,
          collections: event.collections,
          loads: state.loads,
        ),
      ),
    );
  }

  void _onLoadsUpdated(
    _JobWorkLoadsUpdated event,
    Emitter<JobWorkListState> emit,
  ) {
    emit(
      state.copyWith(
        loads: event.loads,
        awaitingQcCount: JobWorkLoadProductionHelper.awaitingQcCount(
          orders: state.orders,
          loads: event.loads,
          loadIdsWithQc: state.loadIdsWithQc,
          jobWorkIdsWithQc: state.jobWorkIdsWithQc,
        ),
        visibleOrders: _applyFilters(
          state.orders,
          query: state.searchQuery,
          stageFilter: state.stageFilter,
          collections: state.collections,
          loads: event.loads,
        ),
      ),
    );
  }

  Set<String> _jobWorkIdsWithQc(List<QualityCheck> checks) {
    return checks
        .where((check) => check.referenceType == QcReferenceType.jobWork)
        .map((check) => check.referenceId)
        .toSet();
  }

  Set<String> _loadIdsWithQc(List<QualityCheck> checks) {
    return checks
        .where((check) => check.referenceType == QcReferenceType.jobWorkLoad)
        .map((check) => check.referenceId)
        .toSet();
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
    required List<JobWorkCollection> collections,
    required List<JobWorkLoad> loads,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final loadsByJobWorkId = <String, List<JobWorkLoad>>{};
    for (final load in loads) {
      loadsByJobWorkId.putIfAbsent(load.jobWorkId, () => []).add(load);
    }

    final filtered = orders.where((order) {
      final orderCollections =
          JobWorkCollectionQuantityHelper.collectionsForOrder(
        order.id,
        collections,
      );
      if (stageFilter == JobWorkListStageFilter.pendingPickup) {
        if (!JobWorkCollectionQuantityHelper.isPendingPickup(
          order,
          orderCollections,
        )) {
          return false;
        }
      } else if (stageFilter == JobWorkListStageFilter.partiallyCollected) {
        final totals = JobWorkCollectionQuantityHelper.orderTotals(
          order,
          orderCollections,
        );
        final isPartial = order.status == JobWorkStatus.partiallyCollected ||
            (totals.hasCollections && !totals.isFullyCollected);
        if (!isPartial) return false;
      } else if (!stageFilter.matches(order.status)) {
        return false;
      }
      if (normalizedQuery.isEmpty) return true;

      final receiverNames = orderCollections
          .map((collection) => collection.receiverName)
          .whereType<String>()
          .where((name) => name.trim().isNotEmpty);

      final orderLoads = loadsByJobWorkId[order.id] ?? const [];
      final loadNumbers = orderLoads
          .map((load) => load.loadNumber)
          .where((number) => number.trim().isNotEmpty);

      final haystack = [
        order.jobWorkNumber,
        order.customerName,
        order.marbleVariety,
        order.mineLocation,
        order.mineOwner,
        order.status.label,
        ...receiverNames,
        ...loadNumbers,
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
    _collectionsSubscription?.cancel();
    _loadsSubscription?.cancel();
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

final class _JobWorkCollectionsUpdated extends JobWorkListEvent {
  const _JobWorkCollectionsUpdated(this.collections);

  final List<JobWorkCollection> collections;

  @override
  List<Object?> get props => [collections];
}

final class _JobWorkLoadsUpdated extends JobWorkListEvent {
  const _JobWorkLoadsUpdated(this.loads);

  final List<JobWorkLoad> loads;

  @override
  List<Object?> get props => [loads];
}
