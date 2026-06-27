import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/attendance_record.dart';
import '../../domain/enums/labour_enums.dart';

class AttendanceRecordModel {
  const AttendanceRecordModel({
    required this.id,
    required this.factoryId,
    required this.employeeId,
    required this.dateKey,
    required this.attendanceDate,
    required this.status,
    required this.createdAt,
    this.shift,
    this.notes,
    this.updatedAt,
  });

  final String id;
  final String factoryId;
  final String employeeId;
  final String dateKey;
  final DateTime attendanceDate;
  final AttendanceStatus status;
  final AttendanceShift? shift;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory AttendanceRecordModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return AttendanceRecordModel(
      id: id,
      factoryId: data['factoryId'] as String? ?? 'default',
      employeeId: data['employeeId'] as String? ?? '',
      dateKey: data['dateKey'] as String? ?? '',
      attendanceDate:
          (data['attendanceDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: AttendanceStatus.fromString(data['status'] as String?),
      shift: data['shift'] == null
          ? null
          : AttendanceShift.fromString(data['shift'] as String?),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'factoryId': factoryId,
      'employeeId': employeeId,
      'dateKey': dateKey,
      'attendanceDate': Timestamp.fromDate(attendanceDate),
      'status': status.firestoreValue,
      if (shift != null) 'shift': shift!.firestoreValue,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AttendanceRecord toEntity() => AttendanceRecord(
        id: id,
        factoryId: factoryId,
        employeeId: employeeId,
        dateKey: dateKey,
        attendanceDate: attendanceDate,
        status: status,
        shift: shift,
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory AttendanceRecordModel.fromEntity(AttendanceRecord record) =>
      AttendanceRecordModel(
        id: record.id,
        factoryId: record.factoryId,
        employeeId: record.employeeId,
        dateKey: record.dateKey,
        attendanceDate: record.attendanceDate,
        status: record.status,
        shift: record.shift,
        notes: record.notes,
        createdAt: record.createdAt,
        updatedAt: record.updatedAt,
      );
}
