part of 'customer_list_bloc.dart';

enum CustomerListStatus { initial, loading, loaded, failure }

class CustomerListState extends Equatable {
  const CustomerListState({
    this.status = CustomerListStatus.initial,
    this.customers = const [],
    this.visibleCustomers = const [],
    this.searchQuery = '',
    this.serviceTypeFilter,
    this.errorMessage,
  });

  final CustomerListStatus status;
  final List<Customer> customers;
  final List<Customer> visibleCustomers;
  final String searchQuery;
  final CustomerServiceType? serviceTypeFilter;
  final String? errorMessage;

  CustomerListState copyWith({
    CustomerListStatus? status,
    List<Customer>? customers,
    List<Customer>? visibleCustomers,
    String? searchQuery,
    CustomerServiceType? serviceTypeFilter,
    bool clearServiceTypeFilter = false,
    String? errorMessage,
  }) {
    return CustomerListState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      visibleCustomers: visibleCustomers ?? this.visibleCustomers,
      searchQuery: searchQuery ?? this.searchQuery,
      serviceTypeFilter: clearServiceTypeFilter
          ? null
          : (serviceTypeFilter ?? this.serviceTypeFilter),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        customers,
        visibleCustomers,
        searchQuery,
        serviceTypeFilter,
        errorMessage,
      ];
}
