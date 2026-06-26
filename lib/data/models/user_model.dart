import '../../domain/entities/app_user.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.factoryId,
    required this.createdAt,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final String factoryId;
  final DateTime? createdAt;
  final String? photoUrl;

  factory UserModel.fromFirestore(
    String id,
    Map<String, dynamic> data, {
    String? authPhotoUrl,
  }) {
    final storedPhoto = data['photoUrl'] as String?;
    return UserModel(
      id: id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? 'owner',
      factoryId: data['factoryId'] as String? ?? 'default',
      createdAt: (data['createdAt'] as dynamic)?.toDate() as DateTime?,
      photoUrl: _resolvePhotoUrl(storedPhoto, authPhotoUrl),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'factoryId': factoryId,
      if (photoUrl != null) 'photoUrl': photoUrl,
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
    );
  }

  static String? _resolvePhotoUrl(String? stored, String? authPhotoUrl) {
    if (stored != null && stored.isNotEmpty) return stored;
    if (authPhotoUrl != null && authPhotoUrl.isNotEmpty) return authPhotoUrl;
    return null;
  }
}
