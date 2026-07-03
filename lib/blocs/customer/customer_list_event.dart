part of 'customer_list_bloc.dart';

sealed class CustomerListEvent extends Equatable {
  const CustomerListEvent();

  @override
  List<Object?> get props => [];
}

final class CustomerListWatchStarted extends CustomerListEvent {
  const CustomerListWatchStarted(this.factoryId);

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

final class CustomerListWatchStopped extends CustomerListEvent {
  const CustomerListWatchStopped();
}

final class CustomerListSearchChanged extends CustomerListEvent {
  const CustomerListSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class CustomerListFilterChanged extends CustomerListEvent {
  const CustomerListFilterChanged(this.serviceType);

  final CustomerServiceType? serviceType;

  @override
  List<Object?> get props => [serviceType];
}

final class _CustomerListUpdated extends CustomerListEvent {
  const _CustomerListUpdated(this.customers);

  final List<Customer> customers;

  @override
  List<Object?> get props => [customers];
}

final class _CustomerJobWorkCountsUpdated extends CustomerListEvent {
  const _CustomerJobWorkCountsUpdated(this.counts);

  final Map<String, int> counts;

  @override
  List<Object?> get props => [counts];
}

final class _CustomerSalesCountsUpdated extends CustomerListEvent {
  const _CustomerSalesCountsUpdated(this.counts);

  final Map<String, int> counts;

  @override
  List<Object?> get props => [counts];
}

final class _CustomerListStreamFailed extends CustomerListEvent {
  const _CustomerListStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
