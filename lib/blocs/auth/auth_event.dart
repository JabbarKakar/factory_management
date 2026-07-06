part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.factoryName,
    this.factoryPhone,
    this.factoryAddress,
  });

  final String email;
  final String password;
  final String name;
  final String factoryName;
  final String? factoryPhone;
  final String? factoryAddress;

  @override
  List<Object?> get props => [
        email,
        password,
        name,
        factoryName,
        factoryPhone,
        factoryAddress,
      ];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

final class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

final class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);

  final AppUser? user;

  @override
  List<Object?> get props => [user];
}
