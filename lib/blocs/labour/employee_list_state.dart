part of 'employee_list_bloc.dart';

enum EmployeeListStatus { initial, loading, loaded, failure }

class EmployeeListState extends Equatable {
  const EmployeeListState({
    this.status = EmployeeListStatus.initial,
    this.employees = const [],
    this.visibleEmployees = const [],
    this.searchQuery = '',
    this.filter = EmployeeListFilter.active,
    this.errorMessage,
  });

  final EmployeeListStatus status;
  final List<Employee> employees;
  final List<Employee> visibleEmployees;
  final String searchQuery;
  final EmployeeListFilter filter;
  final String? errorMessage;

  int get activeCount =>
      employees.where((employee) => employee.isActive).length;

  EmployeeListState copyWith({
    EmployeeListStatus? status,
    List<Employee>? employees,
    List<Employee>? visibleEmployees,
    String? searchQuery,
    EmployeeListFilter? filter,
    String? errorMessage,
  }) {
    return EmployeeListState(
      status: status ?? this.status,
      employees: employees ?? this.employees,
      visibleEmployees: visibleEmployees ?? this.visibleEmployees,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        employees,
        visibleEmployees,
        searchQuery,
        filter,
        errorMessage,
      ];
}
