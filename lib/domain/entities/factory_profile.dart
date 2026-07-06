import 'package:equatable/equatable.dart';

import '../enums/factory_enums.dart';

class FactoryProfile extends Equatable {
  const FactoryProfile({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.ownerName,
    this.ownerUserId,
    this.status = FactoryStatus.active,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? ownerName;
  final String? ownerUserId;
  final FactoryStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FactoryProfile copyWith({
    String? name,
    String? address,
    String? phone,
    String? ownerName,
    String? ownerUserId,
    FactoryStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FactoryProfile(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      ownerName: ownerName ?? this.ownerName,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        phone,
        ownerName,
        ownerUserId,
        status,
        createdAt,
        updatedAt,
      ];
}
