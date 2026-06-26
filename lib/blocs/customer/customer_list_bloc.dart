import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/customer_repository.dart';
import '../../domain/entities/customer.dart';
import '../../domain/enums/customer_enums.dart';

part 'customer_list_event.dart';
part 'customer_list_state.dart';

class CustomerListBloc extends Bloc<CustomerListEvent, CustomerListState> {
  CustomerListBloc({required CustomerRepository repository})
      : _repository = repository,
        super(const CustomerListState()) {
    on<CustomerListWatchStarted>(_onWatchStarted);
    on<CustomerListWatchStopped>(_onWatchStopped);
    on<CustomerListSearchChanged>(_onSearchChanged);
    on<CustomerListFilterChanged>(_onFilterChanged);
    on<_CustomerListUpdated>(_onListUpdated);
    on<_CustomerListStreamFailed>(_onStreamFailed);
  }

  final CustomerRepository _repository;
  StreamSubscription<List<Customer>>? _subscription;

  Future<void> _onWatchStarted(
    CustomerListWatchStarted event,
    Emitter<CustomerListState> emit,
  ) async {
    emit(state.copyWith(status: CustomerListStatus.loading));
    await _subscription?.cancel();
    _subscription = _repository.watchCustomers(event.factoryId).listen(
          (customers) => add(_CustomerListUpdated(customers)),
          onError: (_) => add(
            const _CustomerListStreamFailed(
              'Could not load customers. Please try again.',
            ),
          ),
        );
  }

  Future<void> _onWatchStopped(
    CustomerListWatchStopped event,
    Emitter<CustomerListState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
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
    return super.close();
  }
}
