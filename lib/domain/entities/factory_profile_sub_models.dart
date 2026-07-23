import 'package:equatable/equatable.dart';
import '../enums/business_profile_enums.dart';

class IdentityInfo extends Equatable {
  const IdentityInfo({
    required this.businessName,
    this.legalName,
    this.logoUrl,
    this.tagline,
    this.businessType,
    this.establishedYear,
  });

  final String businessName;
  final String? legalName;
  final String? logoUrl;
  final String? tagline;
  final String? businessType;
  final int? establishedYear;

  IdentityInfo copyWith({
    String? businessName,
    String? legalName,
    String? logoUrl,
    String? tagline,
    String? businessType,
    int? establishedYear,
  }) {
    return IdentityInfo(
      businessName: businessName ?? this.businessName,
      legalName: legalName ?? this.legalName,
      logoUrl: logoUrl ?? this.logoUrl,
      tagline: tagline ?? this.tagline,
      businessType: businessType ?? this.businessType,
      establishedYear: establishedYear ?? this.establishedYear,
    );
  }

  @override
  List<Object?> get props => [
        businessName,
        legalName,
        logoUrl,
        tagline,
        businessType,
        establishedYear,
      ];
}

class AdditionalLocation extends Equatable {
  const AdditionalLocation({
    required this.name,
    required this.address,
    this.phone,
  });

  final String name;
  final String address;
  final String? phone;

  AdditionalLocation copyWith({
    String? name,
    String? address,
    String? phone,
  }) {
    return AdditionalLocation(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
    );
  }

  @override
  List<Object?> get props => [name, address, phone];
}

class ContactInfo extends Equatable {
  const ContactInfo({
    required this.address,
    this.city = '',
    this.province = '',
    required this.phone,
    this.phoneAlt,
    this.whatsapp,
    this.email,
    this.website,
    this.googleMapsLink,
    this.additionalLocations = const [],
  });

  final String address;
  final String city;
  final String province;
  final String phone;
  final String? phoneAlt;
  final String? whatsapp;
  final String? email;
  final String? website;
  final String? googleMapsLink;
  final List<AdditionalLocation> additionalLocations;

  ContactInfo copyWith({
    String? address,
    String? city,
    String? province,
    String? phone,
    String? phoneAlt,
    String? whatsapp,
    String? email,
    String? website,
    String? googleMapsLink,
    List<AdditionalLocation>? additionalLocations,
  }) {
    return ContactInfo(
      address: address ?? this.address,
      city: city ?? this.city,
      province: province ?? this.province,
      phone: phone ?? this.phone,
      phoneAlt: phoneAlt ?? this.phoneAlt,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      website: website ?? this.website,
      googleMapsLink: googleMapsLink ?? this.googleMapsLink,
      additionalLocations: additionalLocations ?? this.additionalLocations,
    );
  }

  @override
  List<Object?> get props => [
        address,
        city,
        province,
        phone,
        phoneAlt,
        whatsapp,
        email,
        website,
        googleMapsLink,
        additionalLocations,
      ];
}

class LegalInfo extends Equatable {
  const LegalInfo({
    this.ntn,
    this.strn,
    this.cnic,
    this.businessRegNo,
    this.filerStatus = FilerStatus.unknown,
  });

  final String? ntn;
  final String? strn;
  final String? cnic;
  final String? businessRegNo;
  final FilerStatus filerStatus;

  LegalInfo copyWith({
    String? ntn,
    String? strn,
    String? cnic,
    String? businessRegNo,
    FilerStatus? filerStatus,
  }) {
    return LegalInfo(
      ntn: ntn ?? this.ntn,
      strn: strn ?? this.strn,
      cnic: cnic ?? this.cnic,
      businessRegNo: businessRegNo ?? this.businessRegNo,
      filerStatus: filerStatus ?? this.filerStatus,
    );
  }

  @override
  List<Object?> get props => [ntn, strn, cnic, businessRegNo, filerStatus];
}

class InvoiceSettingsInfo extends Equatable {
  const InvoiceSettingsInfo({
    this.prefixSales = 'INV',
    this.prefixJobWork = 'JW-INV',
    this.startingNumber = 1001,
    this.defaultPaymentTerms = 'Net 30',
    this.termsAndConditions,
    this.footerNote,
    this.signatureImageUrl,
    this.stampImageUrl,
    this.currency = 'PKR',
  });

  final String prefixSales;
  final String prefixJobWork;
  final int startingNumber;
  final String defaultPaymentTerms;
  final String? termsAndConditions;
  final String? footerNote;
  final String? signatureImageUrl;
  final String? stampImageUrl;
  final String currency;

  InvoiceSettingsInfo copyWith({
    String? prefixSales,
    String? prefixJobWork,
    int? startingNumber,
    String? defaultPaymentTerms,
    String? termsAndConditions,
    String? footerNote,
    String? signatureImageUrl,
    String? stampImageUrl,
    String? currency,
  }) {
    return InvoiceSettingsInfo(
      prefixSales: prefixSales ?? this.prefixSales,
      prefixJobWork: prefixJobWork ?? this.prefixJobWork,
      startingNumber: startingNumber ?? this.startingNumber,
      defaultPaymentTerms: defaultPaymentTerms ?? this.defaultPaymentTerms,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      footerNote: footerNote ?? this.footerNote,
      signatureImageUrl: signatureImageUrl ?? this.signatureImageUrl,
      stampImageUrl: stampImageUrl ?? this.stampImageUrl,
      currency: currency ?? this.currency,
    );
  }

  @override
  List<Object?> get props => [
        prefixSales,
        prefixJobWork,
        startingNumber,
        defaultPaymentTerms,
        termsAndConditions,
        footerNote,
        signatureImageUrl,
        stampImageUrl,
        currency,
      ];
}

class OperationalInfo extends Equatable {
  const OperationalInfo({
    this.workingHours,
    this.workingDays = const [1, 2, 3, 4, 5, 6], // Monday to Saturday default
    this.fiscalYearStartMonth = 7, // July default in Pakistan
    this.timezone = 'Asia/Karachi',
    this.defaultLanguage = 'en',
  });

  final String? workingHours;
  final List<int> workingDays;
  final int fiscalYearStartMonth;
  final String timezone;
  final String defaultLanguage;

  OperationalInfo copyWith({
    String? workingHours,
    List<int>? workingDays,
    int? fiscalYearStartMonth,
    String? timezone,
    String? defaultLanguage,
  }) {
    return OperationalInfo(
      workingHours: workingHours ?? this.workingHours,
      workingDays: workingDays ?? this.workingDays,
      fiscalYearStartMonth: fiscalYearStartMonth ?? this.fiscalYearStartMonth,
      timezone: timezone ?? this.timezone,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
    );
  }

  @override
  List<Object?> get props => [
        workingHours,
        workingDays,
        fiscalYearStartMonth,
        timezone,
        defaultLanguage,
      ];
}

class AuthorizedSignatory extends Equatable {
  const AuthorizedSignatory({
    required this.name,
    required this.role,
  });

  final String name;
  final String role;

  AuthorizedSignatory copyWith({
    String? name,
    String? role,
  }) {
    return AuthorizedSignatory(
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [name, role];
}

class OwnershipInfo extends Equatable {
  const OwnershipInfo({
    this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
    this.authorizedSignatories = const [],
  });

  final String? ownerName;
  final String? ownerPhone;
  final String? ownerEmail;
  final List<AuthorizedSignatory> authorizedSignatories;

  OwnershipInfo copyWith({
    String? ownerName,
    String? ownerPhone,
    String? ownerEmail,
    List<AuthorizedSignatory>? authorizedSignatories,
  }) {
    return OwnershipInfo(
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      authorizedSignatories:
          authorizedSignatories ?? this.authorizedSignatories,
    );
  }

  @override
  List<Object?> get props => [
        ownerName,
        ownerPhone,
        ownerEmail,
        authorizedSignatories,
      ];
}
