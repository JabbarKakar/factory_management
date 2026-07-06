import '../../domain/entities/app_user.dart';
import '../../domain/enums/user_enums.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.factoryId,
    required this.createdAt,
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
  final DateTime? createdAt;
  final String? photoUrl;
  final String? employeeId;
  final UserAccountStatus status;
  final bool onboardingComplete;

  factory UserModel.fromFirestore(
    String id,
    Map<String, dynamic> data, {
    String? authPhotoUrl,
  }) {
    final storedPhoto = data['photoUrl'] as String?;
    final employeeId = data['employeeId'] as String?;
    return UserModel(
      id: id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? 'viewer',
      factoryId: data['factoryId'] as String? ?? 'default',
      createdAt: (data['createdAt'] as dynamic)?.toDate() as DateTime?,
      photoUrl: _resolvePhotoUrl(storedPhoto, authPhotoUrl),
      employeeId: employeeId != null && employeeId.isNotEmpty ? employeeId : null,
      status: UserAccountStatus.fromString(data['status'] as String?),
      onboardingComplete: data['onboardingComplete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'factoryId': factoryId,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (employeeId != null && employeeId!.isNotEmpty) 'employeeId': employeeId,
      'status': status.firestoreValue,
      'onboardingComplete': onboardingComplete,
      'createdAt': createdAt,
    };
  }

  AppUser toEntity() {
    return AppUser(
      id: id,
      email: email,
      name: name,
      role: role,
      factoryId: factoryId,
      photoUrl: photoUrl,
      employeeId: employeeId,
      status: status,
      onboardingComplete: onboardingComplete,
    );
  }

  static String? _resolvePhotoUrl(String? stored, String? authPhotoUrl) {
    if (stored != null && stored.isNotEmpty) return stored;
    if (authPhotoUrl != null && authPhotoUrl.isNotEmpty) return authPhotoUrl;
    return null;
  }
}
