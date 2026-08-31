part of 'job_work_list_bloc.dart';

enum JobWorkListStatus { initial, loading, loaded, failure }

class JobWorkListState extends Equatable {
  const JobWorkListState({
    this.status = JobWorkListStatus.initial,
    this.orders = const [],
    this.visibleOrders = const [],
    this.qualityChecks = const [],
    this.collections = const [],
    this.loads = const [],
    this.payments = const [],
    this.jobWorkIdsWithQc = const {},
    this.loadIdsWithQc = const {},
    this.awaitingQcCount = 0,
    this.searchQuery = '',
    this.stageFilter = JobWorkListStageFilter.all,
    this.fromDate,
    this.toDate,
    this.errorMessage,
    this.invoicesByJobWorkId = const {},
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.hasMoreData = true,
    this.lastDocument,
    this.factoryId = '',
  });

  final JobWorkListStatus status;
  final List<JobWorkOrder> orders;
  final List<JobWorkOrder> visibleOrders;
  final List<QualityCheck> qualityChecks;
  final List<JobWorkCollection> collections;
  final List<JobWorkLoad> loads;
  final List<Payment> payments;
  final Set<String> jobWorkIdsWithQc;
  final Set<String> loadIdsWithQc;
  final int awaitingQcCount;
  final String searchQuery;
  final JobWorkListStageFilter stageFilter;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? errorMessage;
  /// All invoices for each Job Work (multi-Load factories have many entries).
  final Map<String, List<JobWorkInvoice>> invoicesByJobWorkId;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool hasMoreData;
  final DocumentSnapshot? lastDocument;
  final String factoryId;

  bool get hasDateFilter => fromDate != null || toDate != null;

  bool isAwaitingQcInspection(JobWorkOrder order) {
    return JobWorkLoadProductionHelper.isAwaitingQcInspection(
      order: order,
      loads: loads,
      loadIdsWithQc: loadIdsWithQc,
      jobWorkIdsWithQc: jobWorkIdsWithQc,
    );
  }

  List<JobWorkLoad> loadsForOrder(String jobWorkId) {
    return loads.where((load) => load.jobWorkId == jobWorkId).toList();
  }

  List<JobWorkInvoice> invoicesForOrder(String jobWorkId) {
    final direct = invoicesByJobWorkId[jobWorkId] ?? const [];
    final order = orders.where((item) => item.id == jobWorkId).firstOrNull;
    final loads = loadsForOrder(jobWorkId);
    final extraIds = <String>{
      if (order?.invoiceId != null && order!.invoiceId!.trim().isNotEmpty)
        order.invoiceId!.trim(),
      for (final load in loads)
        if (load.invoiceId != null && load.invoiceId!.trim().isNotEmpty)
          load.invoiceId!.trim(),
    };
    if (extraIds.isEmpty) return direct;

    final byId = <String, JobWorkInvoice>{
      for (final invoice in invoicesByJobWorkId.values.expand((items) => items))
        invoice.id: invoice,
    };
    final merged = <String, JobWorkInvoice>{
      for (final invoice in direct) invoice.id: invoice,
    };
    for (final id in extraIds) {
      final invoice = byId[id];
      if (invoice != null) merged[invoice.id] = invoice;
    }
    return merged.values.toList();
  }

  List<Payment> paymentsForOrder(String jobWorkId) {
    final order = orders.where((item) => item.id == jobWorkId).firstOrNull;
    if (order == null) return const [];
    final siblingOrderIds = {
      for (final item in orders)
        if (item.customerId == order.customerId && item.id != order.id) item.id,
    };
    return JobWorkContainerSyncHelper.relevantPaymentsForJobWork(
      order: order,
      loads: loadsForOrder(jobWorkId),
      invoices: invoicesForOrder(jobWorkId),
      payments: payments,
      siblingOrderIds: siblingOrderIds,
      attachDanglingCustomerPayments: siblingOrderIds.isEmpty,
    );
  }

  JobWorkListState copyWith({
    JobWorkListStatus? status,
    List<JobWorkOrder>? orders,
    List<JobWorkOrder>? visibleOrders,
    List<QualityCheck>? qualityChecks,
    List<JobWorkCollection>? collections,
    List<JobWorkLoad>? loads,
    List<Payment>? payments,
    Set<String>? jobWorkIdsWithQc,
    Set<String>? loadIdsWithQc,
    int? awaitingQcCount,
    String? searchQuery,
    JobWorkListStageFilter? stageFilter,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearDateFilter = false,
    String? errorMessage,
    Map<String, List<JobWorkInvoice>>? invoicesByJobWorkId,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMoreData,
    DocumentSnapshot? lastDocument,
    bool clearLastDocument = false,
    String? factoryId,
  }) {
    return JobWorkListState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      visibleOrders: visibleOrders ?? this.visibleOrders,
      qualityChecks: qualityChecks ?? this.qualityChecks,
      collections: collections ?? this.collections,
      loads: loads ?? this.loads,
      payments: payments ?? this.payments,
      jobWorkIdsWithQc: jobWorkIdsWithQc ?? this.jobWorkIdsWithQc,
      loadIdsWithQc: loadIdsWithQc ?? this.loadIdsWithQc,
      awaitingQcCount: awaitingQcCount ?? this.awaitingQcCount,
      searchQuery: searchQuery ?? this.searchQuery,
      stageFilter: stageFilter ?? this.stageFilter,
      fromDate: clearDateFilter ? null : (fromDate ?? this.fromDate),
      toDate: clearDateFilter ? null : (toDate ?? this.toDate),
      errorMessage: errorMessage,
      invoicesByJobWorkId: invoicesByJobWorkId ?? this.invoicesByJobWorkId,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      lastDocument:
          clearLastDocument ? null : (lastDocument ?? this.lastDocument),
      factoryId: factoryId ?? this.factoryId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        orders,
        visibleOrders,
        qualityChecks,
        collections,
        loads,
        payments,
        jobWorkIdsWithQc,
        loadIdsWithQc,
        awaitingQcCount,
        searchQuery,
        stageFilter,
        fromDate,
        toDate,
        errorMessage,
        invoicesByJobWorkId,
        isLoadingInitial,
        isLoadingMore,
        hasMoreData,
        lastDocument,
        factoryId,
      ];
}
