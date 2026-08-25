import 'package:equatable/equatable.dart';

import '../enums/raw_material_enums.dart';

/// A raw material's stock position.
///
/// [totalQuantity] and [totalValue] are the source of truth; [currentStock] and
/// [averageCost] are derived from them. That split is what lets stock movements
/// be written as two `FieldValue.increment` transforms with no read, so
/// concurrent movements cannot lose each other and offline recording still
/// works (S38).
class RawMaterial extends Equatable {
  const RawMaterial({
    required this.id,
    required this.factoryId,
    required this.materialType,
    required this.totalQuantity,
    required this.totalValue,
    required this.reorderLevel,
    required this.createdAt,
    this.lastUnitCost = 0,
    this.lastReceiptDate,
    this.updatedAt,
  });

  /// Builds from the pre-S38 shape, where quantity and unit cost were stored
  /// and value was implied.
  factory RawMaterial.fromLegacy({
    required String id,
    required String factoryId,
    required RawMaterialType materialType,
    required double currentStock,
    required double averageCost,
    required double reorderLevel,
    required DateTime createdAt,
    DateTime? lastReceiptDate,
    DateTime? updatedAt,
  }) {
    return RawMaterial(
      id: id,
      factoryId: factoryId,
      materialType: materialType,
      totalQuantity: currentStock,
      totalValue: currentStock * averageCost,
      lastUnitCost: averageCost,
      reorderLevel: reorderLevel,
      createdAt: createdAt,
      lastReceiptDate: lastReceiptDate,
      updatedAt: updatedAt,
    );
  }

  final String id;
  final String factoryId;
  final RawMaterialType materialType;

  /// Quantity on hand, in [unit].
  final double totalQuantity;

  /// Σ (quantity × unit cost) of what is on hand.
  final double totalValue;

  /// Cost basis kept for when stock reaches zero, so an empty material still
  /// remembers what it last cost. Without it, [averageCost] would read 0 and
  /// an adjustment-in would lose its default unit cost.
  final double lastUnitCost;

  final double reorderLevel;
  final DateTime? lastReceiptDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  StockUnit get unit => materialType.unit;

  double get currentStock => totalQuantity;

  double get averageCost =>
      totalQuantity > 0 ? totalValue / totalQuantity : lastUnitCost;

  double get stockValue => totalQuantity > 0 ? totalValue : 0;

  bool get isLowStock => reorderLevel > 0 && totalQuantity <= reorderLevel;

  bool get hasStock => totalQuantity > 0;

  RawMaterial copyWith({
    String? id,
    String? factoryId,
    RawMaterialType? materialType,
    double? totalQuantity,
    double? totalValue,
    double? lastUnitCost,
    double? reorderLevel,
    DateTime? lastReceiptDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RawMaterial(
      id: id ?? this.id,
      factoryId: factoryId ?? this.factoryId,
      materialType: materialType ?? this.materialType,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      totalValue: totalValue ?? this.totalValue,
      lastUnitCost: lastUnitCost ?? this.lastUnitCost,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      lastReceiptDate: lastReceiptDate ?? this.lastReceiptDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static RawMaterial placeholder({
    required String factoryId,
    required RawMaterialType materialType,
  }) {
    return RawMaterial(
      id: '',
      factoryId: factoryId,
      materialType: materialType,
      totalQuantity: 0,
      totalValue: 0,
      reorderLevel: 0,
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        factoryId,
        materialType,
        totalQuantity,
        totalValue,
        lastUnitCost,
        reorderLevel,
        lastReceiptDate,
        createdAt,
        updatedAt,
      ];
}
