enum JobWorkStatus {
  received,
  agreed,
  inCutting,
  qc,
  ready,
  invoiced,
  paid,
  partiallyCollected,
  collected,
  closed,
  cancelled;

  String get firestoreValue => switch (this) {
        JobWorkStatus.received => 'received',
        JobWorkStatus.agreed => 'agreed',
        JobWorkStatus.inCutting => 'inCutting',
        JobWorkStatus.qc => 'qc',
        JobWorkStatus.ready => 'ready',
        JobWorkStatus.invoiced => 'invoiced',
        JobWorkStatus.paid => 'paid',
        JobWorkStatus.partiallyCollected => 'partiallyCollected',
        JobWorkStatus.collected => 'collected',
        JobWorkStatus.closed => 'closed',
        JobWorkStatus.cancelled => 'cancelled',
      };

  String get label => switch (this) {
        JobWorkStatus.received => 'Received',
        JobWorkStatus.agreed => 'Agreed',
        JobWorkStatus.inCutting => 'In Cutting',
        JobWorkStatus.qc => 'QC',
        JobWorkStatus.ready => 'Ready',
        JobWorkStatus.invoiced => 'Invoiced',
        JobWorkStatus.paid => 'Paid',
        JobWorkStatus.partiallyCollected => 'Partially Collected',
        JobWorkStatus.collected => 'Collected',
        JobWorkStatus.closed => 'Closed',
        JobWorkStatus.cancelled => 'Cancelled',
      };

  static JobWorkStatus fromString(String? value) {
    return JobWorkStatus.values.firstWhere(
      (e) => e.firestoreValue == value,
      orElse: () => JobWorkStatus.received,
    );
  }

  bool get isActive => switch (this) {
        JobWorkStatus.received ||
        JobWorkStatus.agreed ||
        JobWorkStatus.inCutting ||
        JobWorkStatus.qc ||
        JobWorkStatus.ready =>
          true,
        JobWorkStatus.invoiced ||
        JobWorkStatus.paid ||
        JobWorkStatus.partiallyCollected ||
        JobWorkStatus.collected ||
        JobWorkStatus.closed ||
        JobWorkStatus.cancelled =>
          false,
      };

  bool get isInProduction => switch (this) {
        JobWorkStatus.received ||
        JobWorkStatus.agreed ||
        JobWorkStatus.inCutting ||
        JobWorkStatus.qc =>
          true,
        _ => false,
      };

  bool get isCompleted => switch (this) {
        JobWorkStatus.collected || JobWorkStatus.closed => true,
        _ => false,
      };

  bool get isPendingPickup => switch (this) {
        JobWorkStatus.ready ||
        JobWorkStatus.invoiced ||
        JobWorkStatus.paid ||
        JobWorkStatus.partiallyCollected =>
          true,
        _ => false,
      };

  bool get isListMuted => isCompleted || this == JobWorkStatus.cancelled;

  int get listSortRank => switch (this) {
        JobWorkStatus.received ||
        JobWorkStatus.agreed ||
        JobWorkStatus.inCutting ||
        JobWorkStatus.qc =>
          0,
        JobWorkStatus.ready ||
        JobWorkStatus.invoiced ||
        JobWorkStatus.paid ||
        JobWorkStatus.partiallyCollected =>
          1,
        JobWorkStatus.collected || JobWorkStatus.closed => 2,
        JobWorkStatus.cancelled => 3,
      };

  bool get canRecordOutput => switch (this) {
        JobWorkStatus.agreed ||
        JobWorkStatus.inCutting ||
        JobWorkStatus.qc ||
        JobWorkStatus.ready ||
        JobWorkStatus.partiallyCollected =>
          true,
        _ => false,
      };

  /// Material may leave the factory once cutting has started.
  /// Fully collected / closed / cancelled orders cannot collect again.
  bool get canCollectMaterial => switch (this) {
        JobWorkStatus.inCutting ||
        JobWorkStatus.qc ||
        JobWorkStatus.ready ||
        JobWorkStatus.invoiced ||
        JobWorkStatus.paid ||
        JobWorkStatus.partiallyCollected =>
          true,
        _ => false,
      };

  /// Payment/invoice updates must not overwrite collection progress.
  bool get isCollectionStatus => switch (this) {
        JobWorkStatus.partiallyCollected || JobWorkStatus.collected => true,
        _ => false,
      };

  bool get canAdvanceOperationally => switch (this) {
        JobWorkStatus.agreed ||
        JobWorkStatus.inCutting ||
        JobWorkStatus.qc =>
          true,
        _ => false,
      };

  JobWorkStatus? get nextOperationalStatus => switch (this) {
        JobWorkStatus.received => JobWorkStatus.agreed,
        JobWorkStatus.agreed => JobWorkStatus.inCutting,
        JobWorkStatus.inCutting => JobWorkStatus.qc,
        JobWorkStatus.qc => JobWorkStatus.ready,
        _ => null,
      };

  String get advanceActionLabel => switch (nextOperationalStatus) {
        JobWorkStatus.agreed => 'Confirm Agreement',
        JobWorkStatus.inCutting => 'Start Cutting',
        JobWorkStatus.qc => 'Send to QC',
        JobWorkStatus.ready => 'Mark Ready for Pickup',
        _ => '',
      };

  /// Only Close Order remains as a manual completion step.
  JobWorkStatus? get nextCompletionStatus => switch (this) {
        JobWorkStatus.collected => JobWorkStatus.closed,
        _ => null,
      };

  String get completionActionLabel => switch (nextCompletionStatus) {
        JobWorkStatus.closed => 'Close Order',
        _ => '',
      };
}

enum JobWorkListStageFilter {
  all,
  active,
  inProgress,
  atQc,
  ready,
  invoiced,
  paid,
  partiallyCollected,
  pendingPickup,
  completed,
  cancelled;

  String get label => switch (this) {
        JobWorkListStageFilter.all => 'All',
        JobWorkListStageFilter.active => 'Active',
        JobWorkListStageFilter.inProgress => 'In Progress',
        JobWorkListStageFilter.atQc => 'At QC',
        JobWorkListStageFilter.ready => 'Ready',
        JobWorkListStageFilter.invoiced => 'Invoiced',
        JobWorkListStageFilter.paid => 'Paid',
        JobWorkListStageFilter.partiallyCollected => 'Partially Collected',
        JobWorkListStageFilter.pendingPickup => 'Pending Pickup',
        JobWorkListStageFilter.completed => 'Completed',
        JobWorkListStageFilter.cancelled => 'Cancelled',
      };

  static JobWorkListStageFilter fromQuery(String? value) {
    if (value == null || value.isEmpty) return JobWorkListStageFilter.all;
    return JobWorkListStageFilter.values.firstWhere(
      (filter) => filter.name == value,
      orElse: () => JobWorkListStageFilter.all,
    );
  }

  bool matches(JobWorkStatus status) => switch (this) {
        JobWorkListStageFilter.all => true,
        JobWorkListStageFilter.active => status.isActive,
        JobWorkListStageFilter.inProgress => status.isInProduction,
        JobWorkListStageFilter.atQc => status == JobWorkStatus.qc,
        JobWorkListStageFilter.ready => status == JobWorkStatus.ready,
        JobWorkListStageFilter.invoiced => status == JobWorkStatus.invoiced,
        JobWorkListStageFilter.paid => status == JobWorkStatus.paid,
        JobWorkListStageFilter.partiallyCollected =>
          status == JobWorkStatus.partiallyCollected,
        JobWorkListStageFilter.pendingPickup => status.isPendingPickup,
        JobWorkListStageFilter.completed => status.isCompleted,
        JobWorkListStageFilter.cancelled => status == JobWorkStatus.cancelled,
      };
}

enum CuttingStrategy {
  fourPiller,
  gangSaw,
  bridgeSaw,
  wireSaw,
  waterJet,
  mixed,
  vertical;

  String get firestoreValue => name;

  String get label => switch (this) {
        CuttingStrategy.fourPiller => 'Four Piller',
        CuttingStrategy.gangSaw => 'Gang Saw (Slabs)',
        CuttingStrategy.bridgeSaw => 'Bridge Saw (Tiles)',
        CuttingStrategy.wireSaw => 'Wire Saw',
        CuttingStrategy.waterJet => 'Water Jet',
        CuttingStrategy.mixed => 'Mixed',
        CuttingStrategy.vertical => 'Vertical',
      };

  static CuttingStrategy fromString(String? value) {
    return CuttingStrategy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CuttingStrategy.fourPiller,
    );
  }
}

enum TargetProduct {
  sizeCutting,
  counterCutting,
  slabs,
  tiles,
  strips,
  steps,
  custom;

  String get label => switch (this) {
        TargetProduct.sizeCutting => 'Size Cutting',
        TargetProduct.counterCutting => 'Counter Cutting',
        TargetProduct.slabs => 'Slabs',
        TargetProduct.tiles => 'Tiles',
        TargetProduct.strips => 'Strips',
        TargetProduct.steps => 'Steps',
        TargetProduct.custom => 'Custom Shapes',
      };

  static TargetProduct fromString(String? value) {
    return TargetProduct.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TargetProduct.sizeCutting,
    );
  }
}

enum FinishType {
  unpolished,
  polished,
  honed,
  brushed,
  edgeOnly;

  String get label => switch (this) {
        FinishType.unpolished => 'Unpolished',
        FinishType.polished => 'Polished',
        FinishType.honed => 'Honed',
        FinishType.brushed => 'Brushed',
        FinishType.edgeOnly => 'Edge Only',
      };

  static FinishType fromString(String? value) {
    return FinishType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FinishType.unpolished,
    );
  }
}

enum PricingModel {
  perSqFt,
  perTon,
  lumpSum,
  perBlock;

  String get label => switch (this) {
        PricingModel.perSqFt => 'Per Sq. Ft',
        PricingModel.perTon => 'Per Ton',
        PricingModel.lumpSum => 'Lump Sum',
        PricingModel.perBlock => 'Per Block',
      };

  static PricingModel fromString(String? value) {
    return PricingModel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PricingModel.perSqFt,
    );
  }
}

enum WasteUnit {
  tons,
  sqFt;

  String get label => switch (this) {
        WasteUnit.tons => 'Tons',
        WasteUnit.sqFt => 'Sq. Ft',
      };

  String get firestoreValue => name;

  static WasteUnit fromString(String? value) {
    return WasteUnit.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WasteUnit.tons,
    );
  }
}

enum WasteDisposition {
  customerTakes,
  factoryKeeps,
  disposed;

  String get label => switch (this) {
        WasteDisposition.customerTakes => 'Customer Takes',
        WasteDisposition.factoryKeeps => 'Factory Keeps',
        WasteDisposition.disposed => 'Disposed',
      };

  String get firestoreValue => name;

  static WasteDisposition fromString(String? value) {
    return WasteDisposition.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WasteDisposition.customerTakes,
    );
  }
}
