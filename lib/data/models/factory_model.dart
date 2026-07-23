import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/bank_account.dart';
import '../../domain/entities/factory_profile.dart';
import '../../domain/entities/factory_profile_sub_models.dart';
import '../../domain/enums/business_profile_enums.dart';
import '../../domain/enums/factory_enums.dart';
import 'bank_account_model.dart';

class FactoryModel {
  const FactoryModel({
    required this.id,
    required this.identity,
    required this.contact,
    this.legal = const LegalInfo(),
    this.bankAccounts = const [],
    this.paymentMethodsAccepted = const [
      'cash',
      'bank_transfer',
      'cheque',
      'easypaisa',
      'jazzcash',
    ],
    this.invoiceSettings = const InvoiceSettingsInfo(),
    this.operational = const OperationalInfo(),
    this.ownership = const OwnershipInfo(),
    this.ownerUserId,
    this.status = FactoryStatus.active,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final IdentityInfo identity;
  final ContactInfo contact;
  final LegalInfo legal;
  final List<BankAccount> bankAccounts;
  final List<String> paymentMethodsAccepted;
  final InvoiceSettingsInfo invoiceSettings;
  final OperationalInfo operational;
  final OwnershipInfo ownership;
  final String? ownerUserId;
  final FactoryStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FactoryModel.fromFirestore(String id, Map<String, dynamic> data) {
    // 1. Identity parsing (with fallback to legacy top-level 'name')
    final rawIdentity = data['identity'] as Map<String, dynamic>? ?? {};
    final businessName = (rawIdentity['businessName'] as String?) ??
        (data['name'] as String?) ??
        '';

    final identity = IdentityInfo(
      businessName: businessName,
      legalName: rawIdentity['legalName'] as String?,
      logoUrl: rawIdentity['logoUrl'] as String?,
      tagline: rawIdentity['tagline'] as String?,
      businessType: rawIdentity['businessType'] as String?,
      establishedYear: (rawIdentity['establishedYear'] as num?)?.toInt(),
    );

    // 2. Contact parsing (with fallback to legacy top-level 'address', 'phone')
    final rawContact = data['contact'] as Map<String, dynamic>? ?? {};
    final address = (rawContact['address'] as String?) ??
        (data['address'] as String?) ??
        '';
    final phone =
        (rawContact['phone'] as String?) ?? (data['phone'] as String?) ?? '';

    final additionalLocationsRaw =
        rawContact['additionalLocations'] as List<dynamic>? ?? [];
    final additionalLocations = additionalLocationsRaw
        .map((loc) {
          if (loc is Map<String, dynamic>) {
            return AdditionalLocation(
              name: loc['name'] as String? ?? '',
              address: loc['address'] as String? ?? '',
              phone: loc['phone'] as String?,
            );
          }
          return null;
        })
        .whereType<AdditionalLocation>()
        .toList();

    final contact = ContactInfo(
      address: address,
      city: rawContact['city'] as String? ?? '',
      province: rawContact['province'] as String? ?? '',
      phone: phone,
      phoneAlt: rawContact['phoneAlt'] as String?,
      whatsapp: rawContact['whatsapp'] as String?,
      email: rawContact['email'] as String?,
      website: rawContact['website'] as String?,
      googleMapsLink: rawContact['googleMapsLink'] as String?,
      additionalLocations: additionalLocations,
    );

    // 3. Legal parsing
    final rawLegal = data['legal'] as Map<String, dynamic>? ?? {};
    final legal = LegalInfo(
      ntn: rawLegal['ntn'] as String?,
      strn: rawLegal['strn'] as String?,
      cnic: rawLegal['cnic'] as String?,
      businessRegNo: rawLegal['businessRegNo'] as String?,
      filerStatus: FilerStatus.fromString(rawLegal['filerStatus'] as String?),
    );

    // 4. Bank Accounts
    final rawBanks = data['bankAccounts'] as List<dynamic>? ?? [];
    final bankAccounts = rawBanks
        .map((b) {
          if (b is Map<String, dynamic>) {
            return BankAccountModel.fromMap(b);
          }
          return null;
        })
        .whereType<BankAccount>()
        .toList();

    // 5. Payment Methods Accepted
    final rawPayments = data['paymentMethodsAccepted'] as List<dynamic>?;
    final paymentMethodsAccepted = rawPayments != null
        ? rawPayments.map((e) => e.toString()).toList()
        : const ['cash', 'bank_transfer', 'cheque', 'easypaisa', 'jazzcash'];

    // 6. Invoice Settings
    final rawInvoice = data['invoiceSettings'] as Map<String, dynamic>? ?? {};
    final invoiceSettings = InvoiceSettingsInfo(
      prefixSales: rawInvoice['prefixSales'] as String? ?? 'INV',
      prefixJobWork: rawInvoice['prefixJobWork'] as String? ?? 'JW-INV',
      startingNumber: (rawInvoice['startingNumber'] as num?)?.toInt() ?? 1001,
      defaultPaymentTerms:
          rawInvoice['defaultPaymentTerms'] as String? ?? 'Net 30',
      termsAndConditions: rawInvoice['termsAndConditions'] as String?,
      footerNote: rawInvoice['footerNote'] as String?,
      signatureImageUrl: rawInvoice['signatureImageUrl'] as String?,
      stampImageUrl: rawInvoice['stampImageUrl'] as String?,
      currency: rawInvoice['currency'] as String? ?? 'PKR',
    );

    // 7. Operational
    final rawOp = data['operational'] as Map<String, dynamic>? ?? {};
    final rawWorkingDays = rawOp['workingDays'] as List<dynamic>?;
    final workingDays = rawWorkingDays != null
        ? rawWorkingDays.map((e) => (e as num).toInt()).toList()
        : const [1, 2, 3, 4, 5, 6];

    final operational = OperationalInfo(
      workingHours: rawOp['workingHours'] as String?,
      workingDays: workingDays,
      fiscalYearStartMonth:
          (rawOp['fiscalYearStartMonth'] as num?)?.toInt() ?? 7,
      timezone: rawOp['timezone'] as String? ?? 'Asia/Karachi',
      defaultLanguage: rawOp['defaultLanguage'] as String? ?? 'en',
    );

    // 8. Ownership (with fallback to legacy top-level 'ownerName')
    final rawOwn = data['ownership'] as Map<String, dynamic>? ?? {};
    final ownerName = (rawOwn['ownerName'] as String?) ??
        (data['ownerName'] as String?);

    final rawSignatories = rawOwn['authorizedSignatories'] as List<dynamic>? ?? [];
    final authorizedSignatories = rawSignatories
        .map((s) {
          if (s is Map<String, dynamic>) {
            return AuthorizedSignatory(
              name: s['name'] as String? ?? '',
              role: s['role'] as String? ?? '',
            );
          }
          return null;
        })
        .whereType<AuthorizedSignatory>()
        .toList();

    final ownership = OwnershipInfo(
      ownerName: ownerName,
      ownerPhone: rawOwn['ownerPhone'] as String?,
      ownerEmail: rawOwn['ownerEmail'] as String?,
      authorizedSignatories: authorizedSignatories,
    );

    return FactoryModel(
      id: id,
      identity: identity,
      contact: contact,
      legal: legal,
      bankAccounts: bankAccounts,
      paymentMethodsAccepted: paymentMethodsAccepted,
      invoiceSettings: invoiceSettings,
      operational: operational,
      ownership: ownership,
      ownerUserId: data['ownerUserId'] as String?,
      status: FactoryStatus.fromString(data['status'] as String?),
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  factory FactoryModel.fromEntity(FactoryProfile profile) {
    return FactoryModel(
      id: profile.id,
      identity: profile.identity,
      contact: profile.contact,
      legal: profile.legal,
      bankAccounts: profile.bankAccounts,
      paymentMethodsAccepted: profile.paymentMethodsAccepted,
      invoiceSettings: profile.invoiceSettings,
      operational: profile.operational,
      ownership: profile.ownership,
      ownerUserId: profile.ownerUserId,
      status: profile.status,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  factory FactoryModel.legacy({
    required String id,
    required String name,
    String? address,
    String? phone,
    String? ownerName,
    String? ownerUserId,
    FactoryStatus status = FactoryStatus.active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FactoryModel.fromEntity(
      FactoryProfile.legacy(
        id: id,
        name: name,
        address: address,
        phone: phone,
        ownerName: ownerName,
        ownerUserId: ownerUserId,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      // Legacy root fields maintained for direct database query compatibility
      'name': identity.businessName,
      if (contact.address.isNotEmpty) 'address': contact.address,
      if (contact.phone.isNotEmpty) 'phone': contact.phone,
      if (ownership.ownerName != null && ownership.ownerName!.isNotEmpty)
        'ownerName': ownership.ownerName,
      if (ownerUserId != null && ownerUserId!.isNotEmpty)
        'ownerUserId': ownerUserId,
      'status': status.firestoreValue,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),

      // Structured sub-objects
      'identity': {
        'businessName': identity.businessName,
        'legalName': identity.legalName,
        'logoUrl': identity.logoUrl,
        'tagline': identity.tagline,
        'businessType': identity.businessType,
        'establishedYear': identity.establishedYear,
      },
      'contact': {
        'address': contact.address,
        'city': contact.city,
        'province': contact.province,
        'phone': contact.phone,
        'phoneAlt': contact.phoneAlt,
        'whatsapp': contact.whatsapp,
        'email': contact.email,
        'website': contact.website,
        'googleMapsLink': contact.googleMapsLink,
        'additionalLocations': contact.additionalLocations
            .map((loc) => {
                  'name': loc.name,
                  'address': loc.address,
                  'phone': loc.phone,
                })
            .toList(),
      },
      'legal': {
        'ntn': legal.ntn,
        'strn': legal.strn,
        'cnic': legal.cnic,
        'businessRegNo': legal.businessRegNo,
        'filerStatus': legal.filerStatus.firestoreValue,
      },
      'bankAccounts': bankAccounts
          .map((b) => BankAccountModel.fromEntity(b).toMap())
          .toList(),
      'paymentMethodsAccepted': paymentMethodsAccepted,
      'invoiceSettings': {
        'prefixSales': invoiceSettings.prefixSales,
        'prefixJobWork': invoiceSettings.prefixJobWork,
        'startingNumber': invoiceSettings.startingNumber,
        'defaultPaymentTerms': invoiceSettings.defaultPaymentTerms,
        'termsAndConditions': invoiceSettings.termsAndConditions,
        'footerNote': invoiceSettings.footerNote,
        'signatureImageUrl': invoiceSettings.signatureImageUrl,
        'stampImageUrl': invoiceSettings.stampImageUrl,
        'currency': invoiceSettings.currency,
      },
      'operational': {
        'workingHours': operational.workingHours,
        'workingDays': operational.workingDays,
        'fiscalYearStartMonth': operational.fiscalYearStartMonth,
        'timezone': operational.timezone,
        'defaultLanguage': operational.defaultLanguage,
      },
      'ownership': {
        'ownerName': ownership.ownerName,
        'ownerPhone': ownership.ownerPhone,
        'ownerEmail': ownership.ownerEmail,
        'authorizedSignatories': ownership.authorizedSignatories
            .map((s) => {'name': s.name, 'role': s.role})
            .toList(),
      },
    };
  }

  FactoryProfile toEntity() {
    return FactoryProfile(
      id: id,
      identity: identity,
      contact: contact,
      legal: legal,
      bankAccounts: bankAccounts,
      paymentMethodsAccepted: paymentMethodsAccepted,
      invoiceSettings: invoiceSettings,
      operational: operational,
      ownership: ownership,
      ownerUserId: ownerUserId,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory FactoryModel.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return FactoryModel.fromFirestore(id, map);
  }

  Map<String, dynamic> toMap() => toFirestore();

  factory FactoryModel.fromJson(String source, {String id = ''}) =>
      FactoryModel.fromMap(json.decode(source) as Map<String, dynamic>, id: id);

  String toJson() => json.encode(toMap());

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

/// Convenience alias requested by specs
typedef FactoryProfileModel = FactoryModel;
