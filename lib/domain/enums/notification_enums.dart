enum NotificationType {
  paymentDueIn7Days,
  paymentDueIn3Days,
  paymentDueTomorrow,
  paymentDueToday,
  paymentOverdue,
  partialPaymentReceived;

  String get firestoreValue => name;

  static NotificationType fromString(String? value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.paymentDueToday,
    );
  }

  bool get isPaymentType => switch (this) {
        NotificationType.paymentDueIn7Days ||
        NotificationType.paymentDueIn3Days ||
        NotificationType.paymentDueTomorrow ||
        NotificationType.paymentDueToday ||
        NotificationType.paymentOverdue ||
        NotificationType.partialPaymentReceived =>
          true,
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
  overdue;

  String get label => switch (this) {
        NotificationFilter.all => 'All',
        NotificationFilter.payments => 'Payments',
        NotificationFilter.dueThisWeek => 'Due Soon',
        NotificationFilter.overdue => 'Overdue',
      };

  bool get isQuickFilter => this == dueThisWeek || this == overdue;
}
