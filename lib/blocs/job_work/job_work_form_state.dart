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
    this.invoices = const [],
    this.payments = const [],
    this.collections = const [],
    this.loads = const [],
    this.eligibleCustomers = const [],
    this.qualityChecks = const [],
    this.errorMessage,
    this.successMessage,
    this.isEditing = false,
  });

  final JobWorkFormStatus status;
  final JobWorkOrder? order;
  final JobWorkInvoice? invoice;
  final List<JobWorkInvoice> invoices;
  final List<Payment> payments;
  final List<JobWorkCollection> collections;
  final List<JobWorkLoad> loads;
  final List<Customer> eligibleCustomers;
  final List<QualityCheck> qualityChecks;
  final String? errorMessage;
  final String? successMessage;
  final bool isEditing;

  int get activeLoadCount => loads
      .where(
        (load) =>
            !load.status.isCompleted &&
            load.status != JobWorkStatus.cancelled,
      )
      .length;

  int get completedLoadCount =>
      loads.where((load) => load.status.isCompleted).length;

  JobWorkFormState copyWith({
    JobWorkFormStatus? status,
    JobWorkOrder? order,
    JobWorkInvoice? invoice,
    bool clearInvoice = false,
    List<JobWorkInvoice>? invoices,
    List<Payment>? payments,
    List<JobWorkCollection>? collections,
    List<JobWorkLoad>? loads,
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
      invoices: invoices ?? this.invoices,
      payments: payments ?? this.payments,
      collections: collections ?? this.collections,
      loads: loads ?? this.loads,
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
        invoices,
        payments,
        collections,
        loads,
        eligibleCustomers,
        qualityChecks,
        errorMessage,
        successMessage,
        isEditing,
      ];
}
