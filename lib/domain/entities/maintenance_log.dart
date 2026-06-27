import 'package:equatable/equatable.dart';

import '../enums/equipment_enums.dart';

class MaintenanceLog extends Equatable {
  const MaintenanceLog({
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

  MaintenanceLog copyWith({
    String? id,
    String? equipmentId,
    String? factoryId,
    DateTime? maintenanceDate,
    MaintenanceType? maintenanceType,
    String? description,
    double? cost,
    MaintenancePerformedBy? performedBy,
    String? performedByName,
    double? downtimeHours,
    DateTime? nextDueDate,
    bool clearNextDueDate = false,
    EquipmentStatus? equipmentStatusAfter,
    bool clearEquipmentStatusAfter = false,
    DateTime? createdAt,
  }) {
    return MaintenanceLog(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      factoryId: factoryId ?? this.factoryId,
      maintenanceDate: maintenanceDate ?? this.maintenanceDate,
      maintenanceType: maintenanceType ?? this.maintenanceType,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      performedBy: performedBy ?? this.performedBy,
      performedByName: performedByName ?? this.performedByName,
      downtimeHours: downtimeHours ?? this.downtimeHours,
      nextDueDate:
          clearNextDueDate ? null : (nextDueDate ?? this.nextDueDate),
      equipmentStatusAfter: clearEquipmentStatusAfter
          ? null
          : (equipmentStatusAfter ?? this.equipmentStatusAfter),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        equipmentId,
        factoryId,
        maintenanceDate,
        maintenanceType,
        description,
        cost,
        performedBy,
        performedByName,
        downtimeHours,
        nextDueDate,
        equipmentStatusAfter,
        createdAt,
      ];
}
