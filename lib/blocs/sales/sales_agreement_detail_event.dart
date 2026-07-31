part of 'sales_agreement_detail_bloc.dart';

sealed class SalesAgreementDetailEvent extends Equatable {
  const SalesAgreementDetailEvent();

  @override
  List<Object?> get props => [];
}

final class SalesAgreementDetailWatchStarted extends SalesAgreementDetailEvent {
  const SalesAgreementDetailWatchStarted(this.agreementId);

  final String agreementId;

  @override
  List<Object?> get props => [agreementId];
}

final class SalesAgreementDetailRefreshRequested
    extends SalesAgreementDetailEvent {
  const SalesAgreementDetailRefreshRequested();
}

final class _SalesAgreementDetailAgreementUpdated
    extends SalesAgreementDetailEvent {
  const _SalesAgreementDetailAgreementUpdated(this.agreement);

  final SalesAgreement? agreement;

  @override
  List<Object?> get props => [agreement];
}

final class _SalesAgreementDetailOrdersUpdated
    extends SalesAgreementDetailEvent {
  const _SalesAgreementDetailOrdersUpdated(this.orders);

  final List<SalesOrder> orders;

  @override
  List<Object?> get props => [orders];
}

final class _SalesAgreementDetailInvoicesUpdated
    extends SalesAgreementDetailEvent {
  const _SalesAgreementDetailInvoicesUpdated(this.invoices);

  final List<SalesInvoice> invoices;

  @override
  List<Object?> get props => [invoices];
}

final class _SalesAgreementDetailFailed extends SalesAgreementDetailEvent {
  const _SalesAgreementDetailFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
