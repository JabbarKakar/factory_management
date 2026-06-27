import 'production_enums.dart';

enum FinishedGoodGrade {
  gradeA,
  gradeB,
  gradeC,
  reject;

  String get firestoreValue => name;

  String get label => switch (this) {
        FinishedGoodGrade.gradeA => 'Grade A',
        FinishedGoodGrade.gradeB => 'Grade B',
        FinishedGoodGrade.gradeC => 'Grade C',
        FinishedGoodGrade.reject => 'Reject',
      };

  static FinishedGoodGrade fromString(String? value) {
    return FinishedGoodGrade.values.firstWhere(
      (grade) => grade.name == value,
      orElse: () => FinishedGoodGrade.gradeA,
    );
  }
}

enum InventoryMovementType {
  productionIn,
  adjustmentIn,
  adjustmentOut;

  String get firestoreValue => name;

  String get label => switch (this) {
        InventoryMovementType.productionIn => 'Production Receipt',
        InventoryMovementType.adjustmentIn => 'Stock Added',
        InventoryMovementType.adjustmentOut => 'Stock Removed',
      };

  static InventoryMovementType fromString(String? value) {
    return InventoryMovementType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => InventoryMovementType.productionIn,
    );
  }
}

enum FinishedGoodsListFilter {
  all,
  inStock,
  lowStock;

  String get label => switch (this) {
        FinishedGoodsListFilter.all => 'All',
        FinishedGoodsListFilter.inStock => 'In Stock',
        FinishedGoodsListFilter.lowStock => 'Low Stock',
      };
}

String buildFinishedGoodSkuKey({
  required ProductionProductType productType,
  required String marbleVariety,
  required FinishedGoodGrade grade,
  String? size,
  String? thickness,
}) {
  final normalizedVariety = marbleVariety.trim().toLowerCase();
  final normalizedSize = (size ?? '').trim().toLowerCase();
  final normalizedThickness = (thickness ?? '').trim().toLowerCase();
  return '${productType.name}|$normalizedVariety|$normalizedSize|$normalizedThickness|${grade.name}';
}
