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
    this.jobWorkCounts = const {},
    this.salesCounts = const {},
  });

  final CustomerListStatus status;
  final List<Customer> customers;
  final List<Customer> visibleCustomers;
  final String searchQuery;
  final CustomerServiceType? serviceTypeFilter;
  final String? errorMessage;
  final Map<String, int> jobWorkCounts;
  final Map<String, int> salesCounts;

  CustomerListState copyWith({
    CustomerListStatus? status,
    List<Customer>? customers,
    List<Customer>? visibleCustomers,
    String? searchQuery,
    CustomerServiceType? serviceTypeFilter,
    bool clearServiceTypeFilter = false,
    String? errorMessage,
    Map<String, int>? jobWorkCounts,
    Map<String, int>? salesCounts,
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
      jobWorkCounts: jobWorkCounts ?? this.jobWorkCounts,
      salesCounts: salesCounts ?? this.salesCounts,
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
        jobWorkCounts,
        salesCounts,
      ];
}
