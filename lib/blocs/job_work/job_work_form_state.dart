part of 'job_work_form_bloc.dart';

enum JobWorkFormStatus {
  initial,
  loading,
  ready,
  saving,
  saved,
  cancelled,
  failure,
}

class JobWorkFormState extends Equatable {
  const JobWorkFormState({
    this.status = JobWorkFormStatus.initial,
    this.order,
    this.eligibleCustomers = const [],
    this.qualityChecks = const [],
    this.errorMessage,
    this.successMessage,
    this.isEditing = false,
  });

  final JobWorkFormStatus status;
  final JobWorkOrder? order;
  final List<Customer> eligibleCustomers;
  final List<QualityCheck> qualityChecks;
  final String? errorMessage;
  final String? successMessage;
  final bool isEditing;

  JobWorkFormState copyWith({
    JobWorkFormStatus? status,
    JobWorkOrder? order,
    List<Customer>? eligibleCustomers,
    List<QualityCheck>? qualityChecks,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
    bool? isEditing,
  }) {
    return JobWorkFormState(
      status: status ?? this.status,
      order: order ?? this.order,
      eligibleCustomers: eligibleCustomers ?? this.eligibleCustomers,
      qualityChecks: qualityChecks ?? this.qualityChecks,
      errorMessage: clearMessages ? null : errorMessage,
      successMessage: clearMessages ? null : successMessage,
      isEditing: isEditing ?? this.isEditing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        order,
        eligibleCustomers,
        qualityChecks,
        errorMessage,
        successMessage,
        isEditing,
      ];
}
