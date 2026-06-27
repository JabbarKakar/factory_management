part of 'delivery_form_bloc.dart';

enum DeliveryFormStatus { initial, loading, ready, saving, saved, failure }

class DeliveryFormState extends Equatable {
  const DeliveryFormState({
    this.status = DeliveryFormStatus.initial,
    this.eligibleOrders = const [],
    this.employees = const [],
    this.selectedOrder,
    this.existingDeliveries = const [],
    this.remainingLines = const [],
    this.errorMessage,
  });

  final DeliveryFormStatus status;
  final List<SalesOrder> eligibleOrders;
  final List<Employee> employees;
  final SalesOrder? selectedOrder;
  final List<Delivery> existingDeliveries;
  final List<DeliveryRemainingLine> remainingLines;
  final String? errorMessage;

  bool get hasRemainingQuantity =>
      remainingLines.any((line) => line.remainingQuantity > 0);

  DeliveryFormState copyWith({
    DeliveryFormStatus? status,
    List<SalesOrder>? eligibleOrders,
    List<Employee>? employees,
    SalesOrder? selectedOrder,
    bool clearSelectedOrder = false,
    List<Delivery>? existingDeliveries,
    List<DeliveryRemainingLine>? remainingLines,
    String? errorMessage,
  }) {
    return DeliveryFormState(
      status: status ?? this.status,
      eligibleOrders: eligibleOrders ?? this.eligibleOrders,
      employees: employees ?? this.employees,
      selectedOrder:
          clearSelectedOrder ? null : (selectedOrder ?? this.selectedOrder),
      existingDeliveries: existingDeliveries ?? this.existingDeliveries,
      remainingLines: remainingLines ?? this.remainingLines,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        eligibleOrders,
        employees,
        selectedOrder,
        existingDeliveries,
        remainingLines,
        errorMessage,
      ];
}
