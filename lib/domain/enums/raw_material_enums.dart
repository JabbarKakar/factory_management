enum RawMaterialType {
  marbleBlocks,
  roughSlabs,
  marbleChips,
  silicaSand,
  diamondSegments,
  abrasivePads,
  resinEpoxy,
  cuttingWire,
  lubricatingOil,
  grindingWheels,
  other;

  String get firestoreValue => name;

  String get label => switch (this) {
        RawMaterialType.marbleBlocks => 'Marble Blocks',
        RawMaterialType.roughSlabs => 'Rough Slabs',
        RawMaterialType.marbleChips => 'Marble Chips / Aggregate',
        RawMaterialType.silicaSand => 'Silica Sand',
        RawMaterialType.diamondSegments => 'Diamond Segments',
        RawMaterialType.abrasivePads => 'Abrasive Pads',
        RawMaterialType.resinEpoxy => 'Resin / Epoxy',
        RawMaterialType.cuttingWire => 'Cutting Wire',
        RawMaterialType.lubricatingOil => 'Lubricating Oil',
        RawMaterialType.grindingWheels => 'Grinding Wheels',
        RawMaterialType.other => 'Other',
      };

  StockUnit get unit => switch (this) {
        RawMaterialType.marbleBlocks => StockUnit.ton,
        RawMaterialType.roughSlabs => StockUnit.slab,
        RawMaterialType.marbleChips => StockUnit.ton,
        RawMaterialType.silicaSand => StockUnit.bag,
        RawMaterialType.diamondSegments => StockUnit.piece,
        RawMaterialType.abrasivePads => StockUnit.set,
        RawMaterialType.resinEpoxy => StockUnit.kg,
        RawMaterialType.cuttingWire => StockUnit.meter,
        RawMaterialType.lubricatingOil => StockUnit.liter,
        RawMaterialType.grindingWheels => StockUnit.piece,
        RawMaterialType.other => StockUnit.piece,
      };

  static RawMaterialType fromString(String? value) {
    return RawMaterialType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RawMaterialType.other,
    );
  }
}

enum StockUnit {
  ton,
  cubicMeter,
  slab,
  bag,
  piece,
  set,
  kg,
  liter,
  meter;

  String get label => switch (this) {
        StockUnit.ton => 'Ton',
        StockUnit.cubicMeter => 'm³',
        StockUnit.slab => 'Slab',
        StockUnit.bag => 'Bag',
        StockUnit.piece => 'Piece',
        StockUnit.set => 'Set',
        StockUnit.kg => 'Kg',
        StockUnit.liter => 'Liter',
        StockUnit.meter => 'Meter',
      };

  static StockUnit fromString(String? value) {
    return StockUnit.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StockUnit.piece,
    );
  }
}

enum StockMovementType {
  stockIn,
  stockOut;

  String get firestoreValue => name;

  String get label => switch (this) {
        StockMovementType.stockIn => 'Stock In',
        StockMovementType.stockOut => 'Stock Out',
      };

  static StockMovementType fromString(String? value) {
    return StockMovementType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StockMovementType.stockIn,
    );
  }
}

enum RawMaterialListFilter {
  all,
  lowStock,
  inStock;

  String get label => switch (this) {
        RawMaterialListFilter.all => 'All',
        RawMaterialListFilter.lowStock => 'Low Stock',
        RawMaterialListFilter.inStock => 'In Stock',
      };
}
