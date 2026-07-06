import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/team_invite.dart';
import '../../domain/enums/factory_role_enums.dart';
import '../../domain/enums/invite_enums.dart';

class TeamInviteModel {
  const TeamInviteModel({
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

  factory TeamInviteModel.fromFirestore(String id, Map<String, dynamic> data) {
    return TeamInviteModel(
      id: id,
      email: (data['email'] as String? ?? '').trim().toLowerCase(),
      factoryId: data['factoryId'] as String? ?? '',
      role: FactoryRole.fromString(data['role'] as String?),
      invitedBy: data['invitedBy'] as String? ?? '',
      status: InviteStatus.fromString(data['status'] as String?),
      createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
      expiresAt: _readDate(data['expiresAt']) ?? DateTime.now(),
      acceptedAt: _readDate(data['acceptedAt']),
      acceptedBy: data['acceptedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'email': email,
      'factoryId': factoryId,
      'role': role.firestoreValue,
      'invitedBy': invitedBy,
      'status': status.firestoreValue,
      'createdAt': isCreate ? FieldValue.serverTimestamp() : createdAt,
      'expiresAt': Timestamp.fromDate(expiresAt),
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
      if (acceptedBy != null && acceptedBy!.isNotEmpty) 'acceptedBy': acceptedBy,
    };
  }

  TeamInvite toEntity() {
    return TeamInvite(
      id: id,
      email: email,
      factoryId: factoryId,
      role: role,
      invitedBy: invitedBy,
      status: status,
      createdAt: createdAt,
      expiresAt: expiresAt,
      acceptedAt: acceptedAt,
      acceptedBy: acceptedBy,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
