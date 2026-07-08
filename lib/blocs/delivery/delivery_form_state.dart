part of 'delivery_form_bloc.dart';

enum DeliveryFormStatus { initial, loading, ready, saving, saved, failure }

class DeliveryFormState extends Equatable {
  const DeliveryFormState({
    this.status = DeliveryFormStatus.initial,
    this.eligibleOrders = const [],
    this.employees = const [],
    this.selectedOrder,
    this.editingDelivery,
    this.isEditing = false,
    this.logisticsOnly = false,
    this.existingDeliveries = const [],
    this.remainingLines = const [],
    this.errorMessage,
  });

  final DeliveryFormStatus status;
  final List<SalesOrder> eligibleOrders;
  final List<Employee> employees;
  final SalesOrder? selectedOrder;
  final Delivery? editingDelivery;
  final bool isEditing;
  final bool logisticsOnly;
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
    Delivery? editingDelivery,
    bool? isEditing,
    bool? logisticsOnly,
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
      editingDelivery: editingDelivery ?? this.editingDelivery,
      isEditing: isEditing ?? this.isEditing,
      logisticsOnly: logisticsOnly ?? this.logisticsOnly,
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
        editingDelivery,
        isEditing,
        logisticsOnly,
        existingDeliveries,
        remainingLines,
        errorMessage,
      ];
}
