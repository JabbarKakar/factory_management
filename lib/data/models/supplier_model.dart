import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/supplier.dart';
import '../../domain/enums/customer_enums.dart';
import '../../domain/enums/supplier_enums.dart';

class SupplierModel {
  const SupplierModel({
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

  factory SupplierModel.fromFirestore(String id, Map<String, dynamic> data) {
    return SupplierModel(
      id: id,
      supplierNumber: data['supplierNumber'] as String? ?? '',
      factoryId: data['factoryId'] as String? ?? 'default',
      name: data['name'] as String? ?? '',
      supplierType: SupplierType.fromString(data['supplierType'] as String?),
      contactPersonName: data['contactPersonName'] as String?,
      phone: data['phone'] as String? ?? '',
      phoneSecondary: data['phoneSecondary'] as String?,
      city: data['city'] as String?,
      address: data['address'] as String?,
      cnicNtn: data['cnicNtn'] as String?,
      paymentTerms: PaymentTerms.fromString(data['paymentTerms'] as String?),
      materialsSupplied: data['materialsSupplied'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'supplierNumber': supplierNumber,
      'factoryId': factoryId,
      'name': name,
      'supplierType': supplierType.firestoreValue,
      if (contactPersonName != null && contactPersonName!.isNotEmpty)
        'contactPersonName': contactPersonName,
      'phone': phone,
      if (phoneSecondary != null && phoneSecondary!.isNotEmpty)
        'phoneSecondary': phoneSecondary,
      if (city != null && city!.isNotEmpty) 'city': city,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (cnicNtn != null && cnicNtn!.isNotEmpty) 'cnicNtn': cnicNtn,
      'paymentTerms': paymentTerms.name,
      if (materialsSupplied != null && materialsSupplied!.isNotEmpty)
        'materialsSupplied': materialsSupplied,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Supplier toEntity() => Supplier(
        id: id,
        supplierNumber: supplierNumber,
        factoryId: factoryId,
        name: name,
        supplierType: supplierType,
        contactPersonName: contactPersonName,
        phone: phone,
        phoneSecondary: phoneSecondary,
        city: city,
        address: address,
        cnicNtn: cnicNtn,
        paymentTerms: paymentTerms,
        materialsSupplied: materialsSupplied,
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory SupplierModel.fromEntity(Supplier supplier) => SupplierModel(
        id: supplier.id,
        supplierNumber: supplier.supplierNumber,
        factoryId: supplier.factoryId,
        name: supplier.name,
        supplierType: supplier.supplierType,
        contactPersonName: supplier.contactPersonName,
        phone: supplier.phone,
        phoneSecondary: supplier.phoneSecondary,
        city: supplier.city,
        address: supplier.address,
        cnicNtn: supplier.cnicNtn,
        paymentTerms: supplier.paymentTerms,
        materialsSupplied: supplier.materialsSupplied,
        notes: supplier.notes,
        createdAt: supplier.createdAt,
        updatedAt: supplier.updatedAt,
      );
}
