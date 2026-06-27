import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/employee.dart';
import '../../domain/enums/labour_enums.dart';

class EmployeeModel {
  const EmployeeModel({
    required this.id,
    required this.employeeNumber,
    required this.factoryId,
    required this.fullName,
    required this.phone,
    required this.workerCategory,
    required this.employmentType,
    required this.salaryType,
    required this.rateAmount,
    required this.joinDate,
    required this.status,
    required this.createdAt,
    this.cnic,
    this.notes,
    this.updatedAt,
  });

  final String id;
  final String employeeNumber;
  final String factoryId;
  final String fullName;
  final String phone;
  final String? cnic;
  final WorkerCategory workerCategory;
  final EmploymentType employmentType;
  final SalaryType salaryType;
  final double rateAmount;
  final DateTime joinDate;
  final EmployeeStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory EmployeeModel.fromFirestore(String id, Map<String, dynamic> data) {
    return EmployeeModel(
      id: id,
      employeeNumber: data['employeeNumber'] as String? ?? '',
      factoryId: data['factoryId'] as String? ?? 'default',
      fullName: data['fullName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      cnic: data['cnic'] as String?,
      workerCategory:
          WorkerCategory.fromString(data['workerCategory'] as String?),
      employmentType:
          EmploymentType.fromString(data['employmentType'] as String?),
      salaryType: SalaryType.fromString(data['salaryType'] as String?),
      rateAmount: (data['rateAmount'] as num?)?.toDouble() ?? 0,
      joinDate: (data['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: EmployeeStatus.fromString(data['status'] as String?),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'employeeNumber': employeeNumber,
      'factoryId': factoryId,
      'fullName': fullName,
      'phone': phone,
      if (cnic != null && cnic!.isNotEmpty) 'cnic': cnic,
      'workerCategory': workerCategory.firestoreValue,
      'employmentType': employmentType.firestoreValue,
      'salaryType': salaryType.firestoreValue,
      'rateAmount': rateAmount,
      'joinDate': Timestamp.fromDate(joinDate),
      'status': status.firestoreValue,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Employee toEntity() => Employee(
        id: id,
        employeeNumber: employeeNumber,
        factoryId: factoryId,
        fullName: fullName,
        phone: phone,
        cnic: cnic,
        workerCategory: workerCategory,
        employmentType: employmentType,
        salaryType: salaryType,
        rateAmount: rateAmount,
        joinDate: joinDate,
        status: status,
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory EmployeeModel.fromEntity(Employee employee) => EmployeeModel(
        id: employee.id,
        employeeNumber: employee.employeeNumber,
        factoryId: employee.factoryId,
        fullName: employee.fullName,
        phone: employee.phone,
        cnic: employee.cnic,
        workerCategory: employee.workerCategory,
        employmentType: employee.employmentType,
        salaryType: employee.salaryType,
        rateAmount: employee.rateAmount,
        joinDate: employee.joinDate,
        status: employee.status,
        notes: employee.notes,
        createdAt: employee.createdAt,
        updatedAt: employee.updatedAt,
      );
}
