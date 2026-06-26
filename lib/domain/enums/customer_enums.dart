enum CustomerType {
  individual,
  business;

  String get label => switch (this) {
        CustomerType.individual => 'Individual',
        CustomerType.business => 'Business',
      };

  String get firestoreValue => name;

  static CustomerType fromString(String? value) {
    return CustomerType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CustomerType.individual,
    );
  }
}

enum CustomerServiceType {
  buyer,
  jobWork,
  both,
  other;

  String get code => switch (this) {
        CustomerServiceType.buyer => 'BUYER',
        CustomerServiceType.jobWork => 'JOB_WORK',
        CustomerServiceType.both => 'BOTH',
        CustomerServiceType.other => 'OTHER',
      };

  String get label => switch (this) {
        CustomerServiceType.buyer => 'Buyer Only',
        CustomerServiceType.jobWork => 'Job Work Only',
        CustomerServiceType.both => 'Buyer + Job Work',
        CustomerServiceType.other => 'Other Services',
      };

  String get description => switch (this) {
        CustomerServiceType.buyer => 'Purchases finished marble from factory',
        CustomerServiceType.jobWork => 'Brings blocks for cutting only',
        CustomerServiceType.both => 'Buys stock and brings blocks for cutting',
        CustomerServiceType.other => 'Polishing, edge work, resin filling, etc.',
      };

  static CustomerServiceType fromCode(String? value) {
    return CustomerServiceType.values.firstWhere(
      (e) => e.code == value,
      orElse: () => CustomerServiceType.buyer,
    );
  }
}

enum CustomerCategory {
  retail,
  wholesale,
  contractor,
  builder,
  exporter;

  String get label => switch (this) {
        CustomerCategory.retail => 'Retail',
        CustomerCategory.wholesale => 'Wholesale',
        CustomerCategory.contractor => 'Contractor',
        CustomerCategory.builder => 'Builder',
        CustomerCategory.exporter => 'Exporter',
      };

  static CustomerCategory fromString(String? value) {
    return CustomerCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CustomerCategory.retail,
    );
  }
}

enum PaymentTerms {
  cash,
  days7,
  days15,
  days30,
  days60;

  String get label => switch (this) {
        PaymentTerms.cash => 'Cash',
        PaymentTerms.days7 => '7 Days',
        PaymentTerms.days15 => '15 Days',
        PaymentTerms.days30 => '30 Days',
        PaymentTerms.days60 => '60 Days',
      };

  static PaymentTerms fromString(String? value) {
    return PaymentTerms.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentTerms.cash,
    );
  }
}

enum CustomerBalanceStatus {
  paidUp,
  dueSoon,
  dueToday,
  overdue,
  outstanding;

  String get label => switch (this) {
        CustomerBalanceStatus.paidUp => 'Paid up',
        CustomerBalanceStatus.dueSoon => 'Due soon',
        CustomerBalanceStatus.dueToday => 'Due today',
        CustomerBalanceStatus.overdue => 'Overdue',
        CustomerBalanceStatus.outstanding => 'Outstanding',
      };
}
