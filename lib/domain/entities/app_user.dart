import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.factoryId,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final String factoryId;
  final String? photoUrl;

  @override
  List<Object?> get props => [id, email, name, role, factoryId, photoUrl];
}
