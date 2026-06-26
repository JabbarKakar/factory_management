import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/customer_repository.dart';
import '../../domain/entities/customer.dart';
import '../../domain/enums/customer_enums.dart';

part 'customer_form_event.dart';
part 'customer_form_state.dart';

class CustomerFormBloc extends Bloc<CustomerFormEvent, CustomerFormState> {
  CustomerFormBloc({required CustomerRepository repository})
      : _repository = repository,
        super(const CustomerFormState()) {
    on<CustomerFormLoadRequested>(_onLoadRequested);
    on<CustomerFormInitialized>(_onInitialized);
    on<CustomerFormSubmitted>(_onSubmitted);
    on<CustomerFormDeleteRequested>(_onDeleteRequested);
  }

  final CustomerRepository _repository;

  Future<void> _onLoadRequested(
    CustomerFormLoadRequested event,
    Emitter<CustomerFormState> emit,
  ) async {
    emit(state.copyWith(status: CustomerFormStatus.loading, isEditing: true));
    try {
      final customer = await _repository.getCustomer(event.customerId);
      if (customer == null) {
        emit(
          state.copyWith(
            status: CustomerFormStatus.failure,
            errorMessage: 'Customer not found.',
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: CustomerFormStatus.ready,
          customer: customer,
          isEditing: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CustomerFormStatus.failure,
          errorMessage: 'Could not load customer.',
        ),
      );
    }
  }

  void _onInitialized(
    CustomerFormInitialized event,
    Emitter<CustomerFormState> emit,
  ) {
    if (event.customer != null) {
      emit(
        state.copyWith(
          status: CustomerFormStatus.ready,
          customer: event.customer,
          isEditing: true,
        ),
      );
      return;
    }

    emit(
      CustomerFormState(
        status: CustomerFormStatus.ready,
        isEditing: false,
        customer: Customer(
          id: '',
          factoryId: event.factoryId,
          customerType: CustomerType.individual,
          name: '',
          phone: '',
          serviceType: CustomerServiceType.buyer,
          category: CustomerCategory.retail,
          paymentTerms: PaymentTerms.cash,
          creditLimit: 0,
          balance: 0,
          openingBalance: 0,
          createdAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _onSubmitted(
    CustomerFormSubmitted event,
    Emitter<CustomerFormState> emit,
  ) async {
    emit(state.copyWith(status: CustomerFormStatus.saving));
    try {
      if (event.customer.id.isEmpty) {
        final created = await _repository.createCustomer(event.customer);
        emit(
          state.copyWith(
            status: CustomerFormStatus.saved,
            customer: created,
          ),
        );
      } else {
        await _repository.updateCustomer(event.customer);
        emit(
          state.copyWith(
            status: CustomerFormStatus.saved,
            customer: event.customer,
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: CustomerFormStatus.failure,
          errorMessage: 'Could not save customer. Please try again.',
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    CustomerFormDeleteRequested event,
    Emitter<CustomerFormState> emit,
  ) async {
    emit(state.copyWith(status: CustomerFormStatus.saving));
    try {
      await _repository.deleteCustomer(event.customerId);
      emit(state.copyWith(status: CustomerFormStatus.deleted));
    } catch (_) {
      emit(
        state.copyWith(
          status: CustomerFormStatus.failure,
          errorMessage: 'Could not delete customer.',
        ),
      );
    }
  }
}
