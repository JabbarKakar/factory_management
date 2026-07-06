import 'package:equatable/equatable.dart';

import '../enums/factory_role_enums.dart';
import '../enums/invite_enums.dart';

class TeamInvite extends Equatable {
  const TeamInvite({
    required this.id,
    required this.email,
    required this.factoryId,
    required this.role,
    required this.invitedBy,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.acceptedAt,
    this.acceptedBy,
  });

  final String id;
  final String email;
  final String factoryId;
  final FactoryRole role;
  final String invitedBy;
  final InviteStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final String? acceptedBy;

  bool get isExpired =>
      status == InviteStatus.pending && DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [
        id,
        email,
        factoryId,
        role,
        invitedBy,
        status,
        createdAt,
        expiresAt,
        acceptedAt,
        acceptedBy,
      ];
}
