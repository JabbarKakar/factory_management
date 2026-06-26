import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../domain/entities/customer.dart';
import '../../domain/enums/customer_enums.dart';

part 'customer_form_event.dart';
part 'customer_form_state.dart';

class CustomerFormBloc extends Bloc<CustomerFormEvent, CustomerFormState> {
  CustomerFormBloc({
    required CustomerRepository repository,
    required JobWorkRepository jobWorkRepository,
  })  : _repository = repository,
        _jobWorkRepository = jobWorkRepository,
        super(const CustomerFormState()) {
    on<CustomerFormLoadRequested>(_onLoadRequested);
    on<CustomerFormInitialized>(_onInitialized);
    on<CustomerFormSubmitted>(_onSubmitted);
    on<CustomerFormDeleteRequested>(_onDeleteRequested);
    on<_CustomerFormUpdated>(_onUpdated);
    on<_CustomerFormStreamFailed>(_onStreamFailed);
  }

  final CustomerRepository _repository;
  final JobWorkRepository _jobWorkRepository;
  StreamSubscription<Customer?>? _watchSubscription;

  Future<void> _onLoadRequested(
    CustomerFormLoadRequested event,
    Emitter<CustomerFormState> emit,
  ) async {
    emit(state.copyWith(status: CustomerFormStatus.loading, isEditing: true));
    await _watchSubscription?.cancel();
    _watchSubscription = _repository.watchCustomer(event.customerId).listen(
          (customer) {
            if (customer == null) {
              add(const _CustomerFormStreamFailed('Customer not found.'));
            } else {
              add(_CustomerFormUpdated(customer));
            }
          },
          onError: (_) => add(
            const _CustomerFormStreamFailed('Could not load customer.'),
          ),
        );
  }

  void _onUpdated(
    _CustomerFormUpdated event,
    Emitter<CustomerFormState> emit,
  ) {
    emit(
      state.copyWith(
        status: CustomerFormStatus.ready,
        customer: event.customer,
        isEditing: true,
        errorMessage: null,
      ),
    );
  }

  void _onStreamFailed(
    _CustomerFormStreamFailed event,
    Emitter<CustomerFormState> emit,
  ) {
    emit(
      state.copyWith(
        status: CustomerFormStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  Future<void> _onInitialized(
    CustomerFormInitialized event,
    Emitter<CustomerFormState> emit,
  ) async {
    await _watchSubscription?.cancel();
    _watchSubscription = null;

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
      await _jobWorkRepository.deleteOrdersForCustomer(event.customerId);
      await _repository.deleteCustomer(event.customerId);
      await _watchSubscription?.cancel();
      _watchSubscription = null;
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

  @override
  Future<void> close() {
    _watchSubscription?.cancel();
    return super.close();
  }
}

final class _CustomerFormUpdated extends CustomerFormEvent {
  const _CustomerFormUpdated(this.customer);

  final Customer customer;

  @override
  List<Object?> get props => [customer];
}

final class _CustomerFormStreamFailed extends CustomerFormEvent {
  const _CustomerFormStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
