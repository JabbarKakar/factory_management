import '../../domain/entities/app_user.dart';

abstract interface class AuthRepositoryContract {
  Stream<AppUser?> get authStateChanges;

  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required String factoryName,
    String? factoryPhone,
    String? factoryAddress,
  });

  /// Invitee joins an existing factory using an invite code (S34, client-side).
  Future<AppUser> acceptInvite({
    required String inviteCode,
    required String email,
    required String password,
    required String name,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);
}
