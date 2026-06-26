enum ExpenseCategory {
  rawMaterialPurchase,
  labourWages,
  electricity,
  waterSewage,
  fuel,
  machineMaintenance,
  spareParts,
  transportInward,
  transportOutward,
  rent,
  officeSupplies,
  communication,
  bankCharges,
  depreciation,
  insurance,
  marketing,
  professionalFees,
  miscellaneous;

  String get firestoreValue => name;

  String get label => switch (this) {
        ExpenseCategory.rawMaterialPurchase => 'Raw Material Purchase',
        ExpenseCategory.labourWages => 'Labour Wages',
        ExpenseCategory.electricity => 'Electricity',
        ExpenseCategory.waterSewage => 'Water & Sewage',
        ExpenseCategory.fuel => 'Fuel',
        ExpenseCategory.machineMaintenance => 'Machine Maintenance',
        ExpenseCategory.spareParts => 'Spare Parts',
        ExpenseCategory.transportInward => 'Transport (Inward)',
        ExpenseCategory.transportOutward => 'Transport (Outward)',
        ExpenseCategory.rent => 'Rent',
        ExpenseCategory.officeSupplies => 'Office Supplies',
        ExpenseCategory.communication => 'Communication',
        ExpenseCategory.bankCharges => 'Bank Charges',
        ExpenseCategory.depreciation => 'Depreciation',
        ExpenseCategory.insurance => 'Insurance',
        ExpenseCategory.marketing => 'Marketing',
        ExpenseCategory.professionalFees => 'Professional Fees',
        ExpenseCategory.miscellaneous => 'Miscellaneous',
      };

  static ExpenseCategory fromString(String? value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseCategory.miscellaneous,
    );
  }
}

enum ExpenseListPeriodFilter {
  thisMonth,
  allTime;

  String get label => switch (this) {
        ExpenseListPeriodFilter.thisMonth => 'This Month',
        ExpenseListPeriodFilter.allTime => 'All Time',
      };
}
