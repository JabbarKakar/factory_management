part of 'job_work_form_bloc.dart';

sealed class JobWorkFormEvent extends Equatable {
  const JobWorkFormEvent();

  @override
  List<Object?> get props => [];
}

final class JobWorkFormInitialized extends JobWorkFormEvent {
  const JobWorkFormInitialized({required this.factoryId});

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

final class JobWorkFormLoadRequested extends JobWorkFormEvent {
  const JobWorkFormLoadRequested(this.jobWorkId);

  final String jobWorkId;

  @override
  List<Object?> get props => [jobWorkId];
}

final class JobWorkFormSubmitted extends JobWorkFormEvent {
  const JobWorkFormSubmitted(this.order);

  final JobWorkOrder order;

  @override
  List<Object?> get props => [order];
}

final class JobWorkFormCancelRequested extends JobWorkFormEvent {
  const JobWorkFormCancelRequested(this.jobWorkId);

  final String jobWorkId;

  @override
  List<Object?> get props => [jobWorkId];
}

final class JobWorkFormStatusAdvanceRequested extends JobWorkFormEvent {
  const JobWorkFormStatusAdvanceRequested({
    required this.jobWorkId,
    required this.newStatus,
  });

  final String jobWorkId;
  final JobWorkStatus newStatus;

  @override
  List<Object?> get props => [jobWorkId, newStatus];
}

final class JobWorkFormCompletionRequested extends JobWorkFormEvent {
  const JobWorkFormCompletionRequested({
    required this.jobWorkId,
    required this.newStatus,
  });

  final String jobWorkId;
  final JobWorkStatus newStatus;

  @override
  List<Object?> get props => [jobWorkId, newStatus];
}

final class JobWorkFormLoadStatusAdvanceRequested extends JobWorkFormEvent {
  const JobWorkFormLoadStatusAdvanceRequested({
    required this.loadId,
    required this.newStatus,
  });

  final String loadId;
  final JobWorkStatus newStatus;

  @override
  List<Object?> get props => [loadId, newStatus];
}

final class JobWorkFormLoadCompletionRequested extends JobWorkFormEvent {
  const JobWorkFormLoadCompletionRequested({
    required this.loadId,
    required this.newStatus,
  });

  final String loadId;
  final JobWorkStatus newStatus;

  @override
  List<Object?> get props => [loadId, newStatus];
}
