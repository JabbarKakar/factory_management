import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/equipment.dart';
import '../../domain/enums/equipment_enums.dart';

class EquipmentModel {
  const EquipmentModel({
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

  factory EquipmentModel.fromFirestore(String id, Map<String, dynamic> data) {
    return EquipmentModel(
      id: id,
      equipmentNumber: data['equipmentNumber'] as String? ?? '',
      factoryId: data['factoryId'] as String? ?? 'default',
      name: data['name'] as String? ?? '',
      category: EquipmentCategory.fromString(data['category'] as String?),
      status: EquipmentStatus.fromString(data['status'] as String?),
      brand: data['brand'] as String?,
      model: data['model'] as String?,
      serialNumber: data['serialNumber'] as String?,
      purchaseDate: (data['purchaseDate'] as Timestamp?)?.toDate(),
      purchaseCost: (data['purchaseCost'] as num?)?.toDouble(),
      supplierName: data['supplierName'] as String?,
      location: data['location'] as String?,
      depreciationRatePercent:
          (data['depreciationRatePercent'] as num?)?.toDouble(),
      lastMaintenanceDate:
          (data['lastMaintenanceDate'] as Timestamp?)?.toDate(),
      nextMaintenanceDueDate:
          (data['nextMaintenanceDueDate'] as Timestamp?)?.toDate(),
      maintenanceIntervalDays: data['maintenanceIntervalDays'] as int?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'equipmentNumber': equipmentNumber,
      'factoryId': factoryId,
      'name': name,
      'category': category.firestoreValue,
      'status': status.firestoreValue,
      if (brand != null && brand!.isNotEmpty) 'brand': brand,
      if (model != null && model!.isNotEmpty) 'model': model,
      if (serialNumber != null && serialNumber!.isNotEmpty)
        'serialNumber': serialNumber,
      if (purchaseDate != null)
        'purchaseDate': Timestamp.fromDate(purchaseDate!),
      if (purchaseCost != null) 'purchaseCost': purchaseCost,
      if (supplierName != null && supplierName!.isNotEmpty)
        'supplierName': supplierName,
      if (location != null && location!.isNotEmpty) 'location': location,
      if (depreciationRatePercent != null)
        'depreciationRatePercent': depreciationRatePercent,
      if (lastMaintenanceDate != null)
        'lastMaintenanceDate': Timestamp.fromDate(lastMaintenanceDate!),
      if (nextMaintenanceDueDate != null)
        'nextMaintenanceDueDate': Timestamp.fromDate(nextMaintenanceDueDate!),
      if (maintenanceIntervalDays != null)
        'maintenanceIntervalDays': maintenanceIntervalDays,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Equipment toEntity() => Equipment(
        id: id,
        equipmentNumber: equipmentNumber,
        factoryId: factoryId,
        name: name,
        category: category,
        status: status,
        brand: brand,
        model: model,
        serialNumber: serialNumber,
        purchaseDate: purchaseDate,
        purchaseCost: purchaseCost,
        supplierName: supplierName,
        location: location,
        depreciationRatePercent: depreciationRatePercent,
        lastMaintenanceDate: lastMaintenanceDate,
        nextMaintenanceDueDate: nextMaintenanceDueDate,
        maintenanceIntervalDays: maintenanceIntervalDays,
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory EquipmentModel.fromEntity(Equipment equipment) => EquipmentModel(
        id: equipment.id,
        equipmentNumber: equipment.equipmentNumber,
        factoryId: equipment.factoryId,
        name: equipment.name,
        category: equipment.category,
        status: equipment.status,
        brand: equipment.brand,
        model: equipment.model,
        serialNumber: equipment.serialNumber,
        purchaseDate: equipment.purchaseDate,
        purchaseCost: equipment.purchaseCost,
        supplierName: equipment.supplierName,
        location: equipment.location,
        depreciationRatePercent: equipment.depreciationRatePercent,
        lastMaintenanceDate: equipment.lastMaintenanceDate,
        nextMaintenanceDueDate: equipment.nextMaintenanceDueDate,
        maintenanceIntervalDays: equipment.maintenanceIntervalDays,
        notes: equipment.notes,
        createdAt: equipment.createdAt,
        updatedAt: equipment.updatedAt,
      );
}
