import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/user_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/enums/factory_role_enums.dart';

part 'team_event.dart';
part 'team_state.dart';

class TeamBloc extends Bloc<TeamEvent, TeamState> {
  TeamBloc({required UserRepository repository})
      : _repository = repository,
        super(const TeamState()) {
    on<TeamWatchStarted>(_onWatchStarted);
    on<TeamWatchStopped>(_onWatchStopped);
    on<TeamRoleChangeRequested>(_onRoleChangeRequested);
    on<_TeamUsersUpdated>(_onUsersUpdated);
    on<_TeamStreamFailed>(_onStreamFailed);
  }

  final UserRepository _repository;
  StreamSubscription<List<AppUser>>? _subscription;

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

    await _subscription?.cancel();
    _subscription = _repository.watchFactoryUsers(event.factoryId).listen(
          (users) => add(_TeamUsersUpdated(users)),
          onError: (_) => add(const _TeamStreamFailed()),
        );
  }

  Future<void> _onWatchStopped(
    TeamWatchStopped event,
    Emitter<TeamState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
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

  void _onUsersUpdated(_TeamUsersUpdated event, Emitter<TeamState> emit) {
    emit(
      state.copyWith(
        status: TeamStatus.loaded,
        users: event.users,
        errorMessage: null,
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
    _subscription?.cancel();
    return super.close();
  }
}

final class _TeamUsersUpdated extends TeamEvent {
  const _TeamUsersUpdated(this.users);

  final List<AppUser> users;

  @override
  List<Object?> get props => [users];
}

final class _TeamStreamFailed extends TeamEvent {
  const _TeamStreamFailed();

  @override
  List<Object?> get props => [];
}
