part of 'employee_ledger_history_bloc.dart';

sealed class EmployeeLedgerHistoryEvent extends Equatable {
  const EmployeeLedgerHistoryEvent();

  @override
  List<Object?> get props => [];
}

final class EmployeeLedgerHistoryWatchStarted
    extends EmployeeLedgerHistoryEvent {
  const EmployeeLedgerHistoryWatchStarted({required this.employeeId});

  final String employeeId;

  @override
  List<Object?> get props => [employeeId];
}

final class EmployeeLedgerHistoryWatchStopped
    extends EmployeeLedgerHistoryEvent {
  const EmployeeLedgerHistoryWatchStopped();
}
