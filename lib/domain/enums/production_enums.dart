enum ProductionProductType {
  marbleTiles,
  marbleSlabsPolished,
  marbleSlabsUnpolished,
  stripsBorder,
  stepsStairs,
  customCutPieces,
  columnsPillars,
  countertops,
  flooringSheets,
  mosaicTiles,
  marbleChipsFinished;

  String get firestoreValue => name;

  String get label => switch (this) {
        ProductionProductType.marbleTiles => 'Marble Tiles',
        ProductionProductType.marbleSlabsPolished => 'Marble Slabs (Polished)',
        ProductionProductType.marbleSlabsUnpolished => 'Marble Slabs (Unpolished)',
        ProductionProductType.stripsBorder => 'Strips / Border',
        ProductionProductType.stepsStairs => 'Steps / Stairs',
        ProductionProductType.customCutPieces => 'Custom Cut Pieces',
        ProductionProductType.columnsPillars => 'Columns / Pillars',
        ProductionProductType.countertops => 'Countertops',
        ProductionProductType.flooringSheets => 'Flooring Sheets',
        ProductionProductType.mosaicTiles => 'Mosaic Tiles',
        ProductionProductType.marbleChipsFinished => 'Marble Chips (Finished)',
      };

  static ProductionProductType fromString(String? value) {
    return ProductionProductType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ProductionProductType.marbleTiles,
    );
  }
}

enum ProductionShift {
  morning,
  evening,
  night;

  String get firestoreValue => name;

  String get label => switch (this) {
        ProductionShift.morning => 'Morning',
        ProductionShift.evening => 'Evening',
        ProductionShift.night => 'Night',
      };

  static ProductionShift fromString(String? value) {
    return ProductionShift.values.firstWhere(
      (shift) => shift.name == value,
      orElse: () => ProductionShift.morning,
    );
  }
}

enum ProductionListFilter {
  all,
  thisMonth;

  /// Tab bar order — This Month first, then All.
  static const List<ProductionListFilter> tabOrder = [
    ProductionListFilter.thisMonth,
    ProductionListFilter.all,
  ];

  String get label => switch (this) {
        ProductionListFilter.all => 'All',
        ProductionListFilter.thisMonth => 'This Month',
      };
}
