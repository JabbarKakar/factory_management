part of 'job_work_invoice_bloc.dart';

enum JobWorkInvoiceStatus {
  initial,
  loading,
  loaded,
  notFound,
  saving,
  generated,
  paymentRecorded,
  updated,
  failure,
}

class JobWorkInvoiceState extends Equatable {
  const JobWorkInvoiceState({
    this.status = JobWorkInvoiceStatus.initial,
    this.invoice,
    this.payments = const [],
    this.loads = const [],
    this.perLoadFinance = const {},
    this.jobWorkId,
    this.loadId,
    this.errorMessage,
  });

  final JobWorkInvoiceStatus status;
  final JobWorkInvoice? invoice;
  final List<Payment> payments;
  final List<JobWorkLoad> loads;
  final Map<String, ({double charges, double paid, double due, double credit})>
      perLoadFinance;
  final String? jobWorkId;
  final String? loadId;
  final String? errorMessage;

  JobWorkInvoiceState copyWith({
    JobWorkInvoiceStatus? status,
    JobWorkInvoice? invoice,
    List<Payment>? payments,
    List<JobWorkLoad>? loads,
    Map<String, ({double charges, double paid, double due, double credit})>?
        perLoadFinance,
    String? jobWorkId,
    String? loadId,
    bool clearLoadId = false,
    String? errorMessage,
  }) {
    return JobWorkInvoiceState(
      status: status ?? this.status,
      invoice: invoice ?? this.invoice,
      payments: payments ?? this.payments,
      loads: loads ?? this.loads,
      perLoadFinance: perLoadFinance ?? this.perLoadFinance,
      jobWorkId: jobWorkId ?? this.jobWorkId,
      loadId: clearLoadId ? null : (loadId ?? this.loadId),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        invoice,
        payments,
        loads,
        perLoadFinance,
        jobWorkId,
        loadId,
        errorMessage,
      ];
}
