part of 'sales_order_form_bloc.dart';

enum SalesOrderFormStatus {
  initial,
  loading,
  ready,
  saving,
  saved,
  cancelled,
  failure,
}

class SalesOrderFormState extends Equatable {
  const SalesOrderFormState({
    this.status = SalesOrderFormStatus.initial,
    this.order,
    this.eligibleCustomers = const [],
    this.errorMessage,
    this.isEditing = false,
  });

  final SalesOrderFormStatus status;
  final SalesOrder? order;
  final List<Customer> eligibleCustomers;
  final String? errorMessage;
  final bool isEditing;

  SalesOrderFormState copyWith({
    SalesOrderFormStatus? status,
    SalesOrder? order,
    List<Customer>? eligibleCustomers,
    String? errorMessage,
    bool? isEditing,
  }) {
    return SalesOrderFormState(
      status: status ?? this.status,
      order: order ?? this.order,
      eligibleCustomers: eligibleCustomers ?? this.eligibleCustomers,
      errorMessage: errorMessage,
      isEditing: isEditing ?? this.isEditing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        order,
        eligibleCustomers,
        errorMessage,
        isEditing,
      ];
}
