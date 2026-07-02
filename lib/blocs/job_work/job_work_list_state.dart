part of 'job_work_list_bloc.dart';

enum JobWorkListStatus { initial, loading, loaded, failure }

class JobWorkListState extends Equatable {
  const JobWorkListState({
    this.status = JobWorkListStatus.initial,
    this.orders = const [],
    this.visibleOrders = const [],
    this.qualityChecks = const [],
    this.jobWorkIdsWithQc = const {},
    this.awaitingQcCount = 0,
    this.searchQuery = '',
    this.stageFilter = JobWorkListStageFilter.all,
    this.errorMessage,
  });

  final JobWorkListStatus status;
  final List<JobWorkOrder> orders;
  final List<JobWorkOrder> visibleOrders;
  final List<QualityCheck> qualityChecks;
  final Set<String> jobWorkIdsWithQc;
  final int awaitingQcCount;
  final String searchQuery;
  final JobWorkListStageFilter stageFilter;
  final String? errorMessage;

  bool isAwaitingQcInspection(JobWorkOrder order) {
    return order.status == JobWorkStatus.qc &&
        !jobWorkIdsWithQc.contains(order.id);
  }

  JobWorkListState copyWith({
    JobWorkListStatus? status,
    List<JobWorkOrder>? orders,
    List<JobWorkOrder>? visibleOrders,
    List<QualityCheck>? qualityChecks,
    Set<String>? jobWorkIdsWithQc,
    int? awaitingQcCount,
    String? searchQuery,
    JobWorkListStageFilter? stageFilter,
    String? errorMessage,
  }) {
    return JobWorkListState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      visibleOrders: visibleOrders ?? this.visibleOrders,
      qualityChecks: qualityChecks ?? this.qualityChecks,
      jobWorkIdsWithQc: jobWorkIdsWithQc ?? this.jobWorkIdsWithQc,
      awaitingQcCount: awaitingQcCount ?? this.awaitingQcCount,
      searchQuery: searchQuery ?? this.searchQuery,
      stageFilter: stageFilter ?? this.stageFilter,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        orders,
        visibleOrders,
        qualityChecks,
        jobWorkIdsWithQc,
        awaitingQcCount,
        searchQuery,
        stageFilter,
        errorMessage,
      ];
}
