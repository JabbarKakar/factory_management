part of 'sales_agreement_list_bloc.dart';

enum SalesAgreementListStatus { initial, loading, loaded, failure }

class SalesAgreementListState extends Equatable {
  const SalesAgreementListState({
    this.status = SalesAgreementListStatus.initial,
    this.agreements = const [],
    this.visibleAgreements = const [],
    this.orders = const [],
    this.invoices = const [],
    this.searchQuery = '',
    this.statusFilter = SalesAgreementListStatusFilter.all,
    this.errorMessage,
  });

  final SalesAgreementListStatus status;
  final List<SalesAgreement> agreements;
  final List<SalesAgreement> visibleAgreements;
  final List<SalesOrder> orders;
  final List<SalesInvoice> invoices;
  final String searchQuery;
  final SalesAgreementListStatusFilter statusFilter;
  final String? errorMessage;

  SalesAgreementListState copyWith({
    SalesAgreementListStatus? status,
    List<SalesAgreement>? agreements,
    List<SalesAgreement>? visibleAgreements,
    List<SalesOrder>? orders,
    List<SalesInvoice>? invoices,
    String? searchQuery,
    SalesAgreementListStatusFilter? statusFilter,
    String? errorMessage,
  }) {
    return SalesAgreementListState(
      status: status ?? this.status,
      agreements: agreements ?? this.agreements,
      visibleAgreements: visibleAgreements ?? this.visibleAgreements,
      orders: orders ?? this.orders,
      invoices: invoices ?? this.invoices,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        agreements,
        visibleAgreements,
        orders,
        invoices,
        searchQuery,
        statusFilter,
        errorMessage,
      ];
}
