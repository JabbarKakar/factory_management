import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/equipment.dart';
import '../../domain/entities/maintenance_log.dart';
import '../models/equipment_model.dart';
import '../models/maintenance_log_model.dart';

class EquipmentException implements Exception {
  const EquipmentException(this.message);

  final String message;

  @override
  String toString() => message;
}

class EquipmentRepository {
  EquipmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _equipmentCollection =>
      _firestore.collection('equipment');

  CollectionReference<Map<String, dynamic>> get _maintenanceCollection =>
      _firestore.collection('maintenanceLogs');

  Stream<List<Equipment>> watchEquipment(String factoryId) {
    return _equipmentCollection
        .where('factoryId', isEqualTo: factoryId)
        .snapshots()
        .map(
      (snapshot) {
        final items = snapshot.docs
            .map((doc) => EquipmentModel.fromFirestore(doc.id, doc.data()))
            .map((model) => model.toEntity())
            .toList();
        items.sort((a, b) => a.name.compareTo(b.name));
        return items;
      },
    );
  }

  Stream<Equipment?> watchEquipmentItem(String id) {
    return _equipmentCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return EquipmentModel.fromFirestore(doc.id, doc.data()!).toEntity();
    });
  }

  Future<Equipment?> getEquipment(String id) async {
    final doc = await _equipmentCollection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return EquipmentModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Stream<List<MaintenanceLog>> watchMaintenanceLogs(String equipmentId) {
    return _maintenanceCollection
        .where('equipmentId', isEqualTo: equipmentId)
        .snapshots()
        .map(
      (snapshot) {
        final logs = snapshot.docs
            .map((doc) => MaintenanceLogModel.fromFirestore(doc.id, doc.data()))
            .map((model) => model.toEntity())
            .toList();
        logs.sort((a, b) => b.maintenanceDate.compareTo(a.maintenanceDate));
        return logs;
      },
    );
  }

  Future<Equipment> createEquipment(Equipment equipment) async {
    if (equipment.name.trim().isEmpty) {
      throw const EquipmentException('Equipment name is required.');
    }

    final id = equipment.id.isEmpty ? _uuid.v4() : equipment.id;
    final equipmentNumber = equipment.equipmentNumber.isEmpty
        ? await _generateEquipmentNumber(equipment.factoryId)
        : equipment.equipmentNumber;

    final model = EquipmentModel.fromEntity(
      equipment.copyWith(id: id, equipmentNumber: equipmentNumber),
    );

    await _equipmentCollection.doc(id).set(model.toFirestore(isCreate: true));
    final created = await getEquipment(id);
    return created ?? model.toEntity();
  }

  Future<void> updateEquipment(Equipment equipment) async {
    if (equipment.name.trim().isEmpty) {
      throw const EquipmentException('Equipment name is required.');
    }

    final model = EquipmentModel.fromEntity(equipment);
    await _equipmentCollection.doc(equipment.id).update(model.toFirestore());
  }

  Future<void> deleteEquipment(String id) async {
    final logs = await _maintenanceCollection
        .where('equipmentId', isEqualTo: id)
        .get();
    final batch = _firestore.batch();
    for (final doc in logs.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_equipmentCollection.doc(id));
    await batch.commit();
  }

  Future<MaintenanceLog> createMaintenanceLog(MaintenanceLog log) async {
    if (log.description.trim().isEmpty) {
      throw const EquipmentException('Maintenance description is required.');
    }

    final equipment = await getEquipment(log.equipmentId);
    if (equipment == null) {
      throw const EquipmentException('Equipment not found.');
    }

    final id = log.id.isEmpty ? _uuid.v4() : log.id;
    final model = MaintenanceLogModel.fromEntity(log.copyWith(id: id));

    await _maintenanceCollection.doc(id).set(model.toFirestore(isCreate: true));

    final nextDue = log.nextDueDate ??
        (equipment.maintenanceIntervalDays != null
            ? log.maintenanceDate.add(
                Duration(days: equipment.maintenanceIntervalDays!),
              )
            : null);

    final updatedEquipment = equipment.copyWith(
      lastMaintenanceDate: log.maintenanceDate,
      nextMaintenanceDueDate: nextDue,
      status: log.equipmentStatusAfter ?? equipment.status,
    );
    await updateEquipment(updatedEquipment);

    final createdDoc = await _maintenanceCollection.doc(id).get();
    if (!createdDoc.exists || createdDoc.data() == null) {
      return model.toEntity();
    }
    return MaintenanceLogModel.fromFirestore(id, createdDoc.data()!).toEntity();
  }

  Future<String> _generateEquipmentNumber(String factoryId) async {
    final year = DateTime.now().year;
    final snapshot =
        await _equipmentCollection.where('factoryId', isEqualTo: factoryId).get();
    final count = snapshot.docs.length + 1;
    return 'EQP-$year-${count.toString().padLeft(4, '0')}';
  }
}
