part of 'employee_salary_bloc.dart';

sealed class EmployeeSalaryEvent extends Equatable {
  const EmployeeSalaryEvent();

  @override
  List<Object?> get props => [];
}

final class EmployeeSalaryWatchStarted extends EmployeeSalaryEvent {
  const EmployeeSalaryWatchStarted({
    required this.factoryId,
    required this.employeeId,
    this.monthKey,
    this.initializeIfMissing = true,
  });

  final String factoryId;
  final String employeeId;
  final String? monthKey;
  final bool initializeIfMissing;

  @override
  List<Object?> get props =>
      [factoryId, employeeId, monthKey, initializeIfMissing];
}

final class EmployeeSalaryWatchStopped extends EmployeeSalaryEvent {
  const EmployeeSalaryWatchStopped();
}

final class EmployeeSalaryPaymentRequested extends EmployeeSalaryEvent {
  const EmployeeSalaryPaymentRequested({
    required this.amount,
    required this.paymentMethod,
    required this.recordedBy,
    this.recordedByName,
    this.notes,
    this.paymentDate,
  });

  final double amount;
  final PaymentMethod paymentMethod;
  final String recordedBy;
  final String? recordedByName;
  final String? notes;
  final DateTime? paymentDate;

  @override
  List<Object?> get props => [
        amount,
        paymentMethod,
        recordedBy,
        recordedByName,
        notes,
        paymentDate,
      ];
}

final class EmployeeSalaryCloseCycleRequested extends EmployeeSalaryEvent {
  const EmployeeSalaryCloseCycleRequested({
    required this.rolloverAction,
    this.closedBy,
  });

  final WageCycleRolloverAction rolloverAction;
  final String? closedBy;

  @override
  List<Object?> get props => [rolloverAction, closedBy];
}

final class EmployeeSalaryReopenRequested extends EmployeeSalaryEvent {
  const EmployeeSalaryReopenRequested();
}

final class EmployeeSalaryRefreshPayableRequested extends EmployeeSalaryEvent {
  const EmployeeSalaryRefreshPayableRequested();
}

final class EmployeeSalarySnackbarCleared extends EmployeeSalaryEvent {
  const EmployeeSalarySnackbarCleared();
}
