import 'package:equatable/equatable.dart';

import '../enums/raw_material_enums.dart';

class RawMaterial extends Equatable {
  const RawMaterial({
    required this.id,
    required this.factoryId,
    required this.materialType,
    required this.currentStock,
    required this.reorderLevel,
    required this.averageCost,
    required this.createdAt,
    this.lastReceiptDate,
    this.updatedAt,
  });

  final String id;
  final String factoryId;
  final RawMaterialType materialType;
  final double currentStock;
  final double reorderLevel;
  final double averageCost;
  final DateTime? lastReceiptDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  StockUnit get unit => materialType.unit;

  bool get isLowStock => reorderLevel > 0 && currentStock <= reorderLevel;

  double get stockValue => currentStock * averageCost;

  bool get hasStock => currentStock > 0;

  RawMaterial copyWith({
    String? id,
    String? factoryId,
    RawMaterialType? materialType,
    double? currentStock,
    double? reorderLevel,
    double? averageCost,
    DateTime? lastReceiptDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RawMaterial(
      id: id ?? this.id,
      factoryId: factoryId ?? this.factoryId,
      materialType: materialType ?? this.materialType,
      currentStock: currentStock ?? this.currentStock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      averageCost: averageCost ?? this.averageCost,
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
      currentStock: 0,
      reorderLevel: 0,
      averageCost: 0,
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        factoryId,
        materialType,
        currentStock,
        reorderLevel,
        averageCost,
        lastReceiptDate,
        createdAt,
        updatedAt,
      ];
}
