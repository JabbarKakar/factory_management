import 'package:equatable/equatable.dart';

import '../enums/labour_enums.dart';

class AttendanceRecord extends Equatable {
  const AttendanceRecord({
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

  AttendanceRecord copyWith({
    String? id,
    String? factoryId,
    String? employeeId,
    String? dateKey,
    DateTime? attendanceDate,
    AttendanceStatus? status,
    AttendanceShift? shift,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      factoryId: factoryId ?? this.factoryId,
      employeeId: employeeId ?? this.employeeId,
      dateKey: dateKey ?? this.dateKey,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      status: status ?? this.status,
      shift: shift ?? this.shift,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        factoryId,
        employeeId,
        dateKey,
        attendanceDate,
        status,
        shift,
        notes,
        createdAt,
        updatedAt,
      ];
}
