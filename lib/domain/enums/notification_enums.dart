enum NotificationType {
  paymentDueIn15Days,
  paymentDueIn7Days,
  paymentDueIn3Days,
  paymentDueTomorrow,
  paymentDueToday,
  paymentOverdue,
  partialPaymentReceived,
  lowRawMaterialStock,
  lowFinishedGoodsStock,
  equipmentMaintenanceDueSoon,
  equipmentMaintenanceOverdue,
  pendingDelivery,
  qcReject,
  jobWorkReadyForPickup,
  jobWorkNotCollected;

  String get firestoreValue => name;

  static NotificationType fromString(String? value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.paymentDueToday,
    );
  }

  bool get isPaymentType => switch (this) {
        NotificationType.paymentDueIn15Days ||
        NotificationType.paymentDueIn7Days ||
        NotificationType.paymentDueIn3Days ||
        NotificationType.paymentDueTomorrow ||
        NotificationType.paymentDueToday ||
        NotificationType.paymentOverdue ||
        NotificationType.partialPaymentReceived =>
          true,
        _ => false,
      };

  bool get isJobWorkType => switch (this) {
        NotificationType.jobWorkReadyForPickup ||
        NotificationType.jobWorkNotCollected =>
          true,
        _ => false,
      };

  bool get isStockType => switch (this) {
        NotificationType.lowRawMaterialStock ||
        NotificationType.lowFinishedGoodsStock =>
          true,
        _ => false,
      };

  bool get isOperationsType => switch (this) {
        NotificationType.equipmentMaintenanceDueSoon ||
        NotificationType.equipmentMaintenanceOverdue ||
        NotificationType.pendingDelivery ||
        NotificationType.qcReject =>
          true,
        _ => false,
      };
}

enum NotificationPriority {
  low,
  medium,
  high,
  critical,
  info;

  String get firestoreValue => name;

  static NotificationPriority fromString(String? value) {
    return NotificationPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationPriority.medium,
    );
  }
}

enum NotificationFilter {
  all,
  payments,
  dueThisWeek,
  overdue,
  jobWork,
  stock,
  operations;

  String get label => switch (this) {
        NotificationFilter.all => 'All',
        NotificationFilter.payments => 'Payments',
        NotificationFilter.dueThisWeek => 'Due Soon',
        NotificationFilter.overdue => 'Overdue',
        NotificationFilter.jobWork => 'Job Work',
        NotificationFilter.stock => 'Stock',
        NotificationFilter.operations => 'Operations',
      };

  bool get isQuickFilter =>
      this == dueThisWeek || this == overdue || this == operations;

  static NotificationFilter fromQuery(String? value) {
    if (value == null || value.isEmpty) return NotificationFilter.all;
    return NotificationFilter.values.firstWhere(
      (filter) => filter.name == value,
      orElse: () => NotificationFilter.all,
    );
  }
}
