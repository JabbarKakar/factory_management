part of 'employee_detail_bloc.dart';

sealed class EmployeeDetailEvent extends Equatable {
  const EmployeeDetailEvent();

  @override
  List<Object?> get props => [];
}

final class EmployeeDetailWatchStarted extends EmployeeDetailEvent {
  const EmployeeDetailWatchStarted({
    required this.factoryId,
    required this.employeeId,
  });

  final String factoryId;
  final String employeeId;

  @override
  List<Object?> get props => [factoryId, employeeId];
}

final class EmployeeDetailWatchStopped extends EmployeeDetailEvent {
  const EmployeeDetailWatchStopped();
}
