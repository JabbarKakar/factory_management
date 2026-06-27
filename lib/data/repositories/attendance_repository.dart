import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/date_keys.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/enums/labour_enums.dart';
import '../models/attendance_record_model.dart';

class AttendanceRepository {
  AttendanceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get collection =>
      _firestore.collection('attendanceRecords');

  String _docId({
    required String factoryId,
    required String employeeId,
    required String dateKey,
  }) {
    return '${factoryId}_${dateKey}_$employeeId';
  }

  Stream<List<AttendanceRecord>> watchForDate({
    required String factoryId,
    required DateTime date,
  }) {
    final dateKey = DateKeys.fromDate(date);
    return collection
        .where('factoryId', isEqualTo: factoryId)
        .where('dateKey', isEqualTo: dateKey)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs
            .map(
              (doc) => AttendanceRecordModel.fromFirestore(doc.id, doc.data()),
            )
            .map((model) => model.toEntity())
            .toList();
      },
    );
  }

  Stream<List<AttendanceRecord>> watchForEmployee({
    required String factoryId,
    required String employeeId,
  }) {
    return collection
        .where('factoryId', isEqualTo: factoryId)
        .where('employeeId', isEqualTo: employeeId)
        .snapshots()
        .map(
      (snapshot) {
        final records = snapshot.docs
            .map(
              (doc) => AttendanceRecordModel.fromFirestore(doc.id, doc.data()),
            )
            .map((model) => model.toEntity())
            .toList();
        records.sort((a, b) => b.dateKey.compareTo(a.dateKey));
        return records.take(30).toList();
      },
    );
  }

  Future<AttendanceRecord> upsertAttendance({
    required String factoryId,
    required String employeeId,
    required DateTime date,
    required AttendanceStatus status,
    AttendanceShift? shift,
    String? notes,
  }) async {
    final dateOnly = DateKeys.dateOnly(date);
    final dateKey = DateKeys.fromDate(dateOnly);
    final docId = _docId(
      factoryId: factoryId,
      employeeId: employeeId,
      dateKey: dateKey,
    );

    final existing = await collection.doc(docId).get();
    final isCreate = !existing.exists;

    final record = AttendanceRecord(
      id: docId,
      factoryId: factoryId,
      employeeId: employeeId,
      dateKey: dateKey,
      attendanceDate: dateOnly,
      status: status,
      shift: shift,
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      createdAt: isCreate
          ? DateTime.now()
          : AttendanceRecordModel.fromFirestore(
              docId,
              existing.data()!,
            ).createdAt,
    );

    final model = AttendanceRecordModel.fromEntity(record);
    await collection.doc(docId).set(
          model.toFirestore(isCreate: isCreate),
          SetOptions(merge: !isCreate),
        );

    final saved = await collection.doc(docId).get();
    return AttendanceRecordModel.fromFirestore(docId, saved.data()!).toEntity();
  }

  Future<void> markAllPresent({
    required String factoryId,
    required List<String> employeeIds,
    required DateTime date,
    AttendanceShift shift = AttendanceShift.morning,
  }) async {
    final batch = _firestore.batch();
    final dateOnly = DateKeys.dateOnly(date);
    final dateKey = DateKeys.fromDate(dateOnly);

    for (final employeeId in employeeIds) {
      final docId = _docId(
        factoryId: factoryId,
        employeeId: employeeId,
        dateKey: dateKey,
      );
      final existing = await collection.doc(docId).get();
      final isCreate = !existing.exists;

      final record = AttendanceRecord(
        id: docId,
        factoryId: factoryId,
        employeeId: employeeId,
        dateKey: dateKey,
        attendanceDate: dateOnly,
        status: AttendanceStatus.present,
        shift: shift,
        createdAt: isCreate
            ? DateTime.now()
            : AttendanceRecordModel.fromFirestore(
                docId,
                existing.data()!,
              ).createdAt,
      );

      batch.set(
        collection.doc(docId),
        AttendanceRecordModel.fromEntity(record).toFirestore(isCreate: isCreate),
        SetOptions(merge: !isCreate),
      );
    }

    await batch.commit();
  }
}
