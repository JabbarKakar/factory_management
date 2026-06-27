import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/employee_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/employee.dart';
import '../../domain/enums/factory_role_enums.dart';

part 'team_event.dart';
part 'team_state.dart';

class TeamBloc extends Bloc<TeamEvent, TeamState> {
  TeamBloc({
    required UserRepository repository,
    required EmployeeRepository employeeRepository,
  })  : _repository = repository,
        _employeeRepository = employeeRepository,
        super(const TeamState()) {
    on<TeamWatchStarted>(_onWatchStarted);
    on<TeamWatchStopped>(_onWatchStopped);
    on<TeamRoleChangeRequested>(_onRoleChangeRequested);
    on<TeamEmployeeLinkRequested>(_onEmployeeLinkRequested);
    on<_TeamUsersUpdated>(_onUsersUpdated);
    on<_TeamEmployeesUpdated>(_onEmployeesUpdated);
    on<_TeamStreamFailed>(_onStreamFailed);
  }

  final UserRepository _repository;
  final EmployeeRepository _employeeRepository;
  StreamSubscription<List<AppUser>>? _usersSubscription;
  StreamSubscription<List<Employee>>? _employeesSubscription;

  Future<void> _onWatchStarted(
    TeamWatchStarted event,
    Emitter<TeamState> emit,
  ) async {
    emit(
      state.copyWith(
        status: TeamStatus.loading,
        factoryId: event.factoryId,
        currentUserId: event.currentUserId,
      ),
    );

    await _usersSubscription?.cancel();
    await _employeesSubscription?.cancel();

    _usersSubscription = _repository.watchFactoryUsers(event.factoryId).listen(
          (users) => add(_TeamUsersUpdated(users)),
          onError: (_) => add(const _TeamStreamFailed()),
        );
    _employeesSubscription =
        _employeeRepository.watchEmployees(event.factoryId).listen(
              (employees) => add(_TeamEmployeesUpdated(employees)),
            );
  }

  Future<void> _onWatchStopped(
    TeamWatchStopped event,
    Emitter<TeamState> emit,
  ) async {
    await _usersSubscription?.cancel();
    await _employeesSubscription?.cancel();
    _usersSubscription = null;
    _employeesSubscription = null;
  }

  Future<void> _onRoleChangeRequested(
    TeamRoleChangeRequested event,
    Emitter<TeamState> emit,
  ) async {
    if (event.userId == state.currentUserId) return;

    emit(state.copyWith(isSaving: true, clearMessage: true));
    try {
      await _repository.updateUserRole(
        userId: event.userId,
        role: event.role,
      );
      emit(
        state.copyWith(
          isSaving: false,
          successMessage: 'Role updated.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Could not update role.',
        ),
      );
    }
  }

  Future<void> _onEmployeeLinkRequested(
    TeamEmployeeLinkRequested event,
    Emitter<TeamState> emit,
  ) async {
    if (event.userId == state.currentUserId) return;

    emit(state.copyWith(isSaving: true, clearMessage: true));
    try {
      await _repository.updateUserEmployeeLink(
        userId: event.userId,
        employeeId: event.employeeId,
      );
      emit(
        state.copyWith(
          isSaving: false,
          successMessage: 'Driver profile linked.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Could not link employee profile.',
        ),
      );
    }
  }

  void _onUsersUpdated(_TeamUsersUpdated event, Emitter<TeamState> emit) {
    emit(
      state.copyWith(
        status: TeamStatus.loaded,
        users: event.users,
        errorMessage: null,
      ),
    );
  }

  void _onEmployeesUpdated(
    _TeamEmployeesUpdated event,
    Emitter<TeamState> emit,
  ) {
    emit(
      state.copyWith(
        employees: event.employees,
      ),
    );
  }

  void _onStreamFailed(_TeamStreamFailed event, Emitter<TeamState> emit) {
    emit(
      state.copyWith(
        status: TeamStatus.failure,
        errorMessage: 'Could not load team members.',
      ),
    );
  }

  @override
  Future<void> close() {
    _usersSubscription?.cancel();
    _employeesSubscription?.cancel();
    return super.close();
  }
}

final class _TeamUsersUpdated extends TeamEvent {
  const _TeamUsersUpdated(this.users);

  final List<AppUser> users;

  @override
  List<Object?> get props => [users];
}

final class _TeamEmployeesUpdated extends TeamEvent {
  const _TeamEmployeesUpdated(this.employees);

  final List<Employee> employees;

  @override
  List<Object?> get props => [employees];
}

final class _TeamStreamFailed extends TeamEvent {
  const _TeamStreamFailed();

  @override
  List<Object?> get props => [];
}
