import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/team_invite.dart';
import '../../domain/enums/factory_role_enums.dart';
import '../../domain/enums/invite_enums.dart';
import '../models/team_invite_model.dart';

class InviteRepository {
  InviteRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('invites');

  Future<TeamInvite?> getInvite(String inviteId) async {
    final doc = await _collection.doc(inviteId).get();
    if (!doc.exists || doc.data() == null) return null;
    return TeamInviteModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Stream<TeamInvite?> watchInvite(String inviteId) {
    return _collection.doc(inviteId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return TeamInviteModel.fromFirestore(doc.id, doc.data()!).toEntity();
    });
  }

  /// All invites for a factory, newest first. Owner-only via Firestore rules.
  Stream<List<TeamInvite>> watchFactoryInvites(String factoryId) {
    return _collection
        .where('factoryId', isEqualTo: factoryId)
        .snapshots()
        .map((snapshot) {
          final invites = snapshot.docs
              .map(
                (doc) =>
                    TeamInviteModel.fromFirestore(doc.id, doc.data()).toEntity(),
              )
              .toList();
          invites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return invites;
        });
  }

  /// Pending invites only (excludes expired-by-date still marked pending).
  Stream<List<TeamInvite>> watchPendingFactoryInvites(String factoryId) {
    return watchFactoryInvites(factoryId).map(
      (invites) => invites
          .where(
            (invite) =>
                invite.status == InviteStatus.pending && !invite.isExpired,
          )
          .toList(),
    );
  }

  /// Default invite validity window (client-side flow, no Cloud Functions).
  static const Duration defaultValidity = Duration(days: 7);

  /// Owner creates a pending invite. Returns the created invite (whose [id] is
  /// the shareable invite code the invitee enters when accepting).
  Future<TeamInvite> createInvite({
    required String factoryId,
    required String email,
    required FactoryRole role,
    required String invitedBy,
    Duration validFor = defaultValidity,
  }) async {
    if (role == FactoryRole.owner) {
      throw ArgumentError('Cannot invite a member as owner.');
    }
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw ArgumentError('Invite email is required.');
    }

    final docRef = _collection.doc();
    final now = DateTime.now();
    final model = TeamInviteModel(
      id: docRef.id,
      email: normalizedEmail,
      factoryId: factoryId,
      role: role,
      invitedBy: invitedBy,
      status: InviteStatus.pending,
      createdAt: now,
      expiresAt: now.add(validFor),
    );

    await docRef.set(model.toFirestore(isCreate: true));
    final created = await getInvite(docRef.id);
    return created ?? model.toEntity();
  }

  /// Owner revokes a pending invite.
  Future<void> revokeInvite(String inviteId) async {
    await _collection.doc(inviteId).update({
      'status': InviteStatus.revoked.firestoreValue,
    });
  }
}
