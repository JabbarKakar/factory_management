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

final class _CustomerDataChanged extends CustomerListEvent {
  const _CustomerDataChanged();
}

final class _CustomerListStreamFailed extends CustomerListEvent {
  const _CustomerListStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
