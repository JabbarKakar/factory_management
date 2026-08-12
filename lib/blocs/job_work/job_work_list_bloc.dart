import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../../core/events/entity_reactive_event_bus.dart';

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
    on<JobWorkListFetchNext>(_onFetchNext);
    on<JobWorkListSearchChanged>(_onSearchChanged);
    on<JobWorkListStageFilterChanged>(_onStageFilterChanged);
    on<JobWorkListDateRangeChanged>(_onDateRangeChanged);
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
  StreamSubscription<List<JobWorkInvoice>>? _invoicesSubscription;
  StreamSubscription<List<QualityCheck>>? _qualityChecksSubscription;
  StreamSubscription<List<JobWorkCollection>>? _collectionsSubscription;
  StreamSubscription<List<JobWorkLoad>>? _loadsSubscription;
  StreamSubscription<EntityMutationEvent<JobWorkOrder>>? _jobWorkEventSub;

  JobWorkStatus? _statusFilterForJobWork(JobWorkListStageFilter filter) {
    return switch (filter) {
      JobWorkListStageFilter.inProgress => JobWorkStatus.inCutting,
      JobWorkListStageFilter.atQc => JobWorkStatus.qc,
      JobWorkListStageFilter.ready => JobWorkStatus.ready,
      JobWorkListStageFilter.completed => JobWorkStatus.closed,
      JobWorkListStageFilter.cancelled => JobWorkStatus.cancelled,
      _ => null,
    };
  }

  Future<void> _onWatchStarted(
    JobWorkListWatchStarted event,
    Emitter<JobWorkListState> emit,
  ) async {
    final stageFilter = event.initialFilter ?? state.stageFilter;
    emit(
      state.copyWith(
        status: JobWorkListStatus.loading,
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
      final paginated = await _repository.fetchJobWorkOrdersPage(
        factoryId: event.factoryId,
        statusFilter: _statusFilterForJobWork(stageFilter),
        fromDate: state.fromDate,
        toDate: state.toDate,
        limit: 20,
      );

      final visible = _filteredOrders(
        orders: paginated.items,
        query: state.searchQuery,
        stageFilter: stageFilter,
        fromDate: state.fromDate,
        toDate: state.toDate,
        collections: state.collections,
        loads: state.loads,
      );

      emit(
        state.copyWith(
          status: JobWorkListStatus.loaded,
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
          status: JobWorkListStatus.failure,
          isLoadingInitial: false,
          errorMessage: 'Could not load job work orders. Please try again.',
        ),
      );
    }

    _subscribeRelatedStreams(event.factoryId);
  }

  Future<void> _onFetchNext(
    JobWorkListFetchNext event,
    Emitter<JobWorkListState> emit,
  ) async {
    if (state.isLoadingMore ||
        state.isLoadingInitial ||
        !state.hasMoreData ||
        state.factoryId.isEmpty) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    try {
      final paginated = await _repository.fetchJobWorkOrdersPage(
        factoryId: state.factoryId,
        startAfter: state.lastDocument,
        statusFilter: _statusFilterForJobWork(state.stageFilter),
        fromDate: state.fromDate,
        toDate: state.toDate,
        limit: 20,
      );

      final combined = [...state.orders, ...paginated.items];
      final visible = _filteredOrders(
        orders: combined,
        query: state.searchQuery,
        stageFilter: state.stageFilter,
        fromDate: state.fromDate,
        toDate: state.toDate,
        collections: state.collections,
        loads: state.loads,
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

  void _subscribeRelatedStreams(String factoryId) {
    _invoicesSubscription?.cancel();
    _qualityChecksSubscription?.cancel();
    _collectionsSubscription?.cancel();
    _loadsSubscription?.cancel();

    _invoicesSubscription =
        _invoiceRepository.watchInvoicesForFactory(factoryId).listen(
      (invoices) => add(_JobWorkInvoicesUpdated(invoices)),
      onError: (_) {},
    );

    _qualityChecksSubscription = _qualityCheckRepository
        .watchQualityChecks(factoryId)
        .listen(
          (checks) => add(_JobWorkQualityChecksUpdated(checks)),
          onError: (_) {},
        );

    _collectionsSubscription = _collectionRepository
        .watchCollections(factoryId)
        .listen(
          (collections) => add(_JobWorkCollectionsUpdated(collections)),
          onError: (_) {},
        );

    _loadsSubscription = _loadRepository.watchLoads(factoryId).listen(
          (loads) => add(_JobWorkLoadsUpdated(loads)),
          onError: (_) {},
        );

    _jobWorkEventSub?.cancel();
    _jobWorkEventSub =
        EntityReactiveEventBus.instance.on<JobWorkOrder>().listen((evt) {
      if (evt.type == EntityMutationType.created) {
        final updatedOrders = [
          evt.entity,
          ...state.orders.where((o) => o.id != evt.entity.id),
        ];
        add(_JobWorkListUpdated(updatedOrders));
      } else if (evt.type == EntityMutationType.updated) {
        final updatedOrders = state.orders
            .map((o) => o.id == evt.entity.id ? evt.entity : o)
            .toList();
        add(_JobWorkListUpdated(updatedOrders));
      } else if (evt.type == EntityMutationType.deleted) {
        final updatedOrders =
            state.orders.where((o) => o.id != evt.entity.id).toList();
        add(_JobWorkListUpdated(updatedOrders));
      }
    });
  }

  void _onSearchChanged(
    JobWorkListSearchChanged event,
    Emitter<JobWorkListState> emit,
  ) {
    emit(
      state.copyWith(
        searchQuery: event.query,
        visibleOrders: _filteredOrders(
          orders: state.orders,
          query: event.query,
          stageFilter: state.stageFilter,
          fromDate: state.fromDate,
          toDate: state.toDate,
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
        visibleOrders: _filteredOrders(
          orders: state.orders,
          query: state.searchQuery,
          stageFilter: event.stageFilter,
          fromDate: state.fromDate,
          toDate: state.toDate,
          collections: state.collections,
          loads: state.loads,
        ),
      ),
    );
  }

  void _onDateRangeChanged(
    JobWorkListDateRangeChanged event,
    Emitter<JobWorkListState> emit,
  ) {
    final clear = event.fromDate == null && event.toDate == null;
    emit(
      state.copyWith(
        fromDate: event.fromDate,
        toDate: event.toDate,
        clearDateFilter: clear,
        visibleOrders: _filteredOrders(
          orders: state.orders,
          query: state.searchQuery,
          stageFilter: state.stageFilter,
          fromDate: event.fromDate,
          toDate: event.toDate,
          collections: state.collections,
          loads: state.loads,
        ),
      ),
    );
  }

  List<JobWorkOrder> _filteredOrders({
    required List<JobWorkOrder> orders,
    required String query,
    required JobWorkListStageFilter stageFilter,
    required DateTime? fromDate,
    required DateTime? toDate,
    required List<JobWorkCollection> collections,
    required List<JobWorkLoad> loads,
  }) {
    return _applyFilters(
      orders,
      query: query,
      stageFilter: stageFilter,
      fromDate: fromDate,
      toDate: toDate,
      collections: collections,
      loads: loads,
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
        visibleOrders: _filteredOrders(
          orders: event.orders,
          query: state.searchQuery,
          stageFilter: state.stageFilter,
          fromDate: state.fromDate,
          toDate: state.toDate,
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
    final invoicesByJobWorkId = <String, List<JobWorkInvoice>>{};
    for (final invoice in event.invoices) {
      invoicesByJobWorkId
          .putIfAbsent(invoice.jobWorkId, () => <JobWorkInvoice>[])
          .add(invoice);
    }
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
        visibleOrders: _filteredOrders(
          orders: state.orders,
          query: state.searchQuery,
          stageFilter: state.stageFilter,
          fromDate: state.fromDate,
          toDate: state.toDate,
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
        visibleOrders: _filteredOrders(
          orders: state.orders,
          query: state.searchQuery,
          stageFilter: state.stageFilter,
          fromDate: state.fromDate,
          toDate: state.toDate,
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
        visibleOrders: _filteredOrders(
          orders: state.orders,
          query: state.searchQuery,
          stageFilter: state.stageFilter,
          fromDate: state.fromDate,
          toDate: state.toDate,
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
    required DateTime? fromDate,
    required DateTime? toDate,
    required List<JobWorkCollection> collections,
    required List<JobWorkLoad> loads,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final rangeStart = fromDate == null
        ? null
        : DateTime(fromDate.year, fromDate.month, fromDate.day);
    final rangeEnd = toDate == null
        ? null
        : DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999);
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
      final orderLoads = loadsByJobWorkId[order.id] ?? const <JobWorkLoad>[];
      final displayStatus =
          JobWorkCollectionQuantityHelper.displayStatusForOrder(
        order: order,
        loads: orderLoads,
      );

      if (stageFilter == JobWorkListStageFilter.all) {
        // Keep all orders (still may filter by date/search below).
      } else if (stageFilter == JobWorkListStageFilter.pendingPickup) {
        if (!JobWorkCollectionQuantityHelper.isPendingPickupForOrder(
          order: order,
          collections: collections,
          loads: loads,
        )) {
          return false;
        }
      } else if (stageFilter == JobWorkListStageFilter.cancelled) {
        if (order.status != JobWorkStatus.cancelled &&
            !(orderLoads.isEmpty && stageFilter.matches(order.status))) {
          return false;
        }
      } else if (orderLoads.isEmpty) {
        if (!stageFilter.matches(order.status)) return false;
      } else if (!orderLoads.any((load) => stageFilter.matches(load.status))) {
        return false;
      }

      if (rangeStart != null || rangeEnd != null) {
        if (!_matchesDateRange(
          order: order,
          loads: orderLoads,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        )) {
          return false;
        }
      }

      if (normalizedQuery.isEmpty) return true;

      final receiverNames = orderCollections
          .map((collection) => collection.receiverName)
          .whereType<String>()
          .where((name) => name.trim().isNotEmpty);

      final loadNumbers = orderLoads
          .map((load) => load.loadNumber)
          .where((number) => number.trim().isNotEmpty);

      final haystack = [
        order.jobWorkNumber,
        order.customerName,
        order.marbleVariety,
        order.mineLocation,
        order.mineOwner,
        displayStatus.label,
        ...receiverNames,
        ...loadNumbers,
        ...order.smallSizes,
        ...order.largeSizes,
        ...order.legacySizes,
        for (final load in orderLoads) ...[
          load.marbleVariety,
          load.mineLocation,
          load.mineOwner,
          ...load.smallSizes,
          ...load.largeSizes,
          ...load.legacySizes,
          load.status.label,
        ],
      ].join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList();

    filtered.sort((a, b) {
      final aStatus = JobWorkCollectionQuantityHelper.displayStatusForOrder(
        order: a,
        loads: loadsByJobWorkId[a.id] ?? const [],
      );
      final bStatus = JobWorkCollectionQuantityHelper.displayStatusForOrder(
        order: b,
        loads: loadsByJobWorkId[b.id] ?? const [],
      );
      final rankCompare =
          aStatus.listSortRank.compareTo(bStatus.listSortRank);
      if (rankCompare != 0) return rankCompare;
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  bool _matchesDateRange({
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
    required DateTime? rangeStart,
    required DateTime? rangeEnd,
  }) {
    bool inRange(DateTime date) {
      if (rangeStart != null && date.isBefore(rangeStart)) return false;
      if (rangeEnd != null && date.isAfter(rangeEnd)) return false;
      return true;
    }

    final persisted = loads.where((load) => !load.isVirtual).toList();
    if (persisted.isNotEmpty) {
      return persisted.any((load) => inRange(load.receivedDate));
    }
    return inRange(order.receivedDate);
  }

  @override
  Future<void> close() {
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
