part of 'job_work_invoice_bloc.dart';

sealed class JobWorkInvoiceEvent extends Equatable {
  const JobWorkInvoiceEvent();

  @override
  List<Object?> get props => [];
}

final class JobWorkInvoiceLoadByJobWork extends JobWorkInvoiceEvent {
  const JobWorkInvoiceLoadByJobWork(this.jobWorkId);

  final String jobWorkId;

  @override
  List<Object?> get props => [jobWorkId];
}

final class JobWorkInvoiceLoadById extends JobWorkInvoiceEvent {
  const JobWorkInvoiceLoadById(this.invoiceId);

  final String invoiceId;

  @override
  List<Object?> get props => [invoiceId];
}

final class JobWorkInvoiceGenerateRequested extends JobWorkInvoiceEvent {
  const JobWorkInvoiceGenerateRequested(this.jobWorkId);

  final String jobWorkId;

  @override
  List<Object?> get props => [jobWorkId];
}

final class JobWorkInvoicePaymentSubmitted extends JobWorkInvoiceEvent {
  const JobWorkInvoicePaymentSubmitted({
    required this.invoiceId,
    required this.amount,
    required this.method,
    required this.paymentDate,
    this.reference,
    this.notes,
  });

  final String invoiceId;
  final double amount;
  final PaymentMethod method;
  final DateTime paymentDate;
  final String? reference;
  final String? notes;

  @override
  List<Object?> get props => [
        invoiceId,
        amount,
        method,
        paymentDate,
        reference,
        notes,
      ];
}
