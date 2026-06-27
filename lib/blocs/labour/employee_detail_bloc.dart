import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/employee_repository.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/employee.dart';

part 'employee_detail_event.dart';
part 'employee_detail_state.dart';

class EmployeeDetailBloc extends Bloc<EmployeeDetailEvent, EmployeeDetailState> {
  EmployeeDetailBloc({
    required EmployeeRepository employeeRepository,
    required AttendanceRepository attendanceRepository,
  })  : _employeeRepository = employeeRepository,
        _attendanceRepository = attendanceRepository,
        super(const EmployeeDetailState()) {
    on<EmployeeDetailWatchStarted>(_onWatchStarted);
    on<EmployeeDetailWatchStopped>(_onWatchStopped);
    on<_EmployeeDetailEmployeeUpdated>(_onEmployeeUpdated);
    on<_EmployeeDetailAttendanceUpdated>(_onAttendanceUpdated);
    on<_EmployeeDetailStreamFailed>(_onStreamFailed);
  }

  final EmployeeRepository _employeeRepository;
  final AttendanceRepository _attendanceRepository;
  StreamSubscription<Employee?>? _employeeSubscription;
  StreamSubscription<List<AttendanceRecord>>? _attendanceSubscription;

  Future<void> _onWatchStarted(
    EmployeeDetailWatchStarted event,
    Emitter<EmployeeDetailState> emit,
  ) async {
    emit(state.copyWith(status: EmployeeDetailStatus.loading));

    await _employeeSubscription?.cancel();
    await _attendanceSubscription?.cancel();

    _employeeSubscription =
        _employeeRepository.watchEmployee(event.employeeId).listen(
              (employee) => add(_EmployeeDetailEmployeeUpdated(employee)),
              onError: (_) => add(
                const _EmployeeDetailStreamFailed(
                  'Could not load employee details.',
                ),
              ),
            );

    _attendanceSubscription = _attendanceRepository
        .watchForEmployee(
          factoryId: event.factoryId,
          employeeId: event.employeeId,
        )
        .listen(
          (records) => add(_EmployeeDetailAttendanceUpdated(records)),
          onError: (_) => add(
            const _EmployeeDetailStreamFailed(
              'Could not load attendance history.',
            ),
          ),
        );
  }

  Future<void> _onWatchStopped(
    EmployeeDetailWatchStopped event,
    Emitter<EmployeeDetailState> emit,
  ) async {
    await _employeeSubscription?.cancel();
    await _attendanceSubscription?.cancel();
    _employeeSubscription = null;
    _attendanceSubscription = null;
  }

  void _onEmployeeUpdated(
    _EmployeeDetailEmployeeUpdated event,
    Emitter<EmployeeDetailState> emit,
  ) {
    if (event.employee == null) {
      emit(
        state.copyWith(
          status: EmployeeDetailStatus.failure,
          errorMessage: 'Employee not found.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: EmployeeDetailStatus.loaded,
        employee: event.employee,
        errorMessage: null,
      ),
    );
  }

  void _onAttendanceUpdated(
    _EmployeeDetailAttendanceUpdated event,
    Emitter<EmployeeDetailState> emit,
  ) {
    emit(
      state.copyWith(
        attendanceRecords: event.records,
        status: state.employee != null
            ? EmployeeDetailStatus.loaded
            : state.status,
      ),
    );
  }

  void _onStreamFailed(
    _EmployeeDetailStreamFailed event,
    Emitter<EmployeeDetailState> emit,
  ) {
    emit(
      state.copyWith(
        status: EmployeeDetailStatus.failure,
        errorMessage: event.message,
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

final class _EmployeeDetailEmployeeUpdated extends EmployeeDetailEvent {
  const _EmployeeDetailEmployeeUpdated(this.employee);

  final Employee? employee;

  @override
  List<Object?> get props => [employee];
}

final class _EmployeeDetailAttendanceUpdated extends EmployeeDetailEvent {
  const _EmployeeDetailAttendanceUpdated(this.records);

  final List<AttendanceRecord> records;

  @override
  List<Object?> get props => [records];
}

final class _EmployeeDetailStreamFailed extends EmployeeDetailEvent {
  const _EmployeeDetailStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
