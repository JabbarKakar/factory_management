part of 'team_bloc.dart';

sealed class TeamEvent extends Equatable {
  const TeamEvent();

  @override
  List<Object?> get props => [];
}

final class TeamWatchStarted extends TeamEvent {
  const TeamWatchStarted({
    required this.factoryId,
    required this.currentUserId,
  });

  final String factoryId;
  final String currentUserId;

  @override
  List<Object?> get props => [factoryId, currentUserId];
}

final class TeamWatchStopped extends TeamEvent {
  const TeamWatchStopped();
}

final class TeamRoleChangeRequested extends TeamEvent {
  const TeamRoleChangeRequested({
    required this.userId,
    required this.role,
  });

  final String userId;
  final FactoryRole role;

  @override
  List<Object?> get props => [userId, role];
}

final class TeamEmployeeLinkRequested extends TeamEvent {
  const TeamEmployeeLinkRequested({
    required this.userId,
    required this.employeeId,
  });

  final String userId;
  final String? employeeId;

  @override
  List<Object?> get props => [userId, employeeId];
}

final class TeamInviteRequested extends TeamEvent {
  const TeamInviteRequested({
    required this.email,
    required this.role,
  });

  final String email;
  final FactoryRole role;

  @override
  List<Object?> get props => [email, role];
}

final class TeamInviteRevokeRequested extends TeamEvent {
  const TeamInviteRevokeRequested(this.inviteId);

  final String inviteId;

  @override
  List<Object?> get props => [inviteId];
}

/// UI acknowledged the freshly created invite (share sheet shown); clear it.
final class TeamInviteShareHandled extends TeamEvent {
  const TeamInviteShareHandled();
}
