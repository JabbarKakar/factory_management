part of 'delivery_form_bloc.dart';

enum DeliveryFormStatus { initial, loading, ready, saving, saved, failure }

class DeliveryFormState extends Equatable {
  const DeliveryFormState({
    this.status = DeliveryFormStatus.initial,
    this.eligibleOrders = const [],
    this.employees = const [],
    this.selectedOrder,
    this.errorMessage,
  });

  final DeliveryFormStatus status;
  final List<SalesOrder> eligibleOrders;
  final List<Employee> employees;
  final SalesOrder? selectedOrder;
  final String? errorMessage;

  DeliveryFormState copyWith({
    DeliveryFormStatus? status,
    List<SalesOrder>? eligibleOrders,
    List<Employee>? employees,
    SalesOrder? selectedOrder,
    bool clearSelectedOrder = false,
    String? errorMessage,
  }) {
    return DeliveryFormState(
      status: status ?? this.status,
      eligibleOrders: eligibleOrders ?? this.eligibleOrders,
      employees: employees ?? this.employees,
      selectedOrder:
          clearSelectedOrder ? null : (selectedOrder ?? this.selectedOrder),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        eligibleOrders,
        employees,
        selectedOrder,
        errorMessage,
      ];
}
