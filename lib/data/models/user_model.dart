import '../../domain/entities/app_user.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.factoryId,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final String factoryId;
  final DateTime? createdAt;

  factory UserModel.fromFirestore(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? 'owner',
      factoryId: data['factoryId'] as String? ?? 'default',
      createdAt: (data['createdAt'] as dynamic)?.toDate() as DateTime?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'factoryId': factoryId,
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
    );
  }
}
