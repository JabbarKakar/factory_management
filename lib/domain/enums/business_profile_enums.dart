enum FilerStatus {
  filer,
  nonFiler,
  unknown;

  String get firestoreValue => name;

  String get label {
    switch (this) {
      case FilerStatus.filer:
        return 'Filer (Active Taxpayer)';
      case FilerStatus.nonFiler:
        return 'Non-Filer';
      case FilerStatus.unknown:
        return 'Unknown / Unspecified';
    }
  }

  static FilerStatus fromString(String? value) {
    return FilerStatus.values.firstWhere(
      (s) => s.name == value || s.firestoreValue == value,
      orElse: () => FilerStatus.unknown,
    );
  }
}

enum ImageType {
  logo,
  signature,
  stamp;

  String get storagePathSegment {
    switch (this) {
      case ImageType.logo:
        return 'logo';
      case ImageType.signature:
        return 'signature';
      case ImageType.stamp:
        return 'stamp';
    }
  }

  String get label {
    switch (this) {
      case ImageType.logo:
        return 'Business Logo';
      case ImageType.signature:
        return 'Authorized Signature';
      case ImageType.stamp:
        return 'Official Stamp';
    }
  }
}

enum ProfileSection {
  identity,
  contact,
  legal,
  bankAccounts,
  paymentMethods,
  invoiceSettings,
  operational,
  ownership;

  String get title {
    switch (this) {
      case ProfileSection.identity:
        return 'Core Identity & Branding';
      case ProfileSection.contact:
        return 'Contact & Location';
      case ProfileSection.legal:
        return 'Tax & Legal Identifiers';
      case ProfileSection.bankAccounts:
        return 'Bank Accounts';
      case ProfileSection.paymentMethods:
        return 'Accepted Payment Methods';
      case ProfileSection.invoiceSettings:
        return 'Invoicing & Document Rules';
      case ProfileSection.operational:
        return 'Operational & Fiscal Preferences';
      case ProfileSection.ownership:
        return 'Ownership & Authorized Signatories';
    }
  }
}
