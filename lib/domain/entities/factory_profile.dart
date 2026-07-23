import 'package:equatable/equatable.dart';

import '../enums/factory_enums.dart';
import 'bank_account.dart';
import 'factory_profile_sub_models.dart';

class FactoryProfile extends Equatable {
  const FactoryProfile({
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

  // Backward-compatibility getters
  String get name => identity.businessName;
  String? get address => contact.address.isEmpty ? null : contact.address;
  String? get phone => contact.phone.isEmpty ? null : contact.phone;
  String? get ownerName => ownership.ownerName;

  /// Legacy constructor for creating FactoryProfile from simple flat properties
  factory FactoryProfile.legacy({
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
    return FactoryProfile(
      id: id,
      identity: IdentityInfo(businessName: name),
      contact: ContactInfo(
        address: address ?? '',
        phone: phone ?? '',
      ),
      ownership: OwnershipInfo(ownerName: ownerName),
      ownerUserId: ownerUserId,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  FactoryProfile copyWith({
    String? id,
    IdentityInfo? identity,
    ContactInfo? contact,
    LegalInfo? legal,
    List<BankAccount>? bankAccounts,
    List<String>? paymentMethodsAccepted,
    InvoiceSettingsInfo? invoiceSettings,
    OperationalInfo? operational,
    OwnershipInfo? ownership,
    String? ownerUserId,
    FactoryStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Convenience single-field legacy parameters
    String? name,
    String? address,
    String? phone,
    String? ownerName,
  }) {
    return FactoryProfile(
      id: id ?? this.id,
      identity: identity ??
          (name != null
              ? this.identity.copyWith(businessName: name)
              : this.identity),
      contact: contact ??
          (address != null || phone != null
              ? this.contact.copyWith(
                    address: address ?? this.contact.address,
                    phone: phone ?? this.contact.phone,
                  )
              : this.contact),
      legal: legal ?? this.legal,
      bankAccounts: bankAccounts ?? this.bankAccounts,
      paymentMethodsAccepted:
          paymentMethodsAccepted ?? this.paymentMethodsAccepted,
      invoiceSettings: invoiceSettings ?? this.invoiceSettings,
      operational: operational ?? this.operational,
      ownership: ownership ??
          (ownerName != null
              ? this.ownership.copyWith(ownerName: ownerName)
              : this.ownership),
      ownerUserId: ownerUserId ?? this.ownerUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        identity,
        contact,
        legal,
        bankAccounts,
        paymentMethodsAccepted,
        invoiceSettings,
        operational,
        ownership,
        ownerUserId,
        status,
        createdAt,
        updatedAt,
      ];
}
