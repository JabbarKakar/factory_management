import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/delivery_repository.dart';
import '../../data/repositories/employee_repository.dart';
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
  })  : _deliveryRepository = deliveryRepository,
        _employeeRepository = employeeRepository,
        super(const DeliveryFormState()) {
    on<DeliveryFormInitialized>(_onInitialized);
    on<DeliveryFormSalesOrderSelected>(_onSalesOrderSelected);
    on<DeliveryFormSubmitted>(_onSubmitted);
  }

  final DeliveryRepository _deliveryRepository;
  final EmployeeRepository _employeeRepository;

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

  Future<void> _onSalesOrderSelected(
    DeliveryFormSalesOrderSelected event,
    Emitter<DeliveryFormState> emit,
  ) async {
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
    DeliveryFormState current,
  ) async {
    final deliveries =
        await _deliveryRepository.fetchDeliveriesForSalesOrder(order.id);
    final remaining = DeliveryQuantityHelper.remainingLines(order, deliveries);
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
      await _deliveryRepository.createDelivery(event.delivery);
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
          errorMessage: 'Could not schedule delivery. Please try again.',
        ),
      );
    }
  }
}
