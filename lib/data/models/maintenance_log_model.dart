import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/maintenance_log.dart';
import '../../domain/enums/equipment_enums.dart';

class MaintenanceLogModel {
  const MaintenanceLogModel({
    required this.id,
    required this.equipmentId,
    required this.factoryId,
    required this.maintenanceDate,
    required this.maintenanceType,
    required this.description,
    required this.cost,
    required this.performedBy,
    required this.createdAt,
    this.performedByName,
    this.downtimeHours,
    this.nextDueDate,
    this.equipmentStatusAfter,
  });

  final String id;
  final String equipmentId;
  final String factoryId;
  final DateTime maintenanceDate;
  final MaintenanceType maintenanceType;
  final String description;
  final double cost;
  final MaintenancePerformedBy performedBy;
  final String? performedByName;
  final double? downtimeHours;
  final DateTime? nextDueDate;
  final EquipmentStatus? equipmentStatusAfter;
  final DateTime createdAt;

  factory MaintenanceLogModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return MaintenanceLogModel(
      id: id,
      equipmentId: data['equipmentId'] as String? ?? '',
      factoryId: data['factoryId'] as String? ?? 'default',
      maintenanceDate:
          (data['maintenanceDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maintenanceType:
          MaintenanceType.fromString(data['maintenanceType'] as String?),
      description: data['description'] as String? ?? '',
      cost: (data['cost'] as num?)?.toDouble() ?? 0,
      performedBy:
          MaintenancePerformedBy.fromString(data['performedBy'] as String?),
      performedByName: data['performedByName'] as String?,
      downtimeHours: (data['downtimeHours'] as num?)?.toDouble(),
      nextDueDate: (data['nextDueDate'] as Timestamp?)?.toDate(),
      equipmentStatusAfter: data['equipmentStatusAfter'] == null
          ? null
          : EquipmentStatus.fromString(data['equipmentStatusAfter'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'equipmentId': equipmentId,
      'factoryId': factoryId,
      'maintenanceDate': Timestamp.fromDate(maintenanceDate),
      'maintenanceType': maintenanceType.firestoreValue,
      'description': description,
      'cost': cost,
      'performedBy': performedBy.firestoreValue,
      if (performedByName != null && performedByName!.isNotEmpty)
        'performedByName': performedByName,
      if (downtimeHours != null) 'downtimeHours': downtimeHours,
      if (nextDueDate != null)
        'nextDueDate': Timestamp.fromDate(nextDueDate!),
      if (equipmentStatusAfter != null)
        'equipmentStatusAfter': equipmentStatusAfter!.firestoreValue,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  MaintenanceLog toEntity() => MaintenanceLog(
        id: id,
        equipmentId: equipmentId,
        factoryId: factoryId,
        maintenanceDate: maintenanceDate,
        maintenanceType: maintenanceType,
        description: description,
        cost: cost,
        performedBy: performedBy,
        performedByName: performedByName,
        downtimeHours: downtimeHours,
        nextDueDate: nextDueDate,
        equipmentStatusAfter: equipmentStatusAfter,
        createdAt: createdAt,
      );

  factory MaintenanceLogModel.fromEntity(MaintenanceLog log) =>
      MaintenanceLogModel(
        id: log.id,
        equipmentId: log.equipmentId,
        factoryId: log.factoryId,
        maintenanceDate: log.maintenanceDate,
        maintenanceType: log.maintenanceType,
        description: log.description,
        cost: log.cost,
        performedBy: log.performedBy,
        performedByName: log.performedByName,
        downtimeHours: log.downtimeHours,
        nextDueDate: log.nextDueDate,
        equipmentStatusAfter: log.equipmentStatusAfter,
        createdAt: log.createdAt,
      );
}
