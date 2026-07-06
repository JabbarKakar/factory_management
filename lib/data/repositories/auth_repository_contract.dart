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

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);
}
