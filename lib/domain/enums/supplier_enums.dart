enum SupplierType {
  marbleBlockSlab,
  consumables,
  chemical,
  machinery,
  spareParts,
  transportLogistics,
  utility,
  other;

  String get firestoreValue => name;

  String get label => switch (this) {
        SupplierType.marbleBlockSlab => 'Marble Block / Slab',
        SupplierType.consumables => 'Consumables',
        SupplierType.chemical => 'Chemical',
        SupplierType.machinery => 'Machinery',
        SupplierType.spareParts => 'Spare Parts',
        SupplierType.transportLogistics => 'Transport / Logistics',
        SupplierType.utility => 'Utility',
        SupplierType.other => 'Other',
      };

  static SupplierType fromString(String? value) {
    return SupplierType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SupplierType.other,
    );
  }
}
