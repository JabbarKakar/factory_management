import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/employee_repository.dart';
import '../../domain/entities/employee.dart';
import '../../domain/enums/labour_enums.dart';

part 'employee_list_event.dart';
part 'employee_list_state.dart';

class EmployeeListBloc extends Bloc<EmployeeListEvent, EmployeeListState> {
  EmployeeListBloc({required EmployeeRepository repository})
      : _repository = repository,
        super(const EmployeeListState()) {
    on<EmployeeListWatchStarted>(_onWatchStarted);
    on<EmployeeListWatchStopped>(_onWatchStopped);
    on<EmployeeListSearchChanged>(_onSearchChanged);
    on<EmployeeListFilterChanged>(_onFilterChanged);
    on<_EmployeeListUpdated>(_onListUpdated);
    on<_EmployeeListStreamFailed>(_onStreamFailed);
  }

  final EmployeeRepository _repository;
  StreamSubscription<List<Employee>>? _subscription;

  Future<void> _onWatchStarted(
    EmployeeListWatchStarted event,
    Emitter<EmployeeListState> emit,
  ) async {
    emit(state.copyWith(status: EmployeeListStatus.loading));
    await _subscription?.cancel();
    _subscription = _repository.watchEmployees(event.factoryId).listen(
          (employees) => add(_EmployeeListUpdated(employees)),
          onError: (_) => add(
            const _EmployeeListStreamFailed(
              'Could not load employees. Please try again.',
            ),
          ),
        );
  }

  Future<void> _onWatchStopped(
    EmployeeListWatchStopped event,
    Emitter<EmployeeListState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _onSearchChanged(
    EmployeeListSearchChanged event,
    Emitter<EmployeeListState> emit,
  ) {
    emit(
      state.copyWith(
        searchQuery: event.query,
        visibleEmployees: _applyFilters(
          state.employees,
          query: event.query,
          filter: state.filter,
        ),
      ),
    );
  }

  void _onFilterChanged(
    EmployeeListFilterChanged event,
    Emitter<EmployeeListState> emit,
  ) {
    emit(
      state.copyWith(
        filter: event.filter,
        visibleEmployees: _applyFilters(
          state.employees,
          query: state.searchQuery,
          filter: event.filter,
        ),
      ),
    );
  }

  void _onListUpdated(
    _EmployeeListUpdated event,
    Emitter<EmployeeListState> emit,
  ) {
    emit(
      state.copyWith(
        status: EmployeeListStatus.loaded,
        employees: event.employees,
        visibleEmployees: _applyFilters(
          event.employees,
          query: state.searchQuery,
          filter: state.filter,
        ),
        errorMessage: null,
      ),
    );
  }

  void _onStreamFailed(
    _EmployeeListStreamFailed event,
    Emitter<EmployeeListState> emit,
  ) {
    emit(
      state.copyWith(
        status: EmployeeListStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  List<Employee> _applyFilters(
    List<Employee> employees, {
    required String query,
    required EmployeeListFilter filter,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    return employees.where((employee) {
      if (filter == EmployeeListFilter.active && !employee.isActive) {
        return false;
      }
      if (filter == EmployeeListFilter.inactive && employee.isActive) {
        return false;
      }
      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        employee.fullName,
        employee.employeeNumber,
        employee.phone,
        employee.cnic,
        employee.workerCategory.label,
        employee.employmentType.label,
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

final class _EmployeeListUpdated extends EmployeeListEvent {
  const _EmployeeListUpdated(this.employees);

  final List<Employee> employees;

  @override
  List<Object?> get props => [employees];
}

final class _EmployeeListStreamFailed extends EmployeeListEvent {
  const _EmployeeListStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
