import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/enums/factory_enums.dart';
import '../../domain/enums/factory_role_enums.dart';
import '../../domain/enums/invite_enums.dart';
import '../../domain/enums/user_enums.dart';
import '../models/factory_model.dart';
import '../models/team_invite_model.dart';
import '../models/user_model.dart';
import 'auth_repository_contract.dart';

class AuthRepository implements AuthRepositoryContract {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<AppUser?>.value(null);
      }

      return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) {
          return _transientUserFromAuth(user);
        }

        return UserModel.fromFirestore(
          user.uid,
          doc.data()!,
          authPhotoUrl: user.photoURL,
        ).toEntity();
      });
    });
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Sign in failed.',
      );
    }
    return _loadUserProfile(user);
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required String factoryName,
    String? factoryPhone,
    String? factoryAddress,
  }) async {
    User? authUser;
    DocumentReference<Map<String, dynamic>>? factoryRef;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      authUser = credential.user;
      if (authUser == null) {
        throw FirebaseAuthException(
          code: 'internal',
          message: 'Registration failed. Please try again.',
        );
      }

      // Ensure Firestore sees the new Auth session before bootstrap writes.
      await authUser.getIdToken(true);

      final uid = authUser.uid;
      final trimmedName = name.trim();
      final trimmedFactoryName = factoryName.trim();
      final trimmedEmail = email.trim().toLowerCase();
      factoryRef = _firestore.collection('factories').doc();
      final userRef = _firestore.collection('users').doc(uid);

      final factoryModel = FactoryModel(
        id: factoryRef.id,
        name: trimmedFactoryName,
        phone: factoryPhone?.trim(),
        address: factoryAddress?.trim(),
        ownerName: trimmedName,
        ownerUserId: uid,
        status: FactoryStatus.active,
      );

      final userModel = UserModel(
        id: uid,
        email: trimmedEmail,
        name: trimmedName,
        role: 'owner',
        factoryId: factoryRef.id,
        createdAt: null,
        status: UserAccountStatus.active,
        onboardingComplete: true,
      );

      // Sequential writes: user bootstrap rules require the factory doc to exist.
      await factoryRef.set(factoryModel.toFirestore(isCreate: true));
      await userRef.set({
        ...userModel.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (authUser.displayName != trimmedName) {
        await authUser.updateDisplayName(trimmedName);
      }

      return userModel.toEntity();
    } on FirebaseAuthException {
      await _rollbackBootstrap(authUser, factoryRef);
      rethrow;
    } on FirebaseException catch (e) {
      await _rollbackBootstrap(authUser, factoryRef);
      throw FirebaseAuthException(
        code: e.code == 'permission-denied'
            ? 'permission-denied'
            : 'internal',
        message: e.code == 'permission-denied'
            ? 'Registration was blocked by security rules. Deploy the latest Firestore rules and try again.'
            : 'Registration failed. Please try again.',
      );
    } catch (_) {
      await _rollbackBootstrap(authUser, factoryRef);
      throw FirebaseAuthException(
        code: 'internal',
        message: 'Registration failed. Please try again.',
      );
    }
  }

  @override
  Future<AppUser> acceptInvite({
    required String inviteCode,
    required String email,
    required String password,
    required String name,
  }) async {
    final code = inviteCode.trim();
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedName = name.trim();

    if (code.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-argument',
        message: 'Enter the invite code your factory owner shared with you.',
      );
    }

    User? authUser;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      authUser = credential.user;
      if (authUser == null) {
        throw FirebaseAuthException(
          code: 'internal',
          message: 'Could not join the factory. Please try again.',
        );
      }

      // Refresh the token so Firestore rules see request.auth.token.email.
      await authUser.getIdToken(true);

      final inviteRef = _firestore.collection('invites').doc(code);
      final inviteSnap = await inviteRef.get();
      if (!inviteSnap.exists || inviteSnap.data() == null) {
        throw FirebaseAuthException(
          code: 'invite-not-found',
          message: 'Invite code not found. Check the code and try again.',
        );
      }

      final invite =
          TeamInviteModel.fromFirestore(inviteSnap.id, inviteSnap.data()!)
              .toEntity();

      if (invite.email != trimmedEmail) {
        throw FirebaseAuthException(
          code: 'invite-email-mismatch',
          message:
              'This invite was sent to a different email address. Use the '
              'email your factory owner invited.',
        );
      }
      if (invite.status != InviteStatus.pending) {
        throw FirebaseAuthException(
          code: 'invite-not-pending',
          message: 'This invite is no longer active.',
        );
      }
      if (invite.isExpired) {
        throw FirebaseAuthException(
          code: 'invite-expired',
          message: 'This invite has expired. Ask the owner for a new one.',
        );
      }
      if (invite.role == FactoryRole.owner) {
        throw FirebaseAuthException(
          code: 'invalid-argument',
          message: 'This invite is invalid.',
        );
      }

      final uid = authUser.uid;
      final userRef = _firestore.collection('users').doc(uid);

      final batch = _firestore.batch();
      batch.set(userRef, {
        'email': trimmedEmail,
        'name': trimmedName,
        'role': invite.role.firestoreValue,
        'factoryId': invite.factoryId,
        'status': UserAccountStatus.active.firestoreValue,
        'onboardingComplete': true,
        'inviteId': code,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(inviteRef, {
        'status': InviteStatus.accepted.firestoreValue,
        'acceptedBy': uid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      if (authUser.displayName != trimmedName) {
        await authUser.updateDisplayName(trimmedName);
      }

      return UserModel(
        id: uid,
        email: trimmedEmail,
        name: trimmedName,
        role: invite.role.firestoreValue,
        factoryId: invite.factoryId,
        createdAt: null,
        status: UserAccountStatus.active,
        onboardingComplete: true,
      ).toEntity();
    } on FirebaseAuthException {
      await _rollbackAuthUser(authUser);
      rethrow;
    } on FirebaseException catch (e) {
      await _rollbackAuthUser(authUser);
      throw FirebaseAuthException(
        code: e.code == 'permission-denied' ? 'permission-denied' : 'internal',
        message: e.code == 'permission-denied'
            ? 'Joining was blocked by security rules. Ask the owner to deploy '
                'the latest Firestore rules, then try again.'
            : 'Could not join the factory. Please try again.',
      );
    } catch (_) {
      await _rollbackAuthUser(authUser);
      throw FirebaseAuthException(
        code: 'internal',
        message: 'Could not join the factory. Please try again.',
      );
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<AppUser> _loadUserProfile(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (doc.exists && doc.data() != null) {
      return UserModel.fromFirestore(
        user.uid,
        doc.data()!,
        authPhotoUrl: user.photoURL,
      ).toEntity();
    }

    throw FirebaseAuthException(
      code: 'profile-not-found',
      message:
          'Account profile not found. Complete registration or contact support.',
    );
  }

  AppUser _transientUserFromAuth(User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? user.email?.split('@').first ?? 'User',
      role: 'viewer',
      factoryId: '',
      createdAt: null,
      photoUrl: user.photoURL,
      onboardingComplete: false,
    ).toEntity();
  }

  Future<void> _rollbackBootstrap(
    User? user,
    DocumentReference<Map<String, dynamic>>? factoryRef,
  ) async {
    if (factoryRef != null) {
      try {
        await factoryRef.delete();
      } catch (_) {
        // Best-effort cleanup of orphaned factory doc.
      }
    }
    await _rollbackAuthUser(user);
  }

  Future<void> _rollbackAuthUser(User? user) async {
    if (user == null) return;
    try {
      await user.delete();
    } catch (_) {
      // Best-effort rollback if Firestore bootstrap fails after Auth create.
    }
  }
}
