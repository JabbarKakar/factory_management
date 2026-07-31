part of 'sales_agreement_list_bloc.dart';

sealed class SalesAgreementListEvent extends Equatable {
  const SalesAgreementListEvent();

  @override
  List<Object?> get props => [];
}

final class SalesAgreementListWatchStarted extends SalesAgreementListEvent {
  const SalesAgreementListWatchStarted(
    this.factoryId, {
    this.initialFilter,
  });

  final String factoryId;
  final SalesAgreementListStatusFilter? initialFilter;

  @override
  List<Object?> get props => [factoryId, initialFilter];
}

final class SalesAgreementListSearchChanged extends SalesAgreementListEvent {
  const SalesAgreementListSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class SalesAgreementListStatusFilterChanged
    extends SalesAgreementListEvent {
  const SalesAgreementListStatusFilterChanged(this.statusFilter);

  final SalesAgreementListStatusFilter statusFilter;

  @override
  List<Object?> get props => [statusFilter];
}

final class _SalesAgreementListUpdated extends SalesAgreementListEvent {
  const _SalesAgreementListUpdated(this.agreements);

  final List<SalesAgreement> agreements;

  @override
  List<Object?> get props => [agreements];
}

final class _SalesAgreementOrdersUpdated extends SalesAgreementListEvent {
  const _SalesAgreementOrdersUpdated(this.orders);

  final List<SalesOrder> orders;

  @override
  List<Object?> get props => [orders];
}

final class _SalesAgreementInvoicesUpdated extends SalesAgreementListEvent {
  const _SalesAgreementInvoicesUpdated(this.invoices);

  final List<SalesInvoice> invoices;

  @override
  List<Object?> get props => [invoices];
}

final class _SalesAgreementListStreamFailed extends SalesAgreementListEvent {
  const _SalesAgreementListStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
