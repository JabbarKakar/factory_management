part of 'sales_invoice_bloc.dart';

sealed class SalesInvoiceEvent extends Equatable {
  const SalesInvoiceEvent();

  @override
  List<Object?> get props => [];
}

final class SalesInvoiceLoadByOrder extends SalesInvoiceEvent {
  const SalesInvoiceLoadByOrder(this.salesOrderId);

  final String salesOrderId;

  @override
  List<Object?> get props => [salesOrderId];
}

final class SalesInvoiceLoadById extends SalesInvoiceEvent {
  const SalesInvoiceLoadById(this.invoiceId);

  final String invoiceId;

  @override
  List<Object?> get props => [invoiceId];
}

final class SalesInvoiceGenerateRequested extends SalesInvoiceEvent {
  const SalesInvoiceGenerateRequested(this.salesOrderId);

  final String salesOrderId;

  @override
  List<Object?> get props => [salesOrderId];
}

final class SalesInvoicePaymentSubmitted extends SalesInvoiceEvent {
  const SalesInvoicePaymentSubmitted({
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
