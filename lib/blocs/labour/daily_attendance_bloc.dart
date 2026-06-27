import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../core/utils/date_keys.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/employee_repository.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/employee.dart';
import '../../domain/enums/labour_enums.dart';

part 'daily_attendance_event.dart';
part 'daily_attendance_state.dart';

DateTime _todayDateOnly() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

class DailyAttendanceBloc extends Bloc<DailyAttendanceEvent, DailyAttendanceState> {
  DailyAttendanceBloc({
    required EmployeeRepository employeeRepository,
    required AttendanceRepository attendanceRepository,
  })  : _employeeRepository = employeeRepository,
        _attendanceRepository = attendanceRepository,
        super(DailyAttendanceState(selectedDate: _todayDateOnly())) {
    on<DailyAttendanceWatchStarted>(_onWatchStarted);
    on<DailyAttendanceWatchStopped>(_onWatchStopped);
    on<DailyAttendanceDateChanged>(_onDateChanged);
    on<DailyAttendanceShiftChanged>(_onShiftChanged);
    on<DailyAttendanceStatusChanged>(_onStatusChanged);
    on<DailyAttendanceMarkAllPresentRequested>(_onMarkAllPresent);
    on<DailyAttendanceSearchChanged>(_onSearchChanged);
    on<_DailyAttendanceEmployeesUpdated>(_onEmployeesUpdated);
    on<_DailyAttendanceRecordsUpdated>(_onRecordsUpdated);
    on<_DailyAttendanceStreamFailed>(_onStreamFailed);
  }

  final EmployeeRepository _employeeRepository;
  final AttendanceRepository _attendanceRepository;
  StreamSubscription<List<Employee>>? _employeeSubscription;
  StreamSubscription<List<AttendanceRecord>>? _attendanceSubscription;
  String? _factoryId;
  List<Employee> _employees = const [];
  List<AttendanceRecord> _records = const [];

  Future<void> _onWatchStarted(
    DailyAttendanceWatchStarted event,
    Emitter<DailyAttendanceState> emit,
  ) async {
    _factoryId = event.factoryId;
    final date = DateKeys.dateOnly(event.initialDate ?? _todayDateOnly());

    emit(
      state.copyWith(
        status: DailyAttendanceStatus.loading,
        selectedDate: date,
        clearErrorMessage: true,
        clearActionMessage: true,
      ),
    );

    await _restartAttendanceWatch(date);

    await _employeeSubscription?.cancel();
    _employeeSubscription =
        _employeeRepository.watchEmployees(event.factoryId).listen(
              (employees) => add(_DailyAttendanceEmployeesUpdated(employees)),
              onError: (_) => add(
                const _DailyAttendanceStreamFailed(
                  'Could not load employees.',
                ),
              ),
            );
  }

  Future<void> _onWatchStopped(
    DailyAttendanceWatchStopped event,
    Emitter<DailyAttendanceState> emit,
  ) async {
    await _employeeSubscription?.cancel();
    await _attendanceSubscription?.cancel();
    _employeeSubscription = null;
    _attendanceSubscription = null;
  }

  Future<void> _onDateChanged(
    DailyAttendanceDateChanged event,
    Emitter<DailyAttendanceState> emit,
  ) async {
    final date = DateKeys.dateOnly(event.date);
    emit(
      state.copyWith(
        status: DailyAttendanceStatus.loading,
        selectedDate: date,
        clearErrorMessage: true,
        clearActionMessage: true,
      ),
    );
    await _restartAttendanceWatch(date);
    _emitMerged(emit);
  }

  void _onShiftChanged(
    DailyAttendanceShiftChanged event,
    Emitter<DailyAttendanceState> emit,
  ) {
    emit(state.copyWith(defaultShift: event.shift));
  }

  void _onSearchChanged(
    DailyAttendanceSearchChanged event,
    Emitter<DailyAttendanceState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onStatusChanged(
    DailyAttendanceStatusChanged event,
    Emitter<DailyAttendanceState> emit,
  ) async {
    final factoryId = _factoryId;
    if (factoryId == null) return;

    emit(state.copyWith(status: DailyAttendanceStatus.saving, clearErrorMessage: true));
    try {
      await _attendanceRepository.upsertAttendance(
        factoryId: factoryId,
        employeeId: event.employeeId,
        date: state.selectedDate,
        status: event.status,
        shift: state.defaultShift,
      );
      emit(
        state.copyWith(
          status: DailyAttendanceStatus.loaded,
          actionMessage: 'Attendance saved',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: DailyAttendanceStatus.failure,
          errorMessage: 'Could not save attendance.',
        ),
      );
    }
  }

  Future<void> _onMarkAllPresent(
    DailyAttendanceMarkAllPresentRequested event,
    Emitter<DailyAttendanceState> emit,
  ) async {
    final factoryId = _factoryId;
    if (factoryId == null) return;

    final activeIds = _employees
        .where((employee) => employee.isActive)
        .map((employee) => employee.id)
        .toList();
    if (activeIds.isEmpty) return;

    emit(state.copyWith(status: DailyAttendanceStatus.saving, clearErrorMessage: true));
    try {
      await _attendanceRepository.markAllPresent(
        factoryId: factoryId,
        employeeIds: activeIds,
        date: state.selectedDate,
        shift: state.defaultShift,
      );
      emit(
        state.copyWith(
          status: DailyAttendanceStatus.loaded,
          actionMessage: 'All active workers marked present',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: DailyAttendanceStatus.failure,
          errorMessage: 'Could not mark all present.',
        ),
      );
    }
  }

  void _onEmployeesUpdated(
    _DailyAttendanceEmployeesUpdated event,
    Emitter<DailyAttendanceState> emit,
  ) {
    _employees = event.employees;
    _emitMerged(emit);
  }

  void _onRecordsUpdated(
    _DailyAttendanceRecordsUpdated event,
    Emitter<DailyAttendanceState> emit,
  ) {
    _records = event.records;
    _emitMerged(emit);
  }

  void _onStreamFailed(
    _DailyAttendanceStreamFailed event,
    Emitter<DailyAttendanceState> emit,
  ) {
    emit(
      state.copyWith(
        status: DailyAttendanceStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  Future<void> _restartAttendanceWatch(DateTime date) async {
    final factoryId = _factoryId;
    if (factoryId == null) return;

    await _attendanceSubscription?.cancel();
    _attendanceSubscription = _attendanceRepository
        .watchForDate(factoryId: factoryId, date: date)
        .listen(
          (records) => add(_DailyAttendanceRecordsUpdated(records)),
          onError: (_) => add(
            const _DailyAttendanceStreamFailed(
              'Could not load attendance for this date.',
            ),
          ),
        );
  }

  void _emitMerged(Emitter<DailyAttendanceState> emit) {
    final activeEmployees =
        _employees.where((employee) => employee.isActive).toList();
    final recordByEmployee = {
      for (final record in _records) record.employeeId: record,
    };

    final entries = activeEmployees
        .map(
          (employee) => DailyAttendanceEntry(
            employee: employee,
            record: recordByEmployee[employee.id],
          ),
        )
        .toList();

    emit(
      state.copyWith(
        status: DailyAttendanceStatus.loaded,
        entries: entries,
        errorMessage: null,
      ),
    );
  }

  @override
  Future<void> close() {
    _employeeSubscription?.cancel();
    _attendanceSubscription?.cancel();
    return super.close();
  }
}

final class _DailyAttendanceEmployeesUpdated extends DailyAttendanceEvent {
  const _DailyAttendanceEmployeesUpdated(this.employees);

  final List<Employee> employees;

  @override
  List<Object?> get props => [employees];
}

final class _DailyAttendanceRecordsUpdated extends DailyAttendanceEvent {
  const _DailyAttendanceRecordsUpdated(this.records);

  final List<AttendanceRecord> records;

  @override
  List<Object?> get props => [records];
}

final class _DailyAttendanceStreamFailed extends DailyAttendanceEvent {
  const _DailyAttendanceStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
