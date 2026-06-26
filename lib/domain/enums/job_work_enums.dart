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
