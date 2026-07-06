enum FactoryStatus {
  active,
  inactive;

  String get firestoreValue => name;

  static FactoryStatus fromString(String? value) {
    return FactoryStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => FactoryStatus.active,
    );
  }
}
