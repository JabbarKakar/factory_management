import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../core/constants/marble_data.dart';
import '../../data/repositories/sales_order_repository.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/customer_enums.dart';
import '../../domain/enums/sales_enums.dart';

part 'sales_order_form_event.dart';
part 'sales_order_form_state.dart';

class SalesOrderFormBloc extends Bloc<SalesOrderFormEvent, SalesOrderFormState> {
  SalesOrderFormBloc({required SalesOrderRepository repository})
      : _repository = repository,
        super(const SalesOrderFormState()) {
    on<SalesOrderFormInitialized>(_onInitialized);
    on<SalesOrderFormLoadRequested>(_onLoadRequested);
    on<SalesOrderFormSubmitted>(_onSubmitted);
    on<SalesOrderFormCancelRequested>(_onCancelRequested);
    on<SalesOrderFormStatusAdvanceRequested>(_onStatusAdvanceRequested);
  }

  final SalesOrderRepository _repository;

  Future<void> _onInitialized(
    SalesOrderFormInitialized event,
    Emitter<SalesOrderFormState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderFormStatus.loading));
    try {
      final customers =
          await _repository.fetchSalesEligibleCustomers(event.factoryId);

      emit(
        SalesOrderFormState(
          status: SalesOrderFormStatus.ready,
          eligibleCustomers: customers,
          order: _emptyOrder(event.factoryId),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SalesOrderFormStatus.failure,
          errorMessage: 'Could not load customers for sales.',
        ),
      );
    }
  }

  Future<void> _onLoadRequested(
    SalesOrderFormLoadRequested event,
    Emitter<SalesOrderFormState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderFormStatus.loading, isEditing: true));
    try {
      final order = await _repository.getSalesOrder(event.salesOrderId);
      if (order == null) {
        emit(
          state.copyWith(
            status: SalesOrderFormStatus.failure,
            errorMessage: 'Sales order not found.',
          ),
        );
        return;
      }

      final customers =
          await _repository.fetchSalesEligibleCustomers(order.factoryId);

      emit(
        state.copyWith(
          status: SalesOrderFormStatus.ready,
          order: order,
          eligibleCustomers: _repository.customersForOrderForm(
            eligible: customers,
            order: order,
          ),
          isEditing: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SalesOrderFormStatus.failure,
          errorMessage: 'Could not load sales order.',
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    SalesOrderFormSubmitted event,
    Emitter<SalesOrderFormState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderFormStatus.saving));
    try {
      if (event.order.id.isEmpty) {
        final created = await _repository.createSalesOrder(event.order);
        emit(
          state.copyWith(
            status: SalesOrderFormStatus.saved,
            order: created,
          ),
        );
      } else {
        await _repository.updateSalesOrder(event.order);
        emit(
          state.copyWith(
            status: SalesOrderFormStatus.saved,
            order: event.order,
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: SalesOrderFormStatus.failure,
          errorMessage: 'Could not save sales order.',
        ),
      );
    }
  }

  Future<void> _onCancelRequested(
    SalesOrderFormCancelRequested event,
    Emitter<SalesOrderFormState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderFormStatus.saving));
    try {
      await _repository.cancelSalesOrder(event.salesOrderId);
      emit(state.copyWith(status: SalesOrderFormStatus.cancelled));
    } catch (_) {
      emit(
        state.copyWith(
          status: SalesOrderFormStatus.failure,
          errorMessage: 'Could not cancel sales order.',
        ),
      );
    }
  }

  Future<void> _onStatusAdvanceRequested(
    SalesOrderFormStatusAdvanceRequested event,
    Emitter<SalesOrderFormState> emit,
  ) async {
    emit(state.copyWith(status: SalesOrderFormStatus.saving));
    try {
      await _repository.advanceSalesOrderStatus(
        event.salesOrderId,
        event.newStatus,
      );
      final order = await _repository.getSalesOrder(event.salesOrderId);
      if (order == null) {
        emit(
          state.copyWith(
            status: SalesOrderFormStatus.failure,
            errorMessage: 'Sales order not found.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: SalesOrderFormStatus.ready,
          order: order,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SalesOrderFormStatus.failure,
          errorMessage: 'Could not update order status.',
        ),
      );
    }
  }

  SalesOrder _emptyOrder(String factoryId) {
    return SalesOrder(
      id: '',
      orderNumber: '',
      factoryId: factoryId,
      customerId: '',
      customerName: '',
      status: SalesOrderStatus.received,
      orderDate: DateTime.now(),
      orderSource: SalesOrderSource.walkIn,
      lineItems: [
        SalesOrderLineItem(
          productType: SalesProductType.tile,
          marbleVariety: MarbleData.varieties.first,
          sizeThickness: '',
          quantity: 0,
          quantityUnit: SalesQuantityUnit.sqFt,
          unitRate: 0,
        ),
      ],
      subtotal: 0,
      orderDiscount: 0,
      tax: 0,
      grandTotal: 0,
      paymentTerms: PaymentTerms.cash,
      advanceReceived: 0,
      balanceDue: 0,
      createdAt: DateTime.now(),
    );
  }
}
