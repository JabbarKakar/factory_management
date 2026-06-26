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

  bool get isCompleted => switch (this) {
        SalesOrderStatus.paid || SalesOrderStatus.closed => true,
        _ => false,
      };

  bool get isListMuted => isCompleted || this == SalesOrderStatus.cancelled;

  int get listSortRank => switch (this) {
        SalesOrderStatus.received || SalesOrderStatus.ready => 0,
        SalesOrderStatus.invoiced => 1,
        SalesOrderStatus.paid || SalesOrderStatus.closed => 2,
        SalesOrderStatus.cancelled => 3,
      };

  SalesOrderStatus? get nextStatus => switch (this) {
        SalesOrderStatus.received => SalesOrderStatus.ready,
        SalesOrderStatus.paid => SalesOrderStatus.closed,
        _ => null,
      };

  String get advanceActionLabel => switch (nextStatus) {
        SalesOrderStatus.ready => 'Mark Ready',
        SalesOrderStatus.closed => 'Close Order',
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
  inProgress,
  received,
  ready,
  invoiced,
  paid,
  closed,
  cancelled;

  String get label => switch (this) {
        SalesListFilter.all => 'All',
        SalesListFilter.inProgress => 'In Progress',
        SalesListFilter.received => 'Received',
        SalesListFilter.ready => 'Ready',
        SalesListFilter.invoiced => 'Invoiced',
        SalesListFilter.paid => 'Paid',
        SalesListFilter.closed => 'Closed',
        SalesListFilter.cancelled => 'Cancelled',
      };

  static SalesListFilter fromQuery(String? value) {
    if (value == null || value.isEmpty) return SalesListFilter.all;
    return SalesListFilter.values.firstWhere(
      (filter) => filter.name == value,
      orElse: () => SalesListFilter.all,
    );
  }

  bool matches(SalesOrderStatus status) => switch (this) {
        SalesListFilter.all => true,
        SalesListFilter.inProgress => status.isActive,
        SalesListFilter.received => status == SalesOrderStatus.received,
        SalesListFilter.ready => status == SalesOrderStatus.ready,
        SalesListFilter.invoiced => status == SalesOrderStatus.invoiced,
        SalesListFilter.paid => status == SalesOrderStatus.paid,
        SalesListFilter.closed => status == SalesOrderStatus.closed,
        SalesListFilter.cancelled => status == SalesOrderStatus.cancelled,
      };
}
