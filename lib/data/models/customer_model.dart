import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/customer.dart';
import '../../domain/enums/customer_enums.dart';

class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.factoryId,
    required this.customerType,
    required this.name,
    required this.phone,
    required this.serviceType,
    required this.category,
    required this.paymentTerms,
    required this.creditLimit,
    required this.balance,
    required this.openingBalance,
    required this.createdAt,
    this.contactPersonName,
    this.phoneSecondary,
    this.whatsApp,
    this.email,
    this.billingStreet,
    this.billingCity,
    this.billingProvince,
    this.shippingStreet,
    this.shippingCity,
    this.shippingProvince,
    this.useSameShippingAddress = true,
    this.cnicNtn,
    this.otherServiceDescription,
    this.referredBy,
    this.notes,
    this.nextDueDate,
    this.updatedAt,
  });

  final String id;
  final String factoryId;
  final CustomerType customerType;
  final String name;
  final String? contactPersonName;
  final String phone;
  final String? phoneSecondary;
  final String? whatsApp;
  final String? email;
  final String? billingStreet;
  final String? billingCity;
  final String? billingProvince;
  final String? shippingStreet;
  final String? shippingCity;
  final String? shippingProvince;
  final bool useSameShippingAddress;
  final String? cnicNtn;
  final CustomerCategory category;
  final CustomerServiceType serviceType;
  final String? otherServiceDescription;
  final double creditLimit;
  final PaymentTerms paymentTerms;
  final String? referredBy;
  final String? notes;
  final double balance;
  final double openingBalance;
  final DateTime? nextDueDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory CustomerModel.fromFirestore(String id, Map<String, dynamic> data) {
    return CustomerModel(
      id: id,
      factoryId: data['factoryId'] as String? ?? 'default',
      customerType: CustomerType.fromString(data['customerType'] as String?),
      name: data['name'] as String? ?? '',
      contactPersonName: data['contactPersonName'] as String?,
      phone: data['phone'] as String? ?? '',
      phoneSecondary: data['phoneSecondary'] as String?,
      whatsApp: data['whatsApp'] as String?,
      email: data['email'] as String?,
      billingStreet: data['billingStreet'] as String?,
      billingCity: data['billingCity'] as String?,
      billingProvince: data['billingProvince'] as String?,
      shippingStreet: data['shippingStreet'] as String?,
      shippingCity: data['shippingCity'] as String?,
      shippingProvince: data['shippingProvince'] as String?,
      useSameShippingAddress: data['useSameShippingAddress'] as bool? ?? true,
      cnicNtn: data['cnicNtn'] as String?,
      category: CustomerCategory.fromString(data['category'] as String?),
      serviceType: CustomerServiceType.fromCode(
        (data['serviceType'] as String?) ??
            (data['serviceTypes'] as List?)?.first as String?,
      ),
      otherServiceDescription: data['otherServiceDescription'] as String?,
      creditLimit: (data['creditLimit'] as num?)?.toDouble() ?? 0,
      paymentTerms: PaymentTerms.fromString(data['paymentTerms'] as String?),
      referredBy: data['referredBy'] as String?,
      notes: data['notes'] as String?,
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      openingBalance: (data['openingBalance'] as num?)?.toDouble() ?? 0,
      nextDueDate: (data['nextDueDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'factoryId': factoryId,
      'customerType': customerType.firestoreValue,
      'name': name,
      if (contactPersonName != null) 'contactPersonName': contactPersonName,
      'phone': phone,
      if (phoneSecondary != null) 'phoneSecondary': phoneSecondary,
      if (whatsApp != null) 'whatsApp': whatsApp,
      if (email != null) 'email': email,
      if (billingStreet != null) 'billingStreet': billingStreet,
      if (billingCity != null) 'billingCity': billingCity,
      if (billingProvince != null) 'billingProvince': billingProvince,
      if (shippingStreet != null) 'shippingStreet': shippingStreet,
      if (shippingCity != null) 'shippingCity': shippingCity,
      if (shippingProvince != null) 'shippingProvince': shippingProvince,
      'useSameShippingAddress': useSameShippingAddress,
      if (cnicNtn != null) 'cnicNtn': cnicNtn,
      'category': category.name,
      'serviceType': serviceType.code,
      'serviceTypes': [serviceType.code],
      if (otherServiceDescription != null)
        'otherServiceDescription': otherServiceDescription,
      'creditLimit': creditLimit,
      'paymentTerms': paymentTerms.name,
      if (referredBy != null) 'referredBy': referredBy,
      if (notes != null) 'notes': notes,
      'balance': balance,
      'openingBalance': openingBalance,
      if (nextDueDate != null) 'nextDueDate': Timestamp.fromDate(nextDueDate!),
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Customer toEntity() {
    return Customer(
      id: id,
      factoryId: factoryId,
      customerType: customerType,
      name: name,
      contactPersonName: contactPersonName,
      phone: phone,
      phoneSecondary: phoneSecondary,
      whatsApp: whatsApp,
      email: email,
      billingStreet: billingStreet,
      billingCity: billingCity,
      billingProvince: billingProvince,
      shippingStreet: shippingStreet,
      shippingCity: shippingCity,
      shippingProvince: shippingProvince,
      useSameShippingAddress: useSameShippingAddress,
      cnicNtn: cnicNtn,
      category: category,
      serviceType: serviceType,
      otherServiceDescription: otherServiceDescription,
      creditLimit: creditLimit,
      paymentTerms: paymentTerms,
      referredBy: referredBy,
      notes: notes,
      balance: balance,
      openingBalance: openingBalance,
      nextDueDate: nextDueDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory CustomerModel.fromEntity(Customer customer) {
    return CustomerModel(
      id: customer.id,
      factoryId: customer.factoryId,
      customerType: customer.customerType,
      name: customer.name,
      contactPersonName: customer.contactPersonName,
      phone: customer.phone,
      phoneSecondary: customer.phoneSecondary,
      whatsApp: customer.whatsApp,
      email: customer.email,
      billingStreet: customer.billingStreet,
      billingCity: customer.billingCity,
      billingProvince: customer.billingProvince,
      shippingStreet: customer.shippingStreet,
      shippingCity: customer.shippingCity,
      shippingProvince: customer.shippingProvince,
      useSameShippingAddress: customer.useSameShippingAddress,
      cnicNtn: customer.cnicNtn,
      category: customer.category,
      serviceType: customer.serviceType,
      otherServiceDescription: customer.otherServiceDescription,
      creditLimit: customer.creditLimit,
      paymentTerms: customer.paymentTerms,
      referredBy: customer.referredBy,
      notes: customer.notes,
      balance: customer.balance,
      openingBalance: customer.openingBalance,
      nextDueDate: customer.nextDueDate,
      createdAt: customer.createdAt,
      updatedAt: customer.updatedAt,
    );
  }
}
