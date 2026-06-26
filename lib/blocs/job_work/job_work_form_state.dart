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
    this.errorMessage,
    this.isEditing = false,
  });

  final JobWorkFormStatus status;
  final JobWorkOrder? order;
  final List<Customer> eligibleCustomers;
  final String? errorMessage;
  final bool isEditing;

  JobWorkFormState copyWith({
    JobWorkFormStatus? status,
    JobWorkOrder? order,
    List<Customer>? eligibleCustomers,
    String? errorMessage,
    bool? isEditing,
  }) {
    return JobWorkFormState(
      status: status ?? this.status,
      order: order ?? this.order,
      eligibleCustomers: eligibleCustomers ?? this.eligibleCustomers,
      errorMessage: errorMessage,
      isEditing: isEditing ?? this.isEditing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        order,
        eligibleCustomers,
        errorMessage,
        isEditing,
      ];
}
