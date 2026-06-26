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
    this.order,
    this.errorMessage,
  });

  final JobWorkOutputStatus status;
  final JobWorkOrder? order;
  final String? errorMessage;

  JobWorkOutputState copyWith({
    JobWorkOutputStatus? status,
    JobWorkOrder? order,
    String? errorMessage,
  }) {
    return JobWorkOutputState(
      status: status ?? this.status,
      order: order ?? this.order,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, order, errorMessage];
}
