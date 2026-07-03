import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/repositories/sales_order_repository.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/customer_enums.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/sales_enums.dart';

part 'customer_list_event.dart';
part 'customer_list_state.dart';

class CustomerListBloc extends Bloc<CustomerListEvent, CustomerListState> {
  CustomerListBloc({
    required CustomerRepository repository,
    required JobWorkRepository jobWorkRepository,
    required SalesOrderRepository salesOrderRepository,
  })  : _repository = repository,
        _jobWorkRepository = jobWorkRepository,
        _salesOrderRepository = salesOrderRepository,
        super(const CustomerListState()) {
    on<CustomerListWatchStarted>(_onWatchStarted);
    on<CustomerListWatchStopped>(_onWatchStopped);
    on<CustomerListSearchChanged>(_onSearchChanged);
    on<CustomerListFilterChanged>(_onFilterChanged);
    on<_CustomerListUpdated>(_onListUpdated);
    on<_CustomerJobWorkCountsUpdated>(_onJobWorkCountsUpdated);
    on<_CustomerSalesCountsUpdated>(_onSalesCountsUpdated);
    on<_CustomerListStreamFailed>(_onStreamFailed);
  }

  final CustomerRepository _repository;
  final JobWorkRepository _jobWorkRepository;
  final SalesOrderRepository _salesOrderRepository;
  StreamSubscription<List<Customer>>? _subscription;
  StreamSubscription<List<JobWorkOrder>>? _jobWorkSubscription;
  StreamSubscription<List<SalesOrder>>? _salesSubscription;

  Future<void> _onWatchStarted(
    CustomerListWatchStarted event,
    Emitter<CustomerListState> emit,
  ) async {
    emit(state.copyWith(status: CustomerListStatus.loading));
    await _subscription?.cancel();
    await _jobWorkSubscription?.cancel();
    await _salesSubscription?.cancel();

    _subscription = _repository.watchCustomers(event.factoryId).listen(
          (customers) => add(_CustomerListUpdated(customers)),
          onError: (_) => add(
            const _CustomerListStreamFailed(
              'Could not load customers. Please try again.',
            ),
          ),
        );

    _jobWorkSubscription =
        _jobWorkRepository.watchJobWorkOrders(event.factoryId).listen(
      (orders) {
        final counts = <String, int>{};
        for (final order in orders) {
          if (order.status == JobWorkStatus.cancelled) continue;
          counts[order.customerId] = (counts[order.customerId] ?? 0) + 1;
        }
        add(_CustomerJobWorkCountsUpdated(counts));
      },
      onError: (_) {},
    );

    _salesSubscription =
        _salesOrderRepository.watchSalesOrders(event.factoryId).listen(
      (orders) {
        final counts = <String, int>{};
        for (final order in orders) {
          if (order.status == SalesOrderStatus.cancelled) continue;
          counts[order.customerId] = (counts[order.customerId] ?? 0) + 1;
        }
        add(_CustomerSalesCountsUpdated(counts));
      },
      onError: (_) {},
    );
  }

  Future<void> _onWatchStopped(
    CustomerListWatchStopped event,
    Emitter<CustomerListState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
    await _jobWorkSubscription?.cancel();
    _jobWorkSubscription = null;
    await _salesSubscription?.cancel();
    _salesSubscription = null;
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

  void _onListUpdated(
    _CustomerListUpdated event,
    Emitter<CustomerListState> emit,
  ) {
    final visible = _applyFilters(
      event.customers,
      query: state.searchQuery,
      serviceType: state.serviceTypeFilter,
    );
    emit(
      state.copyWith(
        status: CustomerListStatus.loaded,
        customers: event.customers,
        visibleCustomers: visible,
        errorMessage: null,
      ),
    );
  }

  void _onJobWorkCountsUpdated(
    _CustomerJobWorkCountsUpdated event,
    Emitter<CustomerListState> emit,
  ) {
    emit(state.copyWith(jobWorkCounts: event.counts));
  }

  void _onSalesCountsUpdated(
    _CustomerSalesCountsUpdated event,
    Emitter<CustomerListState> emit,
  ) {
    emit(state.copyWith(salesCounts: event.counts));
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
    _subscription?.cancel();
    _jobWorkSubscription?.cancel();
    _salesSubscription?.cancel();
    return super.close();
  }
}
