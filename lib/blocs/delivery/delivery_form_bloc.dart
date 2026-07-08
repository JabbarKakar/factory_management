import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/delivery_repository.dart';
import '../../data/repositories/employee_repository.dart';
import '../../data/repositories/sales_order_repository.dart';
import '../../data/services/delivery_quantity_helper.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/sales_order.dart';

part 'delivery_form_event.dart';
part 'delivery_form_state.dart';

class DeliveryFormBloc extends Bloc<DeliveryFormEvent, DeliveryFormState> {
  DeliveryFormBloc({
    required DeliveryRepository deliveryRepository,
    required EmployeeRepository employeeRepository,
    required SalesOrderRepository salesOrderRepository,
  })  : _deliveryRepository = deliveryRepository,
        _employeeRepository = employeeRepository,
        _salesOrderRepository = salesOrderRepository,
        super(const DeliveryFormState()) {
    on<DeliveryFormInitialized>(_onInitialized);
    on<DeliveryFormLoadRequested>(_onLoadRequested);
    on<DeliveryFormSalesOrderSelected>(_onSalesOrderSelected);
    on<DeliveryFormSubmitted>(_onSubmitted);
  }

  final DeliveryRepository _deliveryRepository;
  final EmployeeRepository _employeeRepository;
  final SalesOrderRepository _salesOrderRepository;

  Future<void> _onInitialized(
    DeliveryFormInitialized event,
    Emitter<DeliveryFormState> emit,
  ) async {
    emit(state.copyWith(status: DeliveryFormStatus.loading));
    try {
      final orders =
          await _deliveryRepository.fetchDeliveryEligibleOrders(event.factoryId);
      final employees = await _employeeRepository
          .watchEmployees(event.factoryId)
          .first;
      final activeEmployees =
          employees.where((employee) => employee.isActive).toList();

      SalesOrder? selected;
      if (event.salesOrderId != null) {
        final matches = orders.where((order) => order.id == event.salesOrderId);
        selected = matches.isEmpty ? null : matches.first;
      }

      var nextState = state.copyWith(
        status: DeliveryFormStatus.ready,
        eligibleOrders: orders,
        employees: activeEmployees,
        selectedOrder: selected,
        errorMessage: null,
      );
      emit(nextState);

      if (selected != null) {
        nextState = await _loadRemainingForOrder(selected, nextState);
        emit(nextState);
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: DeliveryFormStatus.failure,
          errorMessage: 'Could not load delivery form data.',
        ),
      );
    }
  }

  Future<void> _onLoadRequested(
    DeliveryFormLoadRequested event,
    Emitter<DeliveryFormState> emit,
  ) async {
    emit(state.copyWith(status: DeliveryFormStatus.loading, isEditing: true));
    try {
      final delivery = await _deliveryRepository.getDelivery(event.deliveryId);
      if (delivery == null) {
        emit(
          state.copyWith(
            status: DeliveryFormStatus.failure,
            errorMessage: 'Delivery not found.',
          ),
        );
        return;
      }
      if (!delivery.status.canEditLogistics) {
        emit(
          state.copyWith(
            status: DeliveryFormStatus.failure,
            errorMessage: 'This delivery can no longer be edited.',
          ),
        );
        return;
      }

      final orders =
          await _deliveryRepository.fetchDeliveryEligibleOrders(delivery.factoryId);
      final employees = await _employeeRepository
          .watchEmployees(delivery.factoryId)
          .first;
      final activeEmployees =
          employees.where((employee) => employee.isActive).toList();

      SalesOrder? selectedOrder;
      for (final order in orders) {
        if (order.id == delivery.salesOrderId) {
          selectedOrder = order;
          break;
        }
      }
      selectedOrder ??=
          await _salesOrderRepository.getSalesOrder(delivery.salesOrderId);

      var eligibleOrders = orders;
      if (selectedOrder != null &&
          !orders.any((order) => order.id == selectedOrder!.id)) {
        eligibleOrders = [selectedOrder, ...orders];
      }

      var nextState = state.copyWith(
        status: DeliveryFormStatus.ready,
        eligibleOrders: eligibleOrders,
        employees: activeEmployees,
        selectedOrder: selectedOrder,
        editingDelivery: delivery,
        isEditing: true,
        logisticsOnly: !delivery.status.canEditScheduled,
        errorMessage: null,
      );
      emit(nextState);

      if (selectedOrder != null) {
        nextState = await _loadRemainingForOrder(
          selectedOrder,
          nextState,
          excludeDeliveryId: delivery.id,
        );
        emit(nextState);
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: DeliveryFormStatus.failure,
          errorMessage: 'Could not load delivery.',
        ),
      );
    }
  }

  Future<void> _onSalesOrderSelected(
    DeliveryFormSalesOrderSelected event,
    Emitter<DeliveryFormState> emit,
  ) async {
    if (state.isEditing) return;

    SalesOrder? order;
    for (final item in state.eligibleOrders) {
      if (item.id == event.salesOrderId) {
        order = item;
        break;
      }
    }

    var nextState = state.copyWith(
      selectedOrder: order,
      clearSelectedOrder: order == null,
      existingDeliveries: const [],
      remainingLines: const [],
    );
    emit(nextState);

    if (order != null) {
      nextState = await _loadRemainingForOrder(order, nextState);
      emit(nextState);
    }
  }

  Future<DeliveryFormState> _loadRemainingForOrder(
    SalesOrder order,
    DeliveryFormState current, {
    String? excludeDeliveryId,
  }) async {
    final deliveries =
        await _deliveryRepository.fetchDeliveriesForSalesOrder(order.id);
    final remaining = DeliveryQuantityHelper.remainingLines(
      order,
      deliveries,
      excludeDeliveryId: excludeDeliveryId,
    );
    return current.copyWith(
      existingDeliveries: deliveries,
      remainingLines: remaining,
    );
  }

  Future<void> _onSubmitted(
    DeliveryFormSubmitted event,
    Emitter<DeliveryFormState> emit,
  ) async {
    emit(state.copyWith(status: DeliveryFormStatus.saving));
    try {
      if (state.isEditing) {
        final existing = state.editingDelivery;
        if (existing == null) return;

        await _deliveryRepository.updateDelivery(
          existing: existing,
          deliveryAddress: event.delivery.deliveryAddress,
          scheduledDate: event.delivery.scheduledDate,
          lineItems: event.delivery.lineItems,
          vehicleNumber: event.delivery.vehicleNumber,
          driverName: event.delivery.driverName,
          driverEmployeeId: event.delivery.driverEmployeeId,
          loadingSupervisor: event.delivery.loadingSupervisor,
          notes: event.delivery.notes,
        );
      } else {
        await _deliveryRepository.createDelivery(event.delivery);
      }
      emit(state.copyWith(status: DeliveryFormStatus.saved));
    } on DeliveryException catch (error) {
      emit(
        state.copyWith(
          status: DeliveryFormStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: DeliveryFormStatus.failure,
          errorMessage: state.isEditing
              ? 'Could not update delivery. Please try again.'
              : 'Could not schedule delivery. Please try again.',
        ),
      );
    }
  }
}
