part of 'customer_form_bloc.dart';

sealed class CustomerFormEvent extends Equatable {
  const CustomerFormEvent();

  @override
  List<Object?> get props => [];
}

final class CustomerFormLoadRequested extends CustomerFormEvent {
  const CustomerFormLoadRequested(this.customerId);

  final String customerId;

  @override
  List<Object?> get props => [customerId];
}

final class CustomerFormInitialized extends CustomerFormEvent {
  const CustomerFormInitialized({
    required this.factoryId,
    this.customer,
  });

  final String factoryId;
  final Customer? customer;

  @override
  List<Object?> get props => [factoryId, customer];
}

final class CustomerFormSubmitted extends CustomerFormEvent {
  const CustomerFormSubmitted(this.customer);

  final Customer customer;

  @override
  List<Object?> get props => [customer];
}

final class CustomerFormDeleteRequested extends CustomerFormEvent {
  const CustomerFormDeleteRequested(this.customerId);

  final String customerId;

  @override
  List<Object?> get props => [customerId];
}
