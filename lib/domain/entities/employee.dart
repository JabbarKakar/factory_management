import 'package:equatable/equatable.dart';

import '../enums/labour_enums.dart';

class Employee extends Equatable {
  const Employee({
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

  bool get isActive => status == EmployeeStatus.active;

  String get rateLabel => switch (salaryType) {
        SalaryType.monthlyFixed => 'PKR / month',
        SalaryType.dailyRate => 'PKR / day',
        SalaryType.perPieceRate => 'PKR / piece',
      };

  Employee copyWith({
    String? id,
    String? employeeNumber,
    String? factoryId,
    String? fullName,
    String? phone,
    String? cnic,
    WorkerCategory? workerCategory,
    EmploymentType? employmentType,
    SalaryType? salaryType,
    double? rateAmount,
    DateTime? joinDate,
    EmployeeStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      factoryId: factoryId ?? this.factoryId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      cnic: cnic ?? this.cnic,
      workerCategory: workerCategory ?? this.workerCategory,
      employmentType: employmentType ?? this.employmentType,
      salaryType: salaryType ?? this.salaryType,
      rateAmount: rateAmount ?? this.rateAmount,
      joinDate: joinDate ?? this.joinDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        employeeNumber,
        factoryId,
        fullName,
        phone,
        cnic,
        workerCategory,
        employmentType,
        salaryType,
        rateAmount,
        joinDate,
        status,
        notes,
        createdAt,
        updatedAt,
      ];
}
