import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/team_invite.dart';
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

  /// Owner revokes a pending invite (client-side until S34 Function exists).
  Future<void> revokeInvite(String inviteId) async {
    await _collection.doc(inviteId).update({
      'status': InviteStatus.revoked.firestoreValue,
    });
  }
}
