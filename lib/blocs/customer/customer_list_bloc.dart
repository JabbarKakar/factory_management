import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

part 'customer_list_event.dart';
part 'customer_list_state.dart';

class CustomerListBloc extends Bloc<CustomerListEvent, CustomerListState> {
  CustomerListBloc({
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
        super(const CustomerListState()) {
    on<CustomerListWatchStarted>(_onWatchStarted);
    on<CustomerListFetchNext>(_onFetchNext);
    on<CustomerListWatchStopped>(_onWatchStopped);
    on<CustomerListSearchChanged>(_onSearchChanged);
    on<CustomerListFilterChanged>(_onFilterChanged);
    on<_CustomerDataChanged>(_onDataChanged);
    on<_CustomerListStreamFailed>(_onStreamFailed);
  }

  final CustomerRepository _repository;
  final JobWorkRepository _jobWorkRepository;
  final JobWorkLoadRepository _jobWorkLoadRepository;
  final JobWorkInvoiceRepository _jobWorkInvoiceRepository;
  final SalesOrderRepository _salesOrderRepository;
  final SalesInvoiceRepository _salesInvoiceRepository;
  final PaymentRepository _paymentRepository;

  StreamSubscription<List<JobWorkOrder>>? _jobWorkSubscription;
  StreamSubscription<List<JobWorkLoad>>? _jobWorkLoadSubscription;
  StreamSubscription<List<JobWorkInvoice>>? _jobWorkInvoiceSubscription;
  StreamSubscription<List<SalesOrder>>? _salesSubscription;
  StreamSubscription<List<SalesInvoice>>? _salesInvoiceSubscription;
  StreamSubscription<List<Payment>>? _paymentSubscription;

  List<Customer> _rawCustomers = [];
  List<JobWorkOrder> _jobWorkOrders = [];
  List<JobWorkLoad> _jobWorkLoads = [];
  List<JobWorkInvoice> _jobWorkInvoices = [];
  List<SalesOrder> _salesOrders = [];
  List<SalesInvoice> _salesInvoices = [];
  List<Payment> _payments = [];

  Future<void> _onWatchStarted(
    CustomerListWatchStarted event,
    Emitter<CustomerListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CustomerListStatus.loading,
        isLoadingInitial: true,
        factoryId: event.factoryId,
        clearLastDocument: true,
        hasMoreData: true,
        customers: const [],
        visibleCustomers: const [],
      ),
    );

    try {
      final paginated = await _repository.fetchCustomersPage(
        factoryId: event.factoryId,
        limit: 20,
      );

      _rawCustomers = paginated.items;

      _emitProcessedCustomers(
        emit,
        isLoadingInitial: false,
        lastDocument: paginated.lastDocument,
        hasMoreData: paginated.hasMore,
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CustomerListStatus.failure,
          isLoadingInitial: false,
          errorMessage: 'Could not load customers. Please try again.',
        ),
      );
    }

    _subscribeRelatedStreams(event.factoryId);
  }

  Future<void> _onFetchNext(
    CustomerListFetchNext event,
    Emitter<CustomerListState> emit,
  ) async {
    if (state.isLoadingMore ||
        state.isLoadingInitial ||
        !state.hasMoreData ||
        state.factoryId.isEmpty) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    try {
      final paginated = await _repository.fetchCustomersPage(
        factoryId: state.factoryId,
        startAfter: state.lastDocument,
        limit: 20,
      );

      _rawCustomers = [..._rawCustomers, ...paginated.items];

      _emitProcessedCustomers(
        emit,
        isLoadingMore: false,
        lastDocument: paginated.lastDocument,
        hasMoreData: paginated.hasMore,
      );
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  void _subscribeRelatedStreams(String factoryId) {
    _cancelSubscriptions();

    _jobWorkSubscription =
        _jobWorkRepository.watchJobWorkOrders(factoryId).listen(
      (orders) {
        _jobWorkOrders = orders;
        add(const _CustomerDataChanged());
      },
      onError: (_) {},
    );

    _jobWorkLoadSubscription =
        _jobWorkLoadRepository.watchLoads(factoryId).listen(
      (loads) {
        _jobWorkLoads = loads;
        add(const _CustomerDataChanged());
      },
      onError: (_) {},
    );

    _jobWorkInvoiceSubscription = _jobWorkInvoiceRepository
        .watchInvoicesForFactory(factoryId)
        .listen(
      (invoices) {
        _jobWorkInvoices = invoices;
        add(const _CustomerDataChanged());
      },
      onError: (_) {},
    );

    _salesSubscription =
        _salesOrderRepository.watchSalesOrders(factoryId).listen(
      (orders) {
        _salesOrders = orders;
        add(const _CustomerDataChanged());
      },
      onError: (_) {},
    );

    _salesInvoiceSubscription = _salesInvoiceRepository
        .watchInvoicesForFactory(factoryId)
        .listen(
      (invoices) {
        _salesInvoices = invoices;
        add(const _CustomerDataChanged());
      },
      onError: (_) {},
    );

    _paymentSubscription =
        _paymentRepository.watchPaymentsForFactory(factoryId).listen(
      (payments) {
        _payments = payments;
        add(const _CustomerDataChanged());
      },
      onError: (_) {},
    );
  }

  Future<void> _onWatchStopped(
    CustomerListWatchStopped event,
    Emitter<CustomerListState> emit,
  ) async {
    await _cancelSubscriptions();
  }

  Future<void> _cancelSubscriptions() async {
    await _jobWorkSubscription?.cancel();
    _jobWorkSubscription = null;
    await _jobWorkLoadSubscription?.cancel();
    _jobWorkLoadSubscription = null;
    await _jobWorkInvoiceSubscription?.cancel();
    _jobWorkInvoiceSubscription = null;
    await _salesSubscription?.cancel();
    _salesSubscription = null;
    await _salesInvoiceSubscription?.cancel();
    _salesInvoiceSubscription = null;
    await _paymentSubscription?.cancel();
    _paymentSubscription = null;
  }

  void _onSearchChanged(
    CustomerListSearchChanged event,
    Emitter<CustomerListState> emit,
  ) {
    final visible = _applyFilters(
      state.customers,
      query: event.query,
      serviceType: state.serviceTypeFilter,
    );
    emit(
      state.copyWith(
        searchQuery: event.query,
        visibleCustomers: visible,
      ),
    );
  }

  void _onFilterChanged(
    CustomerListFilterChanged event,
    Emitter<CustomerListState> emit,
  ) {
    final visible = _applyFilters(
      state.customers,
      query: state.searchQuery,
      serviceType: event.serviceType,
    );
    emit(
      state.copyWith(
        serviceTypeFilter: event.serviceType,
        clearServiceTypeFilter: event.serviceType == null,
        visibleCustomers: visible,
      ),
    );
  }

  void _emitProcessedCustomers(
    Emitter<CustomerListState> emit, {
    bool? isLoadingInitial,
    bool? isLoadingMore,
    DocumentSnapshot? lastDocument,
    bool? hasMoreData,
  }) {
    final updatedCustomers = <Customer>[];
    final jobWorkCounts = <String, int>{};
    final salesCounts = <String, int>{};

    for (final customer in _rawCustomers) {
      final summary = CustomerBalanceCalculator.calculateCustomerSummary(
        customer: customer,
        salesOrders: _salesOrders,
        salesInvoices: _salesInvoices,
        jobWorkOrders: _jobWorkOrders,
        jobWorkLoads: _jobWorkLoads,
        jobWorkInvoices: _jobWorkInvoices,
        payments: _payments,
      );

      final updatedCustomer = customer.copyWith(
        balance: summary.totalDue,
        nextDueDate: summary.nextDueDate,
      );

      updatedCustomers.add(updatedCustomer);
      jobWorkCounts[customer.id] = summary.jobWorkOrderCount;
      salesCounts[customer.id] = summary.salesOrderCount;
    }

    final visible = _applyFilters(
      updatedCustomers,
      query: state.searchQuery,
      serviceType: state.serviceTypeFilter,
    );

    emit(
      state.copyWith(
        status: CustomerListStatus.loaded,
        customers: updatedCustomers,
        visibleCustomers: visible,
        jobWorkCounts: jobWorkCounts,
        salesCounts: salesCounts,
        isLoadingInitial: isLoadingInitial,
        isLoadingMore: isLoadingMore,
        lastDocument: lastDocument,
        hasMoreData: hasMoreData,
        errorMessage: null,
      ),
    );
  }

  void _onDataChanged(
    _CustomerDataChanged event,
    Emitter<CustomerListState> emit,
  ) {
    _emitProcessedCustomers(emit);
  }

  void _onStreamFailed(
    _CustomerListStreamFailed event,
    Emitter<CustomerListState> emit,
  ) {
    emit(
      state.copyWith(
        status: CustomerListStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  List<Customer> _applyFilters(
    List<Customer> customers, {
    required String query,
    CustomerServiceType? serviceType,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    return customers.where((customer) {
      final matchesService =
          serviceType == null || customer.serviceType == serviceType;

      if (!matchesService) return false;
      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        customer.name,
        customer.phone,
        customer.phoneSecondary,
        customer.whatsApp,
        customer.email,
        customer.billingCity,
        customer.category.label,
        customer.serviceType.label,
      ].whereType<String>().join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList();
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
