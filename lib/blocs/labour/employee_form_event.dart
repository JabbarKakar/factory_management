part of 'employee_form_bloc.dart';

sealed class EmployeeFormEvent extends Equatable {
  const EmployeeFormEvent();

  @override
  List<Object?> get props => [];
}

final class EmployeeFormInitialized extends EmployeeFormEvent {
  const EmployeeFormInitialized({required this.factoryId});

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

final class EmployeeFormLoadRequested extends EmployeeFormEvent {
  const EmployeeFormLoadRequested(this.employeeId);

  final String employeeId;

  @override
  List<Object?> get props => [employeeId];
}

final class EmployeeFormSubmitted extends EmployeeFormEvent {
  const EmployeeFormSubmitted(this.employee);

  final Employee employee;

  @override
  List<Object?> get props => [employee];
}

final class EmployeeFormDeleteRequested extends EmployeeFormEvent {
  const EmployeeFormDeleteRequested(this.employeeId);

  final String employeeId;

  @override
  List<Object?> get props => [employeeId];
}
