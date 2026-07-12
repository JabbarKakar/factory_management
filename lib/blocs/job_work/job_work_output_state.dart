part of 'job_work_output_bloc.dart';

enum JobWorkOutputStatus {
  initial,
  loading,
  ready,
  saving,
  saved,
  failure,
}

class JobWorkOutputState extends Equatable {
  const JobWorkOutputState({
    this.status = JobWorkOutputStatus.initial,
    this.load,
    this.errorMessage,
  });

  final JobWorkOutputStatus status;
  final JobWorkLoad? load;
  final String? errorMessage;

  JobWorkOutputState copyWith({
    JobWorkOutputStatus? status,
    JobWorkLoad? load,
    String? errorMessage,
  }) {
    return JobWorkOutputState(
      status: status ?? this.status,
      load: load ?? this.load,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, load, errorMessage];
}
