part of 'employee_ledger_history_bloc.dart';

sealed class EmployeeLedgerHistoryEvent extends Equatable {
  const EmployeeLedgerHistoryEvent();

  @override
  List<Object?> get props => [];
}

final class EmployeeLedgerHistoryWatchStarted
    extends EmployeeLedgerHistoryEvent {
  const EmployeeLedgerHistoryWatchStarted({
    required this.employeeId,
    required this.factoryId,
  });

  final String employeeId;
  final String factoryId;

  @override
  List<Object?> get props => [employeeId, factoryId];
}

final class EmployeeLedgerHistoryWatchStopped
    extends EmployeeLedgerHistoryEvent {
  const EmployeeLedgerHistoryWatchStopped();
}
