part of 'job_work_invoice_bloc.dart';

sealed class JobWorkInvoiceEvent extends Equatable {
  const JobWorkInvoiceEvent();

  @override
  List<Object?> get props => [];
}

final class JobWorkInvoiceLoadByJobWork extends JobWorkInvoiceEvent {
  const JobWorkInvoiceLoadByJobWork({
    required this.factoryId,
    required this.jobWorkId,
  });

  final String factoryId;
  final String jobWorkId;

  @override
  List<Object?> get props => [factoryId, jobWorkId];
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

final class JobWorkInvoicePaymentUpdated extends JobWorkInvoiceEvent {
  const JobWorkInvoicePaymentUpdated({
    required this.paymentId,
    required this.amount,
    required this.method,
    required this.paymentDate,
    this.reference,
    this.notes,
  });

  final String paymentId;
  final double amount;
  final PaymentMethod method;
  final DateTime paymentDate;
  final String? reference;
  final String? notes;

  @override
  List<Object?> get props => [
        paymentId,
        amount,
        method,
        paymentDate,
        reference,
        notes,
      ];
}

final class JobWorkInvoicePaymentDeleteRequested extends JobWorkInvoiceEvent {
  const JobWorkInvoicePaymentDeleteRequested(this.paymentId);

  final String paymentId;

  @override
  List<Object?> get props => [paymentId];
}

final class JobWorkInvoiceUpdateRequested extends JobWorkInvoiceEvent {
  const JobWorkInvoiceUpdateRequested({
    required this.lineItems,
    this.dueDate,
    this.mineLocation,
    this.mineOwner,
  });

  final List<InvoiceLineItem> lineItems;
  final DateTime? dueDate;
  final String? mineLocation;
  final String? mineOwner;

  @override
  List<Object?> get props => [
        lineItems,
        dueDate,
        mineLocation,
        mineOwner,
      ];
}

final class _JobWorkInvoiceStreamUpdated extends JobWorkInvoiceEvent {
  const _JobWorkInvoiceStreamUpdated(this.invoice);

  final JobWorkInvoice? invoice;

  @override
  List<Object?> get props => [invoice];
}

final class _JobWorkInvoicePaymentsUpdated extends JobWorkInvoiceEvent {
  const _JobWorkInvoicePaymentsUpdated(this.payments);

  final List<Payment> payments;

  @override
  List<Object?> get props => [payments];
}
