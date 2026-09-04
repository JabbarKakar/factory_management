import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/employee_salary_repository.dart';
import '../../domain/entities/monthly_ledger.dart';

part 'employee_ledger_history_event.dart';
part 'employee_ledger_history_state.dart';

class EmployeeLedgerHistoryBloc
    extends Bloc<EmployeeLedgerHistoryEvent, EmployeeLedgerHistoryState> {
  EmployeeLedgerHistoryBloc({
    required EmployeeSalaryRepository salaryRepository,
  })  : _salaryRepository = salaryRepository,
        super(const EmployeeLedgerHistoryState()) {
    on<EmployeeLedgerHistoryWatchStarted>(_onWatchStarted);
    on<EmployeeLedgerHistoryWatchStopped>(_onWatchStopped);
    on<_EmployeeLedgerHistoryUpdated>(_onUpdated);
    on<_EmployeeLedgerHistoryFailed>(_onFailed);
  }

  final EmployeeSalaryRepository _salaryRepository;
  StreamSubscription<List<MonthlyLedger>>? _subscription;

  Future<void> _onWatchStarted(
    EmployeeLedgerHistoryWatchStarted event,
    Emitter<EmployeeLedgerHistoryState> emit,
  ) async {
    emit(
      EmployeeLedgerHistoryState(
        status: EmployeeLedgerHistoryStatus.loading,
        employeeId: event.employeeId,
      ),
    );

    await _subscription?.cancel();
    _subscription = _salaryRepository
        .watchLedgers(
          employeeId: event.employeeId,
          factoryId: event.factoryId,
        )
        .listen(
          (ledgers) => add(_EmployeeLedgerHistoryUpdated(ledgers)),
          onError: (_) => add(
            const _EmployeeLedgerHistoryFailed(
              'Could not load monthly ledgers.',
            ),
          ),
        );
  }

  Future<void> _onWatchStopped(
    EmployeeLedgerHistoryWatchStopped event,
    Emitter<EmployeeLedgerHistoryState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _onUpdated(
    _EmployeeLedgerHistoryUpdated event,
    Emitter<EmployeeLedgerHistoryState> emit,
  ) {
    emit(
      state.copyWith(
        status: EmployeeLedgerHistoryStatus.loaded,
        ledgers: event.ledgers,
        errorMessage: null,
      ),
    );
  }

  void _onFailed(
    _EmployeeLedgerHistoryFailed event,
    Emitter<EmployeeLedgerHistoryState> emit,
  ) {
    emit(
      state.copyWith(
        status: EmployeeLedgerHistoryStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

final class _EmployeeLedgerHistoryUpdated extends EmployeeLedgerHistoryEvent {
  const _EmployeeLedgerHistoryUpdated(this.ledgers);

  final List<MonthlyLedger> ledgers;

  @override
  List<Object?> get props => [ledgers];
}

final class _EmployeeLedgerHistoryFailed extends EmployeeLedgerHistoryEvent {
  const _EmployeeLedgerHistoryFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
