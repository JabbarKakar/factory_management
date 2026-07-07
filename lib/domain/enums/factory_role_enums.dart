enum FactoryRole {
  owner,
  factoryManager,
  accountant,
  salesStaff,
  jobWorkClerk,
  supervisor,
  storeKeeper,
  driver,
  viewer;

  String get firestoreValue => name;

  String get label => switch (this) {
        FactoryRole.owner => 'Owner',
        FactoryRole.factoryManager => 'Factory Manager',
        FactoryRole.accountant => 'Accountant',
        FactoryRole.salesStaff => 'Sales Staff',
        FactoryRole.jobWorkClerk => 'Job Work Clerk',
        FactoryRole.supervisor => 'Supervisor',
        FactoryRole.storeKeeper => 'Store Keeper',
        FactoryRole.driver => 'Driver',
        FactoryRole.viewer => 'Viewer',
      };

  static FactoryRole fromString(String? value) {
    if (value == null || value.isEmpty) return FactoryRole.owner;
    final normalized = switch (value) {
      'manager' => 'factoryManager',
      _ => value,
    };
    return FactoryRole.values.firstWhere(
      (role) => role.name == normalized || role.firestoreValue == normalized,
      orElse: () => FactoryRole.viewer,
    );
  }
}
