part of 'employee_detail_bloc.dart';

enum EmployeeDetailStatus { initial, loading, loaded, failure }

class EmployeeDetailState extends Equatable {
  const EmployeeDetailState({
    this.status = EmployeeDetailStatus.initial,
    this.employee,
    this.attendanceRecords = const [],
    this.errorMessage,
  });

  final EmployeeDetailStatus status;
  final Employee? employee;
  final List<AttendanceRecord> attendanceRecords;
  final String? errorMessage;

  EmployeeDetailState copyWith({
    EmployeeDetailStatus? status,
    Employee? employee,
    List<AttendanceRecord>? attendanceRecords,
    String? errorMessage,
  }) {
    return EmployeeDetailState(
      status: status ?? this.status,
      employee: employee ?? this.employee,
      attendanceRecords: attendanceRecords ?? this.attendanceRecords,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, employee, attendanceRecords, errorMessage];
}
