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
    this.invoice,
    this.payments = const [],
    this.collections = const [],
    this.eligibleCustomers = const [],
    this.qualityChecks = const [],
    this.errorMessage,
    this.successMessage,
    this.isEditing = false,
  });

  final JobWorkFormStatus status;
  final JobWorkOrder? order;
  final JobWorkInvoice? invoice;
  final List<Payment> payments;
  final List<JobWorkCollection> collections;
  final List<Customer> eligibleCustomers;
  final List<QualityCheck> qualityChecks;
  final String? errorMessage;
  final String? successMessage;
  final bool isEditing;

  JobWorkFormState copyWith({
    JobWorkFormStatus? status,
    JobWorkOrder? order,
    JobWorkInvoice? invoice,
    bool clearInvoice = false,
    List<Payment>? payments,
    List<JobWorkCollection>? collections,
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
      invoice: clearInvoice ? null : (invoice ?? this.invoice),
      payments: payments ?? this.payments,
      collections: collections ?? this.collections,
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
        invoice,
        payments,
        collections,
        eligibleCustomers,
        qualityChecks,
        errorMessage,
        successMessage,
        isEditing,
      ];
}
