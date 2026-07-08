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
    this.jobWorkId,
    this.errorMessage,
  });

  final JobWorkInvoiceStatus status;
  final JobWorkInvoice? invoice;
  final List<Payment> payments;
  final String? jobWorkId;
  final String? errorMessage;

  JobWorkInvoiceState copyWith({
    JobWorkInvoiceStatus? status,
    JobWorkInvoice? invoice,
    List<Payment>? payments,
    String? jobWorkId,
    String? errorMessage,
  }) {
    return JobWorkInvoiceState(
      status: status ?? this.status,
      invoice: invoice ?? this.invoice,
      payments: payments ?? this.payments,
      jobWorkId: jobWorkId ?? this.jobWorkId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        invoice,
        payments,
        jobWorkId,
        errorMessage,
      ];
}
