enum SalesOrderStatus {
  received,
  ready,
  invoiced,
  paid,
  closed,
  cancelled;

  String get firestoreValue => name;

  String get label => switch (this) {
        SalesOrderStatus.received => 'Received',
        SalesOrderStatus.ready => 'Ready',
        SalesOrderStatus.invoiced => 'Invoiced',
        SalesOrderStatus.paid => 'Paid',
        SalesOrderStatus.closed => 'Closed',
        SalesOrderStatus.cancelled => 'Cancelled',
      };

  static SalesOrderStatus fromString(String? value) {
    return SalesOrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SalesOrderStatus.received,
    );
  }

  bool get isActive => switch (this) {
        SalesOrderStatus.received || SalesOrderStatus.ready => true,
        _ => false,
      };

  SalesOrderStatus? get nextStatus => switch (this) {
        SalesOrderStatus.received => SalesOrderStatus.ready,
        _ => null,
      };

  String get advanceActionLabel => switch (nextStatus) {
        SalesOrderStatus.ready => 'Mark Ready',
        _ => '',
      };
}

enum SalesProductType {
  tile,
  slab,
  custom;

  String get label => switch (this) {
        SalesProductType.tile => 'Tile',
        SalesProductType.slab => 'Slab',
        SalesProductType.custom => 'Custom',
      };

  String get firestoreValue => name;

  static SalesProductType fromString(String? value) {
    return SalesProductType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SalesProductType.tile,
    );
  }
}

enum SalesQuantityUnit {
  sqFt,
  pieces;

  String get label => switch (this) {
        SalesQuantityUnit.sqFt => 'Sq. Ft',
        SalesQuantityUnit.pieces => 'Pieces',
      };

  String get firestoreValue => name;

  static SalesQuantityUnit fromString(String? value) {
    return SalesQuantityUnit.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SalesQuantityUnit.sqFt,
    );
  }
}

enum SalesOrderSource {
  walkIn,
  phone,
  whatsApp,
  contractor;

  String get label => switch (this) {
        SalesOrderSource.walkIn => 'Walk-in',
        SalesOrderSource.phone => 'Phone',
        SalesOrderSource.whatsApp => 'WhatsApp',
        SalesOrderSource.contractor => 'Contractor',
      };

  String get firestoreValue => name;

  static SalesOrderSource fromString(String? value) {
    return SalesOrderSource.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SalesOrderSource.walkIn,
    );
  }
}

enum SalesListFilter {
  all,
  received,
  ready,
  invoiced,
  paid;

  String get label => switch (this) {
        SalesListFilter.all => 'All',
        SalesListFilter.received => 'Received',
        SalesListFilter.ready => 'Ready',
        SalesListFilter.invoiced => 'Invoiced',
        SalesListFilter.paid => 'Paid',
      };

  SalesOrderStatus? get status => switch (this) {
        SalesListFilter.received => SalesOrderStatus.received,
        SalesListFilter.ready => SalesOrderStatus.ready,
        SalesListFilter.invoiced => SalesOrderStatus.invoiced,
        SalesListFilter.paid => SalesOrderStatus.paid,
        SalesListFilter.all => null,
      };
}
