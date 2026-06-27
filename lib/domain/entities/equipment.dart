import 'package:equatable/equatable.dart';

import '../enums/equipment_enums.dart';

class Equipment extends Equatable {
  const Equipment({
    required this.id,
    required this.equipmentNumber,
    required this.factoryId,
    required this.name,
    required this.category,
    required this.status,
    required this.createdAt,
    this.brand,
    this.model,
    this.serialNumber,
    this.purchaseDate,
    this.purchaseCost,
    this.supplierName,
    this.location,
    this.depreciationRatePercent,
    this.lastMaintenanceDate,
    this.nextMaintenanceDueDate,
    this.maintenanceIntervalDays,
    this.notes,
    this.updatedAt,
  });

  final String id;
  final String equipmentNumber;
  final String factoryId;
  final String name;
  final EquipmentCategory category;
  final EquipmentStatus status;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final double? purchaseCost;
  final String? supplierName;
  final String? location;
  final double? depreciationRatePercent;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDueDate;
  final int? maintenanceIntervalDays;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool isMaintenanceOverdue({DateTime? today}) {
    final reference = _dateOnly(today ?? DateTime.now());
    if (status == EquipmentStatus.retired) return false;
    final due = nextMaintenanceDueDate;
    if (due == null) return false;
    return _dateOnly(due).isBefore(reference);
  }

  bool isMaintenanceDueSoon({
    DateTime? today,
    int withinDays = 7,
  }) {
    final reference = _dateOnly(today ?? DateTime.now());
    if (status == EquipmentStatus.retired) return false;
    final due = nextMaintenanceDueDate;
    if (due == null) return false;
    final dueDay = _dateOnly(due);
    if (dueDay.isBefore(reference)) return true;
    final threshold = reference.add(Duration(days: withinDays));
    return !dueDay.isAfter(threshold);
  }

  double? bookValue({DateTime? asOf}) {
    final cost = purchaseCost;
    final purchased = purchaseDate;
    final rate = depreciationRatePercent;
    if (cost == null || purchased == null || rate == null || rate <= 0) {
      return cost;
    }

    final now = asOf ?? DateTime.now();
    final yearsOwned = now.difference(purchased).inDays / 365;
    if (yearsOwned <= 0) return cost;

    final depreciated = cost * (rate / 100) * yearsOwned;
    final value = cost - depreciated;
    return value < 0 ? 0 : value;
  }

  String get displaySubtitle {
    final parts = <String>[category.label, status.label];
    if (location != null && location!.trim().isNotEmpty) {
      parts.add(location!.trim());
    }
    return parts.join(' · ');
  }

  Equipment copyWith({
    String? id,
    String? equipmentNumber,
    String? factoryId,
    String? name,
    EquipmentCategory? category,
    EquipmentStatus? status,
    String? brand,
    String? model,
    String? serialNumber,
    DateTime? purchaseDate,
    bool clearPurchaseDate = false,
    double? purchaseCost,
    bool clearPurchaseCost = false,
    String? supplierName,
    String? location,
    double? depreciationRatePercent,
    bool clearDepreciationRatePercent = false,
    DateTime? lastMaintenanceDate,
    bool clearLastMaintenanceDate = false,
    DateTime? nextMaintenanceDueDate,
    bool clearNextMaintenanceDueDate = false,
    int? maintenanceIntervalDays,
    bool clearMaintenanceIntervalDays = false,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Equipment(
      id: id ?? this.id,
      equipmentNumber: equipmentNumber ?? this.equipmentNumber,
      factoryId: factoryId ?? this.factoryId,
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      purchaseDate: clearPurchaseDate ? null : (purchaseDate ?? this.purchaseDate),
      purchaseCost: clearPurchaseCost ? null : (purchaseCost ?? this.purchaseCost),
      supplierName: supplierName ?? this.supplierName,
      location: location ?? this.location,
      depreciationRatePercent: clearDepreciationRatePercent
          ? null
          : (depreciationRatePercent ?? this.depreciationRatePercent),
      lastMaintenanceDate: clearLastMaintenanceDate
          ? null
          : (lastMaintenanceDate ?? this.lastMaintenanceDate),
      nextMaintenanceDueDate: clearNextMaintenanceDueDate
          ? null
          : (nextMaintenanceDueDate ?? this.nextMaintenanceDueDate),
      maintenanceIntervalDays: clearMaintenanceIntervalDays
          ? null
          : (maintenanceIntervalDays ?? this.maintenanceIntervalDays),
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  @override
  List<Object?> get props => [
        id,
        equipmentNumber,
        factoryId,
        name,
        category,
        status,
        brand,
        model,
        serialNumber,
        purchaseDate,
        purchaseCost,
        supplierName,
        location,
        depreciationRatePercent,
        lastMaintenanceDate,
        nextMaintenanceDueDate,
        maintenanceIntervalDays,
        notes,
        createdAt,
        updatedAt,
      ];
}
