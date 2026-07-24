import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/job_work_invoice_repository.dart';
import '../../data/repositories/job_work_load_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/sales_invoice_repository.dart';
import '../../data/repositories/sales_order_repository.dart';
import '../../data/services/customer_balance_calculator.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/customer_enums.dart';

part 'customer_form_event.dart';
part 'customer_form_state.dart';

class CustomerFormBloc extends Bloc<CustomerFormEvent, CustomerFormState> {
  CustomerFormBloc({
    required CustomerRepository repository,
    required JobWorkRepository jobWorkRepository,
    required JobWorkLoadRepository jobWorkLoadRepository,
    required JobWorkInvoiceRepository jobWorkInvoiceRepository,
    required SalesOrderRepository salesOrderRepository,
    required SalesInvoiceRepository salesInvoiceRepository,
    required PaymentRepository paymentRepository,
  })  : _repository = repository,
        _jobWorkRepository = jobWorkRepository,
        _jobWorkLoadRepository = jobWorkLoadRepository,
        _jobWorkInvoiceRepository = jobWorkInvoiceRepository,
        _salesOrderRepository = salesOrderRepository,
        _salesInvoiceRepository = salesInvoiceRepository,
        _paymentRepository = paymentRepository,
        super(const CustomerFormState()) {
    on<CustomerFormLoadRequested>(_onLoadRequested);
    on<CustomerFormInitialized>(_onInitialized);
    on<CustomerFormSubmitted>(_onSubmitted);
    on<CustomerFormDeleteRequested>(_onDeleteRequested);
    on<_CustomerFormUpdated>(_onUpdated);
    on<_CustomerFormStreamFailed>(_onStreamFailed);
    on<_CustomerDataChanged>(_onDataChanged);
  }

  final CustomerRepository _repository;
  final JobWorkRepository _jobWorkRepository;
  final JobWorkLoadRepository _jobWorkLoadRepository;
  final JobWorkInvoiceRepository _jobWorkInvoiceRepository;
  final SalesOrderRepository _salesOrderRepository;
  final SalesInvoiceRepository _salesInvoiceRepository;
  final PaymentRepository _paymentRepository;

  StreamSubscription<Customer?>? _customerSub;
  StreamSubscription<List<JobWorkOrder>>? _jobWorkSub;
  StreamSubscription<List<JobWorkLoad>>? _loadSub;
  StreamSubscription<List<JobWorkInvoice>>? _jwInvoiceSub;
  StreamSubscription<List<SalesOrder>>? _salesOrderSub;
  StreamSubscription<List<SalesInvoice>>? _salesInvoiceSub;
  StreamSubscription<List<Payment>>? _paymentSub;

  Customer? _currentCustomer;
  List<JobWorkOrder> _jobWorkOrders = const [];
  List<JobWorkLoad> _jobWorkLoads = const [];
  List<JobWorkInvoice> _jwInvoices = const [];
  List<SalesOrder> _salesOrders = const [];
  List<SalesInvoice> _salesInvoices = const [];
  List<Payment> _payments = const [];

  Future<void> _cancelSubscriptions() async {
    await _customerSub?.cancel();
    await _jobWorkSub?.cancel();
    await _loadSub?.cancel();
    await _jwInvoiceSub?.cancel();
    await _salesOrderSub?.cancel();
    await _salesInvoiceSub?.cancel();
    await _paymentSub?.cancel();
    _customerSub = null;
    _jobWorkSub = null;
    _loadSub = null;
    _jwInvoiceSub = null;
    _salesOrderSub = null;
    _salesInvoiceSub = null;
    _paymentSub = null;
  }

  Future<void> _onLoadRequested(
    CustomerFormLoadRequested event,
    Emitter<CustomerFormState> emit,
  ) async {
    emit(state.copyWith(status: CustomerFormStatus.loading, isEditing: true));
    await _cancelSubscriptions();

    _customerSub = _repository.watchCustomer(event.customerId).listen(
      (customer) {
        if (customer == null) {
          add(const _CustomerFormStreamFailed('Customer not found.'));
        } else {
          _currentCustomer = customer;
          add(const _CustomerDataChanged());
          _subscribeRelated(customer.factoryId, event.customerId);
        }
      },
      onError: (_) => add(
        const _CustomerFormStreamFailed('Could not load customer.'),
      ),
    );
  }

  void _subscribeRelated(String factoryId, String customerId) {
    _jobWorkSub?.cancel();
    _jobWorkSub = _jobWorkRepository.watchOrdersForCustomer(customerId).listen((orders) {
      _jobWorkOrders = orders;
      add(const _CustomerDataChanged());
    });

    _loadSub?.cancel();
    _loadSub = _jobWorkLoadRepository.watchLoads(factoryId).listen((loads) {
      _jobWorkLoads = loads;
      add(const _CustomerDataChanged());
    });

    _jwInvoiceSub?.cancel();
    _jwInvoiceSub = _jobWorkInvoiceRepository.watchInvoicesForCustomer(
      factoryId: factoryId,
      customerId: customerId,
    ).listen((invoices) {
      _jwInvoices = invoices;
      add(const _CustomerDataChanged());
    });

    _salesOrderSub?.cancel();
    _salesOrderSub = _salesOrderRepository.watchSalesOrders(factoryId).listen((orders) {
      _salesOrders = orders;
      add(const _CustomerDataChanged());
    });

    _salesInvoiceSub?.cancel();
    _salesInvoiceSub = _salesInvoiceRepository.watchInvoicesForCustomer(
      factoryId: factoryId,
      customerId: customerId,
    ).listen((invoices) {
      _salesInvoices = invoices;
      add(const _CustomerDataChanged());
    });

    _paymentSub?.cancel();
    _paymentSub = _paymentRepository.watchPaymentsForCustomer(
      factoryId: factoryId,
      customerId: customerId,
    ).listen((payments) {
      _payments = payments;
      add(const _CustomerDataChanged());
    });
  }

  void _onDataChanged(
    _CustomerDataChanged event,
    Emitter<CustomerFormState> emit,
  ) {
    if (_currentCustomer == null) return;

    final summary = CustomerBalanceCalculator.calculateCustomerSummary(
      customer: _currentCustomer!,
      salesOrders: _salesOrders,
      salesInvoices: _salesInvoices,
      jobWorkOrders: _jobWorkOrders,
      jobWorkLoads: _jobWorkLoads,
      jobWorkInvoices: _jwInvoices,
      payments: _payments,
    );

    final computedCustomer = _currentCustomer!.copyWith(
      balance: summary.totalDue,
      nextDueDate: summary.nextDueDate,
    );

    emit(
      state.copyWith(
        status: CustomerFormStatus.ready,
        customer: computedCustomer,
        isEditing: true,
        errorMessage: null,
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
    await _cancelSubscriptions();

    if (event.customer != null) {
      _currentCustomer = event.customer;
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
      await _salesInvoiceRepository.deleteInvoicesForCustomer(event.customerId);
      await _salesOrderRepository.deleteOrdersForCustomer(event.customerId);
      await _jobWorkRepository.deleteOrdersForCustomer(event.customerId);
      await _repository.deleteCustomer(event.customerId);
      await _cancelSubscriptions();
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
    _cancelSubscriptions();
    return super.close();
  }
}

final class _CustomerDataChanged extends CustomerFormEvent {
  const _CustomerDataChanged();
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
