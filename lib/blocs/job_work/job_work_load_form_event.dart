part of 'job_work_load_form_bloc.dart';

sealed class JobWorkLoadFormEvent extends Equatable {
  const JobWorkLoadFormEvent();

  @override
  List<Object?> get props => [];
}

final class JobWorkLoadFormInitialized extends JobWorkLoadFormEvent {
  const JobWorkLoadFormInitialized({required this.jobWorkId});

  final String jobWorkId;

  @override
  List<Object?> get props => [jobWorkId];
}

final class JobWorkLoadFormSubmitted extends JobWorkLoadFormEvent {
  const JobWorkLoadFormSubmitted(this.load);

  final JobWorkLoad load;

  @override
  List<Object?> get props => [load];
}
