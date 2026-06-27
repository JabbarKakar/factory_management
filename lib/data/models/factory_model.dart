import '../../domain/entities/factory_profile.dart';

class FactoryModel {
  const FactoryModel({
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

  factory FactoryModel.fromFirestore(String id, Map<String, dynamic> data) {
    return FactoryModel(
      id: id,
      name: data['name'] as String? ?? '',
      address: data['address'] as String?,
      phone: data['phone'] as String?,
      ownerName: data['ownerName'] as String?,
    );
  }

  FactoryProfile toEntity() {
    return FactoryProfile(
      id: id,
      name: name,
      address: address,
      phone: phone,
      ownerName: ownerName,
    );
  }
}
