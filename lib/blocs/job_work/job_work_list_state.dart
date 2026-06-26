part of 'job_work_list_bloc.dart';

enum JobWorkListStatus { initial, loading, loaded, failure }

class JobWorkListState extends Equatable {
  const JobWorkListState({
    this.status = JobWorkListStatus.initial,
    this.orders = const [],
    this.visibleOrders = const [],
    this.searchQuery = '',
    this.showActiveOnly = true,
    this.errorMessage,
  });

  final JobWorkListStatus status;
  final List<JobWorkOrder> orders;
  final List<JobWorkOrder> visibleOrders;
  final String searchQuery;
  final bool showActiveOnly;
  final String? errorMessage;

  JobWorkListState copyWith({
    JobWorkListStatus? status,
    List<JobWorkOrder>? orders,
    List<JobWorkOrder>? visibleOrders,
    String? searchQuery,
    bool? showActiveOnly,
    String? errorMessage,
  }) {
    return JobWorkListState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      visibleOrders: visibleOrders ?? this.visibleOrders,
      searchQuery: searchQuery ?? this.searchQuery,
      showActiveOnly: showActiveOnly ?? this.showActiveOnly,
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
        errorMessage,
      ];
}
