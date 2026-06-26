enum JobWorkStatus {
  received,
  agreed,
  inCutting,
  qc,
  ready,
  invoiced,
  paid,
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
        JobWorkStatus.closed || JobWorkStatus.cancelled => false,
        _ => true,
      };

  bool get canRecordOutput => switch (this) {
        JobWorkStatus.agreed ||
        JobWorkStatus.inCutting ||
        JobWorkStatus.qc ||
        JobWorkStatus.ready =>
          true,
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
}

enum JobWorkListStageFilter {
  all,
  inCutting,
  qc,
  ready,
  invoiced,
  paid;

  String get label => switch (this) {
        JobWorkListStageFilter.all => 'All Stages',
        JobWorkListStageFilter.inCutting => 'In Cutting',
        JobWorkListStageFilter.qc => 'QC',
        JobWorkListStageFilter.ready => 'Ready',
        JobWorkListStageFilter.invoiced => 'Invoiced',
        JobWorkListStageFilter.paid => 'Paid',
      };

  JobWorkStatus? get status => switch (this) {
        JobWorkListStageFilter.inCutting => JobWorkStatus.inCutting,
        JobWorkListStageFilter.qc => JobWorkStatus.qc,
        JobWorkListStageFilter.ready => JobWorkStatus.ready,
        JobWorkListStageFilter.invoiced => JobWorkStatus.invoiced,
        JobWorkListStageFilter.paid => JobWorkStatus.paid,
        JobWorkListStageFilter.all => null,
      };
}

enum CuttingStrategy {
  gangSaw,
  bridgeSaw,
  wireSaw,
  waterJet,
  mixed;

  String get firestoreValue => name;

  String get label => switch (this) {
        CuttingStrategy.gangSaw => 'Gang Saw (Slabs)',
        CuttingStrategy.bridgeSaw => 'Bridge Saw (Tiles)',
        CuttingStrategy.wireSaw => 'Wire Saw',
        CuttingStrategy.waterJet => 'Water Jet',
        CuttingStrategy.mixed => 'Mixed',
      };

  static CuttingStrategy fromString(String? value) {
    return CuttingStrategy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CuttingStrategy.gangSaw,
    );
  }
}

enum TargetProduct {
  slabs,
  tiles,
  strips,
  steps,
  custom;

  String get label => switch (this) {
        TargetProduct.slabs => 'Slabs',
        TargetProduct.tiles => 'Tiles',
        TargetProduct.strips => 'Strips',
        TargetProduct.steps => 'Steps',
        TargetProduct.custom => 'Custom Shapes',
      };

  static TargetProduct fromString(String? value) {
    return TargetProduct.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TargetProduct.slabs,
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
  perTon,
  perSqFt,
  lumpSum,
  perBlock;

  String get label => switch (this) {
        PricingModel.perTon => 'Per Ton',
        PricingModel.perSqFt => 'Per Sq. Ft',
        PricingModel.lumpSum => 'Lump Sum',
        PricingModel.perBlock => 'Per Block',
      };

  static PricingModel fromString(String? value) {
    return PricingModel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PricingModel.perTon,
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
