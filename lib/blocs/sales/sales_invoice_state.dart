part of 'sales_invoice_bloc.dart';

enum SalesInvoiceStatus {
  initial,
  loading,
  loaded,
  notFound,
  saving,
  generated,
  paymentRecorded,
  failure,
}

class SalesInvoiceState extends Equatable {
  const SalesInvoiceState({
    this.status = SalesInvoiceStatus.initial,
    this.invoice,
    this.payments = const [],
    this.salesOrderId,
    this.errorMessage,
  });

  final SalesInvoiceStatus status;
  final SalesInvoice? invoice;
  final List<Payment> payments;
  final String? salesOrderId;
  final String? errorMessage;

  SalesInvoiceState copyWith({
    SalesInvoiceStatus? status,
    SalesInvoice? invoice,
    List<Payment>? payments,
    String? salesOrderId,
    String? errorMessage,
  }) {
    return SalesInvoiceState(
      status: status ?? this.status,
      invoice: invoice ?? this.invoice,
      payments: payments ?? this.payments,
      salesOrderId: salesOrderId ?? this.salesOrderId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        invoice,
        payments,
        salesOrderId,
        errorMessage,
      ];
}
