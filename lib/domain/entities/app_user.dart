import 'package:equatable/equatable.dart';

import '../enums/user_enums.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.factoryId,
    this.photoUrl,
    this.employeeId,
    this.status = UserAccountStatus.active,
    this.onboardingComplete = false,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final String factoryId;
  final String? photoUrl;
  final String? employeeId;
  final UserAccountStatus status;
  final bool onboardingComplete;

  AppUser copyWith({
    String? name,
    String? role,
    String? factoryId,
    String? photoUrl,
    String? employeeId,
    UserAccountStatus? status,
    bool? onboardingComplete,
  }) {
    return AppUser(
      id: id,
      email: email,
      name: name ?? this.name,
      role: role ?? this.role,
      factoryId: factoryId ?? this.factoryId,
      photoUrl: photoUrl ?? this.photoUrl,
      employeeId: employeeId ?? this.employeeId,
      status: status ?? this.status,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        role,
        factoryId,
        photoUrl,
        employeeId,
        status,
        onboardingComplete,
      ];
}
