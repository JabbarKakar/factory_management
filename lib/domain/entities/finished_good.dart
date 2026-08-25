import 'package:equatable/equatable.dart';

import '../enums/inventory_enums.dart';
import '../enums/production_enums.dart';

/// A finished-goods SKU's stock position.
///
/// As with `RawMaterial`, [totalQuantity] and [totalValue] are authoritative and
/// [currentQuantity] / [averageCost] are derived, so movements can be written as
/// `FieldValue.increment` transforms (S38).
class FinishedGood extends Equatable {
  const FinishedGood({
    required this.id,
    required this.factoryId,
    required this.skuKey,
    required this.productType,
    required this.marbleVariety,
    required this.grade,
    required this.totalQuantity,
    required this.totalValue,
    required this.reorderLevel,
    required this.createdAt,
    this.lastUnitCost = 0,
    this.size,
    this.thickness,
    this.location,
    this.lastReceiptDate,
    this.updatedAt,
  });

  /// Builds from the pre-S38 shape, where quantity and unit cost were stored.
  factory FinishedGood.fromLegacy({
    required String id,
    required String factoryId,
    required String skuKey,
    required ProductionProductType productType,
    required String marbleVariety,
    required FinishedGoodGrade grade,
    required double currentQuantity,
    required double averageCost,
    required double reorderLevel,
    required DateTime createdAt,
    String? size,
    String? thickness,
    String? location,
    DateTime? lastReceiptDate,
    DateTime? updatedAt,
  }) {
    return FinishedGood(
      id: id,
      factoryId: factoryId,
      skuKey: skuKey,
      productType: productType,
      marbleVariety: marbleVariety,
      grade: grade,
      totalQuantity: currentQuantity,
      totalValue: currentQuantity * averageCost,
      lastUnitCost: averageCost,
      reorderLevel: reorderLevel,
      createdAt: createdAt,
      size: size,
      thickness: thickness,
      location: location,
      lastReceiptDate: lastReceiptDate,
      updatedAt: updatedAt,
    );
  }

  final String id;
  final String factoryId;
  final String skuKey;
  final ProductionProductType productType;
  final String marbleVariety;
  final String? size;
  final String? thickness;
  final FinishedGoodGrade grade;

  /// Quantity on hand, in square feet.
  final double totalQuantity;

  /// Σ (quantity × unit cost) of what is on hand.
  final double totalValue;

  /// Cost basis kept for when stock reaches zero. See `RawMaterial.lastUnitCost`.
  final double lastUnitCost;

  final double reorderLevel;
  final String? location;
  final DateTime? lastReceiptDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  double get currentQuantity => totalQuantity;

  double get averageCost =>
      totalQuantity > 0 ? totalValue / totalQuantity : lastUnitCost;

  double get stockValue => totalQuantity > 0 ? totalValue : 0;

  bool get isLowStock => reorderLevel > 0 && totalQuantity <= reorderLevel;

  bool get hasStock => totalQuantity > 0;

  String get displaySubtitle {
    final parts = <String>[
      marbleVariety,
      grade.label,
      if (size != null && size!.isNotEmpty) size!,
      if (thickness != null && thickness!.isNotEmpty) thickness!,
    ];
    return parts.join(' · ');
  }

  FinishedGood copyWith({
    String? id,
    String? factoryId,
    String? skuKey,
    ProductionProductType? productType,
    String? marbleVariety,
    String? size,
    String? thickness,
    FinishedGoodGrade? grade,
    double? totalQuantity,
    double? totalValue,
    double? lastUnitCost,
    double? reorderLevel,
    String? location,
    DateTime? lastReceiptDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinishedGood(
      id: id ?? this.id,
      factoryId: factoryId ?? this.factoryId,
      skuKey: skuKey ?? this.skuKey,
      productType: productType ?? this.productType,
      marbleVariety: marbleVariety ?? this.marbleVariety,
      size: size ?? this.size,
      thickness: thickness ?? this.thickness,
      grade: grade ?? this.grade,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      totalValue: totalValue ?? this.totalValue,
      lastUnitCost: lastUnitCost ?? this.lastUnitCost,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      location: location ?? this.location,
      lastReceiptDate: lastReceiptDate ?? this.lastReceiptDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        factoryId,
        skuKey,
        productType,
        marbleVariety,
        size,
        thickness,
        grade,
        totalQuantity,
        totalValue,
        lastUnitCost,
        reorderLevel,
        location,
        lastReceiptDate,
        createdAt,
        updatedAt,
      ];
}
