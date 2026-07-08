enum DeliveryStatus {
  scheduled,
  loaded,
  inTransit,
  delivered,
  partiallyDelivered,
  failed;

  String get firestoreValue => name;

  String get label => switch (this) {
        DeliveryStatus.scheduled => 'Scheduled',
        DeliveryStatus.loaded => 'Loaded',
        DeliveryStatus.inTransit => 'In Transit',
        DeliveryStatus.delivered => 'Delivered',
        DeliveryStatus.partiallyDelivered => 'Partially Delivered',
        DeliveryStatus.failed => 'Failed',
      };

  static DeliveryStatus fromString(String? value) {
    return DeliveryStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => DeliveryStatus.scheduled,
    );
  }

  bool get isTerminal => switch (this) {
        DeliveryStatus.delivered ||
        DeliveryStatus.partiallyDelivered ||
        DeliveryStatus.failed =>
          true,
        _ => false,
      };

  bool get isActive => !isTerminal;

  DeliveryStatus? get nextStatus => switch (this) {
        DeliveryStatus.scheduled => DeliveryStatus.loaded,
        DeliveryStatus.loaded => DeliveryStatus.inTransit,
        _ => null,
      };

  String get advanceActionLabel => switch (nextStatus) {
        DeliveryStatus.loaded => 'Mark Loaded',
        DeliveryStatus.inTransit => 'Mark In Transit',
        _ => '',
      };

  bool get canConfirmDelivery =>
      this == DeliveryStatus.inTransit || this == DeliveryStatus.loaded;

  bool get canEditScheduled => this == DeliveryStatus.scheduled;

  bool get canEditLogistics => switch (this) {
        DeliveryStatus.scheduled ||
        DeliveryStatus.loaded ||
        DeliveryStatus.inTransit =>
          true,
        _ => false,
      };
}

enum DeliveryListFilter {
  all,
  active,
  scheduled,
  inTransit,
  delivered,
  failed;

  String get label => switch (this) {
        DeliveryListFilter.all => 'All',
        DeliveryListFilter.active => 'Active',
        DeliveryListFilter.scheduled => 'Scheduled',
        DeliveryListFilter.inTransit => 'In Transit',
        DeliveryListFilter.delivered => 'Delivered',
        DeliveryListFilter.failed => 'Failed',
      };

  static DeliveryListFilter fromQuery(String? value) {
    if (value == null || value.isEmpty) return DeliveryListFilter.all;
    return DeliveryListFilter.values.firstWhere(
      (filter) => filter.name == value,
      orElse: () => DeliveryListFilter.all,
    );
  }

  bool matches(DeliveryStatus status) => switch (this) {
        DeliveryListFilter.all => true,
        DeliveryListFilter.active => status.isActive,
        DeliveryListFilter.scheduled => status == DeliveryStatus.scheduled,
        DeliveryListFilter.inTransit =>
          status == DeliveryStatus.inTransit ||
              status == DeliveryStatus.loaded,
        DeliveryListFilter.delivered =>
          status == DeliveryStatus.delivered ||
              status == DeliveryStatus.partiallyDelivered,
        DeliveryListFilter.failed => status == DeliveryStatus.failed,
      };
}
