part of 'employee_ledger_history_bloc.dart';

enum EmployeeLedgerHistoryStatus { initial, loading, loaded, failure }

class EmployeeLedgerHistoryState extends Equatable {
  const EmployeeLedgerHistoryState({
    this.status = EmployeeLedgerHistoryStatus.initial,
    this.employeeId = '',
    this.ledgers = const [],
    this.errorMessage,
  });

  final EmployeeLedgerHistoryStatus status;
  final String employeeId;
  final List<MonthlyLedger> ledgers;
  final String? errorMessage;

  EmployeeLedgerHistoryState copyWith({
    EmployeeLedgerHistoryStatus? status,
    String? employeeId,
    List<MonthlyLedger>? ledgers,
    String? errorMessage,
  }) {
    return EmployeeLedgerHistoryState(
      status: status ?? this.status,
      employeeId: employeeId ?? this.employeeId,
      ledgers: ledgers ?? this.ledgers,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, employeeId, ledgers, errorMessage];
}
