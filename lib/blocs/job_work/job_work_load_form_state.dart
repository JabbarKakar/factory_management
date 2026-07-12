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
    this.isEditing = false,
    this.errorMessage,
  });

  final JobWorkLoadFormStatus status;
  final JobWorkOrder? parentOrder;
  final JobWorkLoad? draft;
  final bool isEditing;
  final String? errorMessage;

  JobWorkLoadFormState copyWith({
    JobWorkLoadFormStatus? status,
    JobWorkOrder? parentOrder,
    JobWorkLoad? draft,
    bool? isEditing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return JobWorkLoadFormState(
      status: status ?? this.status,
      parentOrder: parentOrder ?? this.parentOrder,
      draft: draft ?? this.draft,
      isEditing: isEditing ?? this.isEditing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, parentOrder, draft, isEditing, errorMessage];
}
