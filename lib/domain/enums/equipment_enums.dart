enum EquipmentCategory {
  cutting,
  polishing,
  lifting,
  utility;

  String get firestoreValue => name;

  String get label => switch (this) {
        EquipmentCategory.cutting => 'Cutting',
        EquipmentCategory.polishing => 'Polishing',
        EquipmentCategory.lifting => 'Lifting',
        EquipmentCategory.utility => 'Utility',
      };

  static EquipmentCategory fromString(String? value) {
    return EquipmentCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => EquipmentCategory.cutting,
    );
  }
}

enum EquipmentStatus {
  running,
  underMaintenance,
  broken,
  retired;

  String get firestoreValue => name;

  String get label => switch (this) {
        EquipmentStatus.running => 'Running',
        EquipmentStatus.underMaintenance => 'Under Maintenance',
        EquipmentStatus.broken => 'Broken',
        EquipmentStatus.retired => 'Retired',
      };

  static EquipmentStatus fromString(String? value) {
    return EquipmentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => EquipmentStatus.running,
    );
  }

  bool get isOperational =>
      this == EquipmentStatus.running ||
      this == EquipmentStatus.underMaintenance;
}

enum EquipmentListFilter {
  all,
  running,
  underMaintenance,
  broken,
  retired,
  maintenanceDue;

  String get label => switch (this) {
        EquipmentListFilter.all => 'All',
        EquipmentListFilter.running => 'Running',
        EquipmentListFilter.underMaintenance => 'Maintenance',
        EquipmentListFilter.broken => 'Broken',
        EquipmentListFilter.retired => 'Retired',
        EquipmentListFilter.maintenanceDue => 'Due Soon',
      };

  static EquipmentListFilter fromQuery(String? value) {
    if (value == null || value.isEmpty) return EquipmentListFilter.all;
    return EquipmentListFilter.values.firstWhere(
      (filter) => filter.name == value,
      orElse: () => EquipmentListFilter.all,
    );
  }

  bool matches({
    required EquipmentStatus status,
    required DateTime? nextMaintenanceDueDate,
    required DateTime today,
    int dueSoonWithinDays = 7,
  }) {
    return switch (this) {
      EquipmentListFilter.all => true,
      EquipmentListFilter.running => status == EquipmentStatus.running,
      EquipmentListFilter.underMaintenance =>
        status == EquipmentStatus.underMaintenance,
      EquipmentListFilter.broken => status == EquipmentStatus.broken,
      EquipmentListFilter.retired => status == EquipmentStatus.retired,
      EquipmentListFilter.maintenanceDue => _isMaintenanceDue(
          status: status,
          nextMaintenanceDueDate: nextMaintenanceDueDate,
          today: today,
          dueSoonWithinDays: dueSoonWithinDays,
        ),
    };
  }

  static bool _isMaintenanceDue({
    required EquipmentStatus status,
    required DateTime? nextMaintenanceDueDate,
    required DateTime today,
    required int dueSoonWithinDays,
  }) {
    if (status == EquipmentStatus.retired) return false;
    if (nextMaintenanceDueDate == null) return false;
    final dueDay = DateTime(
      nextMaintenanceDueDate.year,
      nextMaintenanceDueDate.month,
      nextMaintenanceDueDate.day,
    );
    final threshold = today.add(Duration(days: dueSoonWithinDays));
    return !dueDay.isAfter(threshold);
  }
}

enum MaintenanceType {
  preventive,
  corrective,
  emergency;

  String get firestoreValue => name;

  String get label => switch (this) {
        MaintenanceType.preventive => 'Preventive',
        MaintenanceType.corrective => 'Corrective',
        MaintenanceType.emergency => 'Emergency',
      };

  static MaintenanceType fromString(String? value) {
    return MaintenanceType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => MaintenanceType.preventive,
    );
  }
}

enum MaintenancePerformedBy {
  inHouse,
  externalVendor;

  String get firestoreValue => name;

  String get label => switch (this) {
        MaintenancePerformedBy.inHouse => 'In-house',
        MaintenancePerformedBy.externalVendor => 'External Vendor',
      };

  static MaintenancePerformedBy fromString(String? value) {
    return MaintenancePerformedBy.values.firstWhere(
      (item) => item.name == value,
      orElse: () => MaintenancePerformedBy.inHouse,
    );
  }
}
