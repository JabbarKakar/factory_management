part of 'job_work_list_bloc.dart';

enum JobWorkListStatus { initial, loading, loaded, failure }

class JobWorkListState extends Equatable {
  const JobWorkListState({
    this.status = JobWorkListStatus.initial,
    this.orders = const [],
    this.visibleOrders = const [],
    this.searchQuery = '',
    this.showActiveOnly = true,
    this.stageFilter = JobWorkListStageFilter.all,
    this.errorMessage,
  });

  final JobWorkListStatus status;
  final List<JobWorkOrder> orders;
  final List<JobWorkOrder> visibleOrders;
  final String searchQuery;
  final bool showActiveOnly;
  final JobWorkListStageFilter stageFilter;
  final String? errorMessage;

  JobWorkListState copyWith({
    JobWorkListStatus? status,
    List<JobWorkOrder>? orders,
    List<JobWorkOrder>? visibleOrders,
    String? searchQuery,
    bool? showActiveOnly,
    JobWorkListStageFilter? stageFilter,
    String? errorMessage,
  }) {
    return JobWorkListState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      visibleOrders: visibleOrders ?? this.visibleOrders,
      searchQuery: searchQuery ?? this.searchQuery,
      showActiveOnly: showActiveOnly ?? this.showActiveOnly,
      stageFilter: stageFilter ?? this.stageFilter,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        orders,
        visibleOrders,
        searchQuery,
        showActiveOnly,
        stageFilter,
        errorMessage,
      ];
}
