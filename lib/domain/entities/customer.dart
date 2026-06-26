import 'package:equatable/equatable.dart';

import '../enums/customer_enums.dart';

class Customer extends Equatable {
  const Customer({
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

  String get displayLocation {
    final city = billingCity?.trim();
    if (city != null && city.isNotEmpty) return city;
    return '—';
  }

  CustomerBalanceStatus get balanceStatus {
    if (balance <= 0) return CustomerBalanceStatus.paidUp;

    final due = nextDueDate;
    if (due == null) return CustomerBalanceStatus.outstanding;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final diff = dueDay.difference(today).inDays;

    if (diff < 0) return CustomerBalanceStatus.overdue;
    if (diff == 0) return CustomerBalanceStatus.dueToday;
    if (diff <= 7) return CustomerBalanceStatus.dueSoon;
    return CustomerBalanceStatus.outstanding;
  }

  Customer copyWith({
    String? id,
    String? factoryId,
    CustomerType? customerType,
    String? name,
    String? contactPersonName,
    String? phone,
    String? phoneSecondary,
    String? whatsApp,
    String? email,
    String? billingStreet,
    String? billingCity,
    String? billingProvince,
    String? shippingStreet,
    String? shippingCity,
    String? shippingProvince,
    bool? useSameShippingAddress,
    String? cnicNtn,
    CustomerCategory? category,
    CustomerServiceType? serviceType,
    String? otherServiceDescription,
    double? creditLimit,
    PaymentTerms? paymentTerms,
    String? referredBy,
    String? notes,
    double? balance,
    double? openingBalance,
    DateTime? nextDueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      factoryId: factoryId ?? this.factoryId,
      customerType: customerType ?? this.customerType,
      name: name ?? this.name,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      phone: phone ?? this.phone,
      phoneSecondary: phoneSecondary ?? this.phoneSecondary,
      whatsApp: whatsApp ?? this.whatsApp,
      email: email ?? this.email,
      billingStreet: billingStreet ?? this.billingStreet,
      billingCity: billingCity ?? this.billingCity,
      billingProvince: billingProvince ?? this.billingProvince,
      shippingStreet: shippingStreet ?? this.shippingStreet,
      shippingCity: shippingCity ?? this.shippingCity,
      shippingProvince: shippingProvince ?? this.shippingProvince,
      useSameShippingAddress:
          useSameShippingAddress ?? this.useSameShippingAddress,
      cnicNtn: cnicNtn ?? this.cnicNtn,
      category: category ?? this.category,
      serviceType: serviceType ?? this.serviceType,
      otherServiceDescription:
          otherServiceDescription ?? this.otherServiceDescription,
      creditLimit: creditLimit ?? this.creditLimit,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      referredBy: referredBy ?? this.referredBy,
      notes: notes ?? this.notes,
      balance: balance ?? this.balance,
      openingBalance: openingBalance ?? this.openingBalance,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        factoryId,
        customerType,
        name,
        contactPersonName,
        phone,
        phoneSecondary,
        whatsApp,
        email,
        billingStreet,
        billingCity,
        billingProvince,
        shippingStreet,
        shippingCity,
        shippingProvince,
        useSameShippingAddress,
        cnicNtn,
        category,
        serviceType,
        otherServiceDescription,
        creditLimit,
        paymentTerms,
        referredBy,
        notes,
        balance,
        openingBalance,
        nextDueDate,
        createdAt,
        updatedAt,
      ];
}
