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
    this.deliveries = const [],
    this.errorMessage,
    this.successMessage,
    this.isEditing = false,
  });

  final SalesOrderFormStatus status;
  final SalesOrder? order;
  final List<Customer> eligibleCustomers;
  final List<Delivery> deliveries;
  final String? errorMessage;
  final String? successMessage;
  final bool isEditing;

  SalesOrderFormState copyWith({
    SalesOrderFormStatus? status,
    SalesOrder? order,
    List<Customer>? eligibleCustomers,
    List<Delivery>? deliveries,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
    bool? isEditing,
  }) {
    return SalesOrderFormState(
      status: status ?? this.status,
      order: order ?? this.order,
      eligibleCustomers: eligibleCustomers ?? this.eligibleCustomers,
      deliveries: deliveries ?? this.deliveries,
      errorMessage: clearMessages ? null : errorMessage,
      successMessage: clearMessages ? null : successMessage,
      isEditing: isEditing ?? this.isEditing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        order,
        eligibleCustomers,
        deliveries,
        errorMessage,
        successMessage,
        isEditing,
      ];
}
