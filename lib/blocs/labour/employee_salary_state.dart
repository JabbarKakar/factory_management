part of 'employee_salary_bloc.dart';

enum EmployeeSalaryStatus { initial, loading, loaded, failure }

enum EmployeeSalaryActionStatus { idle, saving, success, failure }

class EmployeeSalaryState extends Equatable {
  const EmployeeSalaryState({
    this.status = EmployeeSalaryStatus.initial,
    this.actionStatus = EmployeeSalaryActionStatus.idle,
    this.employeeId = '',
    this.factoryId = '',
    this.requestedMonthKey,
    this.monthKey,
    this.initializeIfMissing = true,
    this.employee,
    this.ledger,
    this.payments = const [],
    this.errorMessage,
    this.snackbarMessage,
  });

  final EmployeeSalaryStatus status;
  final EmployeeSalaryActionStatus actionStatus;
  final String employeeId;
  final String factoryId;
  final String? requestedMonthKey;
  final String? monthKey;
  final bool initializeIfMissing;
  final Employee? employee;
  final MonthlyLedger? ledger;
  final List<WagePayment> payments;
  final String? errorMessage;
  final String? snackbarMessage;

  bool get canRecordPayment => ledger?.canRecordPayment ?? true;

  EmployeeSalaryState copyWith({
    EmployeeSalaryStatus? status,
    EmployeeSalaryActionStatus? actionStatus,
    String? employeeId,
    String? factoryId,
    String? requestedMonthKey,
    String? monthKey,
    bool? initializeIfMissing,
    Employee? employee,
    MonthlyLedger? ledger,
    List<WagePayment>? payments,
    String? errorMessage,
    String? snackbarMessage,
    bool clearLedger = false,
    bool clearError = false,
    bool clearSnackbar = false,
  }) {
    return EmployeeSalaryState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      employeeId: employeeId ?? this.employeeId,
      factoryId: factoryId ?? this.factoryId,
      requestedMonthKey: requestedMonthKey ?? this.requestedMonthKey,
      monthKey: monthKey ?? this.monthKey,
      initializeIfMissing: initializeIfMissing ?? this.initializeIfMissing,
      employee: employee ?? this.employee,
      ledger: clearLedger ? null : (ledger ?? this.ledger),
      payments: payments ?? this.payments,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      snackbarMessage:
          clearSnackbar ? null : (snackbarMessage ?? this.snackbarMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        employeeId,
        factoryId,
        requestedMonthKey,
        monthKey,
        initializeIfMissing,
        employee,
        ledger,
        payments,
        errorMessage,
        snackbarMessage,
      ];
}
