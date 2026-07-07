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
    this.employees = const [],
    this.pendingInvites = const [],
    this.factoryId,
    this.currentUserId,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.createdInvite,
  });

  final TeamStatus status;
  final List<AppUser> users;
  final List<Employee> employees;
  final List<TeamInvite> pendingInvites;
  final String? factoryId;
  final String? currentUserId;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  /// Set right after an invite is created so the UI can present the share code,
  /// then cleared via [TeamInviteShareHandled].
  final TeamInvite? createdInvite;

  TeamState copyWith({
    TeamStatus? status,
    List<AppUser>? users,
    List<Employee>? employees,
    List<TeamInvite>? pendingInvites,
    String? factoryId,
    String? currentUserId,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    TeamInvite? createdInvite,
    bool clearMessage = false,
    bool clearCreatedInvite = false,
  }) {
    return TeamState(
      status: status ?? this.status,
      users: users ?? this.users,
      employees: employees ?? this.employees,
      pendingInvites: pendingInvites ?? this.pendingInvites,
      factoryId: factoryId ?? this.factoryId,
      currentUserId: currentUserId ?? this.currentUserId,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearMessage ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearMessage ? null : successMessage ?? this.successMessage,
      createdInvite:
          clearCreatedInvite ? null : createdInvite ?? this.createdInvite,
    );
  }

  @override
  List<Object?> get props => [
        status,
        users,
        employees,
        pendingInvites,
        factoryId,
        currentUserId,
        isSaving,
        errorMessage,
        successMessage,
        createdInvite,
      ];
}
