import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../core/utils/date_keys.dart';
import '../../data/repositories/employee_repository.dart';
import '../../data/repositories/employee_salary_repository.dart';
import '../../data/services/write_failure_message.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/monthly_ledger.dart';
import '../../domain/entities/wage_payment.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/labour_enums.dart';

part 'employee_salary_event.dart';
part 'employee_salary_state.dart';

class EmployeeSalaryBloc
    extends Bloc<EmployeeSalaryEvent, EmployeeSalaryState> {
  EmployeeSalaryBloc({
    required EmployeeRepository employeeRepository,
    required EmployeeSalaryRepository salaryRepository,
  })  : _employeeRepository = employeeRepository,
        _salaryRepository = salaryRepository,
        super(const EmployeeSalaryState()) {
    on<EmployeeSalaryWatchStarted>(_onWatchStarted);
    on<EmployeeSalaryWatchStopped>(_onWatchStopped);
    on<EmployeeSalaryPaymentRequested>(_onPaymentRequested);
    on<EmployeeSalaryCloseCycleRequested>(_onCloseCycleRequested);
    on<EmployeeSalaryReopenRequested>(_onReopenRequested);
    on<EmployeeSalaryRefreshPayableRequested>(_onRefreshPayableRequested);
    on<EmployeeSalarySnackbarCleared>(_onSnackbarCleared);
    on<_EmployeeSalaryEmployeeUpdated>(_onEmployeeUpdated);
    on<_EmployeeSalaryLedgerUpdated>(_onLedgerUpdated);
    on<_EmployeeSalaryPaymentsUpdated>(_onPaymentsUpdated);
    on<_EmployeeSalaryPaymentsFailed>(_onPaymentsFailed);
    on<_EmployeeSalaryStreamFailed>(_onStreamFailed);
  }

  final EmployeeRepository _employeeRepository;
  final EmployeeSalaryRepository _salaryRepository;

  StreamSubscription<Employee?>? _employeeSubscription;
  StreamSubscription<MonthlyLedger?>? _ledgerSubscription;
  StreamSubscription<List<WagePayment>>? _paymentsSubscription;
  bool _ensureInFlight = false;

  Future<void> _onWatchStarted(
    EmployeeSalaryWatchStarted event,
    Emitter<EmployeeSalaryState> emit,
  ) async {
    emit(
      EmployeeSalaryState(
        status: EmployeeSalaryStatus.loading,
        employeeId: event.employeeId,
        factoryId: event.factoryId,
        requestedMonthKey: event.monthKey,
        initializeIfMissing: event.initializeIfMissing,
      ),
    );

    await _cancelWatches();

    _employeeSubscription =
        _employeeRepository.watchEmployee(event.employeeId).listen(
              (employee) => add(_EmployeeSalaryEmployeeUpdated(employee)),
              onError: (_) => add(
                const _EmployeeSalaryStreamFailed(
                  'Could not load worker salary details.',
                ),
              ),
            );
  }

  Future<void> _onWatchStopped(
    EmployeeSalaryWatchStopped event,
    Emitter<EmployeeSalaryState> emit,
  ) async {
    await _cancelWatches();
  }

  Future<void> _onEmployeeUpdated(
    _EmployeeSalaryEmployeeUpdated event,
    Emitter<EmployeeSalaryState> emit,
  ) async {
    if (event.employee == null) {
      emit(
        state.copyWith(
          status: EmployeeSalaryStatus.failure,
          errorMessage: 'Worker not found.',
        ),
      );
      return;
    }

    final monthKey = state.requestedMonthKey ??
        event.employee!.activeMonthKey ??
        DateKeys.monthKey(DateTime.now());
    final previousMonthKey = state.monthKey;

    emit(
      state.copyWith(
        employee: event.employee,
        monthKey: monthKey,
        clearError: true,
      ),
    );

    if (previousMonthKey != monthKey || _ledgerSubscription == null) {
      await _bindLedgerWatches(
        employeeId: event.employee!.id,
        factoryId: event.employee!.factoryId,
        monthKey: monthKey,
        initializeIfMissing: state.initializeIfMissing,
        refreshPayable: event.employee!.salaryType == SalaryType.dailyRate,
      );
    }
  }

  Future<void> _bindLedgerWatches({
    required String employeeId,
    required String factoryId,
    required String monthKey,
    required bool initializeIfMissing,
    bool refreshPayable = false,
  }) async {
    await _ledgerSubscription?.cancel();
    await _paymentsSubscription?.cancel();
    _ledgerSubscription = null;
    _paymentsSubscription = null;

    if (initializeIfMissing && !_ensureInFlight) {
      _ensureInFlight = true;
      try {
        await _salaryRepository.ensureOpenLedger(
          employeeId: employeeId,
          monthKey: monthKey,
        );
        if (refreshPayable) {
          await _salaryRepository.refreshLedgerPayable(
            employeeId: employeeId,
            monthKey: monthKey,
          );
        }
      } catch (_) {
        // Viewers can still read an existing ledger; creation is best-effort.
      } finally {
        _ensureInFlight = false;
      }
    }

    _ledgerSubscription = _salaryRepository
        .watchLedger(employeeId: employeeId, monthKey: monthKey)
        .listen(
          (ledger) => add(_EmployeeSalaryLedgerUpdated(ledger)),
          onError: (_) => add(
            const _EmployeeSalaryStreamFailed(
              'Could not load the monthly salary ledger.',
            ),
          ),
        );

    _paymentsSubscription = _salaryRepository
        .watchPayments(
          employeeId: employeeId,
          monthKey: monthKey,
          factoryId: factoryId,
        )
        .listen(
          (payments) => add(_EmployeeSalaryPaymentsUpdated(payments)),
          onError: (_) => add(
            const _EmployeeSalaryPaymentsFailed(
              'Could not load wage payments.',
            ),
          ),
        );
  }

  void _onLedgerUpdated(
    _EmployeeSalaryLedgerUpdated event,
    Emitter<EmployeeSalaryState> emit,
  ) {
    emit(
      state.copyWith(
        status: EmployeeSalaryStatus.loaded,
        ledger: event.ledger,
        clearLedger: event.ledger == null,
      ),
    );
  }

  void _onPaymentsUpdated(
    _EmployeeSalaryPaymentsUpdated event,
    Emitter<EmployeeSalaryState> emit,
  ) {
    emit(
      state.copyWith(
        payments: event.payments,
        clearPaymentsError: true,
        status: state.employee != null
            ? EmployeeSalaryStatus.loaded
            : state.status,
      ),
    );
  }

  void _onPaymentsFailed(
    _EmployeeSalaryPaymentsFailed event,
    Emitter<EmployeeSalaryState> emit,
  ) {
    emit(
      state.copyWith(
        paymentsErrorMessage: event.message,
        status: state.employee != null
            ? EmployeeSalaryStatus.loaded
            : state.status,
      ),
    );
  }

  void _onStreamFailed(
    _EmployeeSalaryStreamFailed event,
    Emitter<EmployeeSalaryState> emit,
  ) {
    emit(
      state.copyWith(
        status: EmployeeSalaryStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  Future<void> _onPaymentRequested(
    EmployeeSalaryPaymentRequested event,
    Emitter<EmployeeSalaryState> emit,
  ) async {
    final monthKey = state.monthKey;
    if (monthKey == null || monthKey.isEmpty) return;

    emit(state.copyWith(actionStatus: EmployeeSalaryActionStatus.saving));
    try {
      await _salaryRepository.recordWorkerPayment(
        employeeId: state.employeeId,
        monthKey: monthKey,
        amount: event.amount,
        paymentMethod: event.paymentMethod.firestoreValue,
        recordedBy: event.recordedBy,
        recordedByName: event.recordedByName,
        notes: event.notes,
        paymentDate: event.paymentDate,
      );
      emit(
        state.copyWith(
          actionStatus: EmployeeSalaryActionStatus.success,
          snackbarMessage: 'Payment recorded.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: EmployeeSalaryActionStatus.failure,
          snackbarMessage: writeFailureMessage(
            error,
            fallback: error is StateError
                ? error.message
                : 'Could not record the payment.',
          ),
        ),
      );
    }
  }

  Future<void> _onCloseCycleRequested(
    EmployeeSalaryCloseCycleRequested event,
    Emitter<EmployeeSalaryState> emit,
  ) async {
    final monthKey = state.monthKey;
    if (monthKey == null || monthKey.isEmpty) return;

    emit(state.copyWith(actionStatus: EmployeeSalaryActionStatus.saving));
    try {
      await _salaryRepository.closeMonthlyCycle(
        employeeId: state.employeeId,
        monthKey: monthKey,
        rollOverAction: event.rolloverAction.name,
        closedBy: event.closedBy,
      );
      emit(
        state.copyWith(
          actionStatus: EmployeeSalaryActionStatus.success,
          snackbarMessage: 'Month closed.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: EmployeeSalaryActionStatus.failure,
          snackbarMessage: writeFailureMessage(
            error,
            fallback: error is StateError
                ? error.message
                : 'Could not close this month.',
          ),
        ),
      );
    }
  }

  Future<void> _onReopenRequested(
    EmployeeSalaryReopenRequested event,
    Emitter<EmployeeSalaryState> emit,
  ) async {
    final monthKey = state.monthKey;
    if (monthKey == null || monthKey.isEmpty) return;

    emit(state.copyWith(actionStatus: EmployeeSalaryActionStatus.saving));
    try {
      await _salaryRepository.reopenMonthlyCycle(
        employeeId: state.employeeId,
        monthKey: monthKey,
      );
      emit(
        state.copyWith(
          actionStatus: EmployeeSalaryActionStatus.success,
          snackbarMessage: 'Month reopened.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: EmployeeSalaryActionStatus.failure,
          snackbarMessage: writeFailureMessage(
            error,
            fallback: error is StateError
                ? error.message
                : 'Could not reopen this month.',
          ),
        ),
      );
    }
  }

  Future<void> _onRefreshPayableRequested(
    EmployeeSalaryRefreshPayableRequested event,
    Emitter<EmployeeSalaryState> emit,
  ) async {
    final monthKey = state.monthKey;
    if (monthKey == null || monthKey.isEmpty) return;

    emit(state.copyWith(actionStatus: EmployeeSalaryActionStatus.saving));
    try {
      await _salaryRepository.refreshLedgerPayable(
        employeeId: state.employeeId,
        monthKey: monthKey,
      );
      emit(
        state.copyWith(
          actionStatus: EmployeeSalaryActionStatus.success,
          snackbarMessage: 'Payable amount updated from attendance.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: EmployeeSalaryActionStatus.failure,
          snackbarMessage: writeFailureMessage(
            error,
            fallback: error is StateError
                ? error.message
                : 'Could not refresh the payable amount.',
          ),
        ),
      );
    }
  }

  void _onSnackbarCleared(
    EmployeeSalarySnackbarCleared event,
    Emitter<EmployeeSalaryState> emit,
  ) {
    emit(
      state.copyWith(
        actionStatus: EmployeeSalaryActionStatus.idle,
        clearSnackbar: true,
      ),
    );
  }

  Future<void> _cancelWatches() async {
    await _employeeSubscription?.cancel();
    await _ledgerSubscription?.cancel();
    await _paymentsSubscription?.cancel();
    _employeeSubscription = null;
    _ledgerSubscription = null;
    _paymentsSubscription = null;
  }

  @override
  Future<void> close() {
    _cancelWatches();
    return super.close();
  }
}

final class _EmployeeSalaryEmployeeUpdated extends EmployeeSalaryEvent {
  const _EmployeeSalaryEmployeeUpdated(this.employee);

  final Employee? employee;

  @override
  List<Object?> get props => [employee];
}

final class _EmployeeSalaryLedgerUpdated extends EmployeeSalaryEvent {
  const _EmployeeSalaryLedgerUpdated(this.ledger);

  final MonthlyLedger? ledger;

  @override
  List<Object?> get props => [ledger];
}

final class _EmployeeSalaryPaymentsUpdated extends EmployeeSalaryEvent {
  const _EmployeeSalaryPaymentsUpdated(this.payments);

  final List<WagePayment> payments;

  @override
  List<Object?> get props => [payments];
}

final class _EmployeeSalaryPaymentsFailed extends EmployeeSalaryEvent {
  const _EmployeeSalaryPaymentsFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class _EmployeeSalaryStreamFailed extends EmployeeSalaryEvent {
  const _EmployeeSalaryStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
