part of 'job_work_output_bloc.dart';

sealed class JobWorkOutputEvent extends Equatable {
  const JobWorkOutputEvent();

  @override
  List<Object?> get props => [];
}

final class JobWorkOutputLoadRequested extends JobWorkOutputEvent {
  const JobWorkOutputLoadRequested(this.jobWorkId);

  final String jobWorkId;

  @override
  List<Object?> get props => [jobWorkId];
}

final class JobWorkOutputSubmitted extends JobWorkOutputEvent {
  const JobWorkOutputSubmitted(this.order);

  final JobWorkOrder order;

  @override
  List<Object?> get props => [order];
}
