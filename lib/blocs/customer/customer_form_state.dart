part of 'customer_form_bloc.dart';

enum CustomerFormStatus {
  initial,
  loading,
  ready,
  saving,
  saved,
  deleted,
  failure,
}

class CustomerFormState extends Equatable {
  const CustomerFormState({
    this.status = CustomerFormStatus.initial,
    this.customer,
    this.errorMessage,
    this.isEditing = false,
  });

  final CustomerFormStatus status;
  final Customer? customer;
  final String? errorMessage;
  final bool isEditing;

  CustomerFormState copyWith({
    CustomerFormStatus? status,
    Customer? customer,
    String? errorMessage,
    bool? isEditing,
  }) {
    return CustomerFormState(
      status: status ?? this.status,
      customer: customer ?? this.customer,
      errorMessage: errorMessage,
      isEditing: isEditing ?? this.isEditing,
    );
  }

  @override
  List<Object?> get props => [status, customer, errorMessage, isEditing];
}
