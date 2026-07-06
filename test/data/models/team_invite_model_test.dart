import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:factory_management/data/models/team_invite_model.dart';
import 'package:factory_management/domain/enums/factory_role_enums.dart';
import 'package:factory_management/domain/enums/invite_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TeamInviteModel', () {
    final createdAt = DateTime(2026, 7, 1, 10, 0);
    final expiresAt = DateTime(2026, 7, 8, 10, 0);

    test('fromFirestore maps fields and normalizes email', () {
      final model = TeamInviteModel.fromFirestore('invite-1', {
        'email': '  Member@Example.COM ',
        'factoryId': 'factory-1',
        'role': 'accountant',
        'invitedBy': 'owner-1',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });

      expect(model.id, 'invite-1');
      expect(model.email, 'member@example.com');
      expect(model.factoryId, 'factory-1');
      expect(model.role, FactoryRole.accountant);
      expect(model.invitedBy, 'owner-1');
      expect(model.status, InviteStatus.pending);
      expect(model.createdAt, createdAt);
      expect(model.expiresAt, expiresAt);
      expect(model.acceptedAt, isNull);
      expect(model.acceptedBy, isNull);
    });

    test('fromFirestore defaults missing values for backward compatibility', () {
      final model = TeamInviteModel.fromFirestore('invite-2', {});

      expect(model.email, '');
      expect(model.factoryId, '');
      expect(model.role, FactoryRole.owner);
      expect(model.status, InviteStatus.pending);
      expect(model.invitedBy, '');
    });

    test('toFirestore serializes role and status', () {
      final model = TeamInviteModel(
        id: 'invite-3',
        email: 'staff@test.com',
        factoryId: 'factory-1',
        role: FactoryRole.factoryManager,
        invitedBy: 'owner-1',
        status: InviteStatus.revoked,
        createdAt: createdAt,
        expiresAt: expiresAt,
        acceptedAt: createdAt,
        acceptedBy: 'user-9',
      );

      final data = model.toFirestore();

      expect(data['email'], 'staff@test.com');
      expect(data['factoryId'], 'factory-1');
      expect(data['role'], 'factoryManager');
      expect(data['invitedBy'], 'owner-1');
      expect(data['status'], 'revoked');
      expect(data['expiresAt'], Timestamp.fromDate(expiresAt));
      expect(data['acceptedAt'], Timestamp.fromDate(createdAt));
      expect(data['acceptedBy'], 'user-9');
    });

    test('toEntity preserves invite fields', () {
      final model = TeamInviteModel(
        id: 'invite-4',
        email: 'driver@test.com',
        factoryId: 'factory-1',
        role: FactoryRole.driver,
        invitedBy: 'owner-1',
        status: InviteStatus.accepted,
        createdAt: createdAt,
        expiresAt: expiresAt,
        acceptedAt: createdAt,
        acceptedBy: 'driver-1',
      );

      final entity = model.toEntity();

      expect(entity.id, model.id);
      expect(entity.email, model.email);
      expect(entity.role, FactoryRole.driver);
      expect(entity.status, InviteStatus.accepted);
      expect(entity.acceptedBy, 'driver-1');
    });
  });
}
