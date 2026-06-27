part of 'employee_form_bloc.dart';

enum EmployeeFormStatus {
  initial,
  loading,
  ready,
  saving,
  saved,
  deleted,
  failure,
}

class EmployeeFormState extends Equatable {
  const EmployeeFormState({
    this.status = EmployeeFormStatus.initial,
    this.employee,
    this.isEditing = false,
    this.errorMessage,
  });

  final EmployeeFormStatus status;
  final Employee? employee;
  final bool isEditing;
  final String? errorMessage;

  EmployeeFormState copyWith({
    EmployeeFormStatus? status,
    Employee? employee,
    bool? isEditing,
    String? errorMessage,
  }) {
    return EmployeeFormState(
      status: status ?? this.status,
      employee: employee ?? this.employee,
      isEditing: isEditing ?? this.isEditing,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, employee, isEditing, errorMessage];
}
