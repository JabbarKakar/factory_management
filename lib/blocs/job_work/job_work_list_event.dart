part of 'job_work_list_bloc.dart';

sealed class JobWorkListEvent extends Equatable {
  const JobWorkListEvent();

  @override
  List<Object?> get props => [];
}

final class JobWorkListWatchStarted extends JobWorkListEvent {
  const JobWorkListWatchStarted(this.factoryId);

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

final class JobWorkListSearchChanged extends JobWorkListEvent {
  const JobWorkListSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class JobWorkListStatusFilterChanged extends JobWorkListEvent {
  const JobWorkListStatusFilterChanged(this.showActiveOnly);

  final bool showActiveOnly;

  @override
  List<Object?> get props => [showActiveOnly];
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
