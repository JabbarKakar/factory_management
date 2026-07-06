import 'package:factory_management/blocs/auth/auth_bloc.dart';
import 'package:factory_management/data/repositories/auth_repository_contract.dart';
import 'package:factory_management/domain/entities/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepositoryContract {
  FakeAuthRepository({this.signUpImpl});

  final Future<AppUser> Function({
    required String email,
    required String password,
    required String name,
    required String factoryName,
    String? factoryPhone,
    String? factoryAddress,
  })? signUpImpl;

  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required String factoryName,
    String? factoryPhone,
    String? factoryAddress,
  }) {
    final handler = signUpImpl;
    if (handler == null) {
      throw StateError('signUpImpl is required');
    }
    return handler(
      email: email,
      password: password,
      name: name,
      factoryName: factoryName,
      factoryPhone: factoryPhone,
      factoryAddress: factoryAddress,
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}
}

void main() {
  const owner = AppUser(
    id: 'owner-1',
    email: 'owner@test.com',
    name: 'Owner',
    role: 'owner',
    factoryId: 'factory-1',
    onboardingComplete: true,
  );

  group('AuthBloc sign up', () {
    test('emits authenticated when sign up succeeds', () async {
      final repository = FakeAuthRepository(
        signUpImpl: ({
          required email,
          required password,
          required name,
          required factoryName,
          factoryPhone,
          factoryAddress,
        }) async {
          return owner;
        },
      );
      final bloc = AuthBloc(authRepository: repository);

      expectLater(
        bloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const AuthAuthenticated(owner),
        ]),
      );

      bloc.add(
        const AuthSignUpRequested(
          email: 'owner@test.com',
          password: 'secret1',
          name: 'Owner',
          factoryName: 'Test Factory',
        ),
      );

      await Future<void>.delayed(Duration.zero);
      await bloc.close();
    });

    test('emits failure when email is already in use', () async {
      final repository = FakeAuthRepository(
        signUpImpl: ({
          required email,
          required password,
          required name,
          required factoryName,
          factoryPhone,
          factoryAddress,
        }) async {
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'An account already exists for this email.',
          );
        },
      );
      final bloc = AuthBloc(authRepository: repository);

      expectLater(
        bloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const AuthFailure('An account already exists for this email.'),
        ]),
      );

      bloc.add(
        const AuthSignUpRequested(
          email: 'owner@test.com',
          password: 'secret1',
          name: 'Owner',
          factoryName: 'Test Factory',
        ),
      );

      await Future<void>.delayed(Duration.zero);
      await bloc.close();
    });
  });
}
