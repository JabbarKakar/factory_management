import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/delivery_repository.dart';
import '../../data/repositories/employee_repository.dart';
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

      emit(
        state.copyWith(
          status: DeliveryFormStatus.ready,
          eligibleOrders: orders,
          employees: activeEmployees,
          selectedOrder: selected,
          errorMessage: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: DeliveryFormStatus.failure,
          errorMessage: 'Could not load delivery form data.',
        ),
      );
    }
  }

  void _onSalesOrderSelected(
    DeliveryFormSalesOrderSelected event,
    Emitter<DeliveryFormState> emit,
  ) {
    SalesOrder? order;
    for (final item in state.eligibleOrders) {
      if (item.id == event.salesOrderId) {
        order = item;
        break;
      }
    }
    emit(state.copyWith(selectedOrder: order, clearSelectedOrder: order == null));
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
