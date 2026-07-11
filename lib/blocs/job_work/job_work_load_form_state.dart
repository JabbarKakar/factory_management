part of 'job_work_load_form_bloc.dart';

enum JobWorkLoadFormStatus {
  initial,
  loading,
  ready,
  saving,
  saved,
  failure,
}

class JobWorkLoadFormState extends Equatable {
  const JobWorkLoadFormState({
    this.status = JobWorkLoadFormStatus.initial,
    this.parentOrder,
    this.draft,
    this.errorMessage,
  });

  final JobWorkLoadFormStatus status;
  final JobWorkOrder? parentOrder;
  final JobWorkLoad? draft;
  final String? errorMessage;

  JobWorkLoadFormState copyWith({
    JobWorkLoadFormStatus? status,
    JobWorkOrder? parentOrder,
    JobWorkLoad? draft,
    String? errorMessage,
    bool clearError = false,
  }) {
    return JobWorkLoadFormState(
      status: status ?? this.status,
      parentOrder: parentOrder ?? this.parentOrder,
      draft: draft ?? this.draft,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, parentOrder, draft, errorMessage];
}
