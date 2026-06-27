part of 'team_bloc.dart';

enum TeamStatus {
  initial,
  loading,
  loaded,
  failure,
}

class TeamState extends Equatable {
  const TeamState({
    this.status = TeamStatus.initial,
    this.users = const [],
    this.factoryId,
    this.currentUserId,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  final TeamStatus status;
  final List<AppUser> users;
  final String? factoryId;
  final String? currentUserId;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  TeamState copyWith({
    TeamStatus? status,
    List<AppUser>? users,
    String? factoryId,
    String? currentUserId,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearMessage = false,
  }) {
    return TeamState(
      status: status ?? this.status,
      users: users ?? this.users,
      factoryId: factoryId ?? this.factoryId,
      currentUserId: currentUserId ?? this.currentUserId,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearMessage ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearMessage ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        users,
        factoryId,
        currentUserId,
        isSaving,
        errorMessage,
        successMessage,
      ];
}
