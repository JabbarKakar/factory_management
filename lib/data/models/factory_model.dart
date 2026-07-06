import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/factory_profile.dart';
import '../../domain/enums/factory_enums.dart';

class FactoryModel {
  const FactoryModel({
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

  factory FactoryModel.fromFirestore(String id, Map<String, dynamic> data) {
    return FactoryModel(
      id: id,
      name: data['name'] as String? ?? '',
      address: data['address'] as String?,
      phone: data['phone'] as String?,
      ownerName: data['ownerName'] as String?,
      ownerUserId: data['ownerUserId'] as String?,
      status: FactoryStatus.fromString(data['status'] as String?),
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  factory FactoryModel.fromEntity(FactoryProfile profile) {
    return FactoryModel(
      id: profile.id,
      name: profile.name,
      address: profile.address,
      phone: profile.phone,
      ownerName: profile.ownerName,
      ownerUserId: profile.ownerUserId,
      status: profile.status,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'name': name,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (ownerName != null && ownerName!.isNotEmpty) 'ownerName': ownerName,
      if (ownerUserId != null && ownerUserId!.isNotEmpty)
        'ownerUserId': ownerUserId,
      'status': status.firestoreValue,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  FactoryProfile toEntity() {
    return FactoryProfile(
      id: id,
      name: name,
      address: address,
      phone: phone,
      ownerName: ownerName,
      ownerUserId: ownerUserId,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
