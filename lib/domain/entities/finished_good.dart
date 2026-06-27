import 'package:equatable/equatable.dart';

import '../enums/inventory_enums.dart';
import '../enums/production_enums.dart';

class FinishedGood extends Equatable {
  const FinishedGood({
    required this.id,
    required this.factoryId,
    required this.skuKey,
    required this.productType,
    required this.marbleVariety,
    required this.grade,
    required this.currentQuantity,
    required this.reorderLevel,
    required this.averageCost,
    required this.createdAt,
    this.size,
    this.thickness,
    this.location,
    this.lastReceiptDate,
    this.updatedAt,
  });

  final String id;
  final String factoryId;
  final String skuKey;
  final ProductionProductType productType;
  final String marbleVariety;
  final String? size;
  final String? thickness;
  final FinishedGoodGrade grade;
  final double currentQuantity;
  final double reorderLevel;
  final double averageCost;
  final String? location;
  final DateTime? lastReceiptDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isLowStock => reorderLevel > 0 && currentQuantity <= reorderLevel;

  bool get hasStock => currentQuantity > 0;

  double get stockValue => currentQuantity * averageCost;

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
    double? currentQuantity,
    double? reorderLevel,
    double? averageCost,
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
      currentQuantity: currentQuantity ?? this.currentQuantity,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      averageCost: averageCost ?? this.averageCost,
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
        currentQuantity,
        reorderLevel,
        averageCost,
        location,
        lastReceiptDate,
        createdAt,
        updatedAt,
      ];
}
