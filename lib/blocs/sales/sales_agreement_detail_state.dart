part of 'sales_agreement_detail_bloc.dart';

enum SalesAgreementDetailStatus { initial, loading, ready, failure }

class SalesAgreementDetailState extends Equatable {
  const SalesAgreementDetailState({
    this.status = SalesAgreementDetailStatus.initial,
    this.agreement,
    this.orders = const [],
    this.invoices = const [],
    this.errorMessage,
  });

  final SalesAgreementDetailStatus status;
  final SalesAgreement? agreement;
  final List<SalesOrder> orders;
  final List<SalesInvoice> invoices;
  final String? errorMessage;

  SalesAgreementDetailState copyWith({
    SalesAgreementDetailStatus? status,
    SalesAgreement? agreement,
    List<SalesOrder>? orders,
    List<SalesInvoice>? invoices,
    String? errorMessage,
  }) {
    return SalesAgreementDetailState(
      status: status ?? this.status,
      agreement: agreement ?? this.agreement,
      orders: orders ?? this.orders,
      invoices: invoices ?? this.invoices,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        agreement,
        orders,
        invoices,
        errorMessage,
      ];
}
