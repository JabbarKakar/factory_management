import 'package:equatable/equatable.dart';

import '../enums/customer_enums.dart';
import '../enums/supplier_enums.dart';

class Supplier extends Equatable {
  const Supplier({
    required this.id,
    required this.supplierNumber,
    required this.factoryId,
    required this.name,
    required this.supplierType,
    required this.phone,
    required this.paymentTerms,
    required this.createdAt,
    this.contactPersonName,
    this.phoneSecondary,
    this.city,
    this.address,
    this.cnicNtn,
    this.materialsSupplied,
    this.notes,
    this.updatedAt,
  });

  final String id;
  final String supplierNumber;
  final String factoryId;
  final String name;
  final SupplierType supplierType;
  final String? contactPersonName;
  final String phone;
  final String? phoneSecondary;
  final String? city;
  final String? address;
  final String? cnicNtn;
  final PaymentTerms paymentTerms;
  final String? materialsSupplied;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  String get displayLocation {
    final value = city?.trim();
    if (value != null && value.isNotEmpty) return value;
    return '—';
  }

  Supplier copyWith({
    String? id,
    String? supplierNumber,
    String? factoryId,
    String? name,
    SupplierType? supplierType,
    String? contactPersonName,
    String? phone,
    String? phoneSecondary,
    String? city,
    String? address,
    String? cnicNtn,
    PaymentTerms? paymentTerms,
    String? materialsSupplied,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      supplierNumber: supplierNumber ?? this.supplierNumber,
      factoryId: factoryId ?? this.factoryId,
      name: name ?? this.name,
      supplierType: supplierType ?? this.supplierType,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      phone: phone ?? this.phone,
      phoneSecondary: phoneSecondary ?? this.phoneSecondary,
      city: city ?? this.city,
      address: address ?? this.address,
      cnicNtn: cnicNtn ?? this.cnicNtn,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      materialsSupplied: materialsSupplied ?? this.materialsSupplied,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        supplierNumber,
        factoryId,
        name,
        supplierType,
        contactPersonName,
        phone,
        phoneSecondary,
        city,
        address,
        cnicNtn,
        paymentTerms,
        materialsSupplied,
        notes,
        createdAt,
        updatedAt,
      ];
}
