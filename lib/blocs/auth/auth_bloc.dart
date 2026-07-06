import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/repositories/auth_repository_contract.dart';
import '../../domain/entities/app_user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepositoryContract authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<_AuthUserChanged>(_onUserChanged);
  }

  final AuthRepositoryContract _authRepository;
  StreamSubscription<AppUser?>? _authSubscription;

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges.listen(
      (user) => add(_AuthUserChanged(user)),
    );
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapFirebaseError(e)));
    } catch (_) {
      emit(const AuthFailure('Login failed. Please try again.'));
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
        factoryName: event.factoryName,
        factoryPhone: event.factoryPhone,
        factoryAddress: event.factoryAddress,
      );
      emit(AuthAuthenticated(user));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapFirebaseError(e)));
    } catch (_) {
      emit(const AuthFailure('Registration failed. Please try again.'));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.sendPasswordResetEmail(event.email);
      emit(const AuthPasswordResetSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapFirebaseError(e)));
    } catch (_) {
      emit(const AuthFailure('Could not send reset email.'));
    }
  }

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    if (user != null) {
      emit(AuthAuthenticated(user));
      return;
    }
    emit(const AuthUnauthenticated());
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' => 'Invalid email address.',
      'invalid-argument' => e.message ?? 'Please check your registration details.',
      'email-already-in-use' => 'An account already exists for this email.',
      'weak-password' => 'Password must be at least 6 characters.',
      'operation-not-allowed' => 'Registration is not available right now.',
      'permission-denied' =>
        'Registration was blocked. Deploy the latest Firestore rules and try again.',
      'internal' => 'Registration failed. Please try again.',
      'profile-not-found' =>
        'Account profile not found. Complete registration or contact support.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' => 'No account found for this email.',
      'wrong-password' => 'Incorrect password.',
      'invalid-credential' => 'Invalid email or password.',
      'too-many-requests' => 'Too many attempts. Try again later.',
      _ => e.message ?? 'Authentication error.',
    };
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
