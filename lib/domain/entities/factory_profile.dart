import 'package:equatable/equatable.dart';

class FactoryProfile extends Equatable {
  const FactoryProfile({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.ownerName,
  });

  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? ownerName;

  @override
  List<Object?> get props => [id, name, address, phone, ownerName];
}
