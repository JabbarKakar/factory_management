part of 'job_work_list_bloc.dart';

sealed class JobWorkListEvent extends Equatable {
  const JobWorkListEvent();

  @override
  List<Object?> get props => [];
}

final class JobWorkListWatchStarted extends JobWorkListEvent {
  const JobWorkListWatchStarted(this.factoryId, {this.initialFilter});

  final String factoryId;
  final JobWorkListStageFilter? initialFilter;

  @override
  List<Object?> get props => [factoryId, initialFilter];
}

final class JobWorkListSearchChanged extends JobWorkListEvent {
  const JobWorkListSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class JobWorkListStageFilterChanged extends JobWorkListEvent {
  const JobWorkListStageFilterChanged(this.stageFilter);

  final JobWorkListStageFilter stageFilter;

  @override
  List<Object?> get props => [stageFilter];
}

final class JobWorkListDateRangeChanged extends JobWorkListEvent {
  const JobWorkListDateRangeChanged({this.fromDate, this.toDate});

  final DateTime? fromDate;
  final DateTime? toDate;

  @override
  List<Object?> get props => [fromDate, toDate];
}

final class _JobWorkListUpdated extends JobWorkListEvent {
  const _JobWorkListUpdated(this.orders);

  final List<JobWorkOrder> orders;

  @override
  List<Object?> get props => [orders];
}

final class _JobWorkListStreamFailed extends JobWorkListEvent {
  const _JobWorkListStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
