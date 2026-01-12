import 'package:cloud_firestore/cloud_firestore.dart';

class FactoryModel {
  final String id;
  final String ownerId;
  final String? logoUrl;
  final String name;
  final String type;
  final String factoryCode;
  final String status;
  
  // Address
  final String street;
  final String city;
  final String province;
  final String country;
  final GeoPoint? gpsCoordinates;

  // Contact
  final String contactPhone;
  final String email;
  final String emergencyContact;

  // Business Info
  final String businessType;
  final String workingDays;
  final String workingHours;
  final String shiftSystem;
  final String defaultShift;
  final String currency;
  final String salaryType;
  final String paymentCycle;
  
  // Production
  final String productionUnit;
  final String qualityLevel;
  
  final DateTime createdAt;

  FactoryModel({
    required this.id,
    required this.ownerId,
    this.logoUrl,
    required this.name,
    required this.type,
    required this.factoryCode,
    required this.status,
    required this.street,
    required this.city,
    required this.province,
    required this.country,
    this.gpsCoordinates,
    required this.contactPhone,
    required this.email,
    required this.emergencyContact,
    required this.businessType,
    required this.workingDays,
    required this.workingHours,
    required this.shiftSystem,
    required this.defaultShift,
    required this.currency,
    required this.salaryType,
    required this.paymentCycle,
    required this.productionUnit,
    required this.qualityLevel,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'logoUrl': logoUrl,
      'name': name,
      'type': type,
      'factoryCode': factoryCode,
      'status': status,
      'street': street,
      'city': city,
      'province': province,
      'country': country,
      'gpsCoordinates': gpsCoordinates,
      'contactPhone': contactPhone,
      'email': email,
      'emergencyContact': emergencyContact,
      'businessType': businessType,
      'workingDays': workingDays,
      'workingHours': workingHours,
      'shiftSystem': shiftSystem,
      'defaultShift': defaultShift,
      'currency': currency,
      'salaryType': salaryType,
      'paymentCycle': paymentCycle,
      'productionUnit': productionUnit,
      'qualityLevel': qualityLevel,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FactoryModel.fromMap(Map<String, dynamic> map) {
    return FactoryModel(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      logoUrl: map['logoUrl'],
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      factoryCode: map['factoryCode'] ?? '',
      status: map['status'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      province: map['province'] ?? '',
      country: map['country'] ?? '',
      gpsCoordinates: map['gpsCoordinates'] as GeoPoint?,
      contactPhone: map['contactPhone'] ?? '',
      email: map['email'] ?? '',
      emergencyContact: map['emergencyContact'] ?? '',
      businessType: map['businessType'] ?? '',
      workingDays: map['workingDays'] ?? '',
      workingHours: map['workingHours'] ?? '',
      shiftSystem: map['shiftSystem'] ?? '',
      defaultShift: map['defaultShift'] ?? '',
      currency: map['currency'] ?? '',
      salaryType: map['salaryType'] ?? '',
      paymentCycle: map['paymentCycle'] ?? '',
      productionUnit: map['productionUnit'] ?? '',
      qualityLevel: map['qualityLevel'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
