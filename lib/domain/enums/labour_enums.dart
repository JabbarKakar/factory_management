import 'production_enums.dart';

enum WorkerCategory {
  machineOperator,
  helper,
  polishWorker,
  loadingWorker,
  craneOperator,
  forkliftDriver,
  supervisor,
  qualityInspector,
  driver,
  mechanic,
  other;

  String get firestoreValue => name;

  String get label => switch (this) {
        WorkerCategory.machineOperator => 'Machine Operator',
        WorkerCategory.helper => 'Helper / Assistant',
        WorkerCategory.polishWorker => 'Polish Worker',
        WorkerCategory.loadingWorker => 'Loading / Unloading',
        WorkerCategory.craneOperator => 'Crane Operator',
        WorkerCategory.forkliftDriver => 'Forklift Driver',
        WorkerCategory.supervisor => 'Supervisor',
        WorkerCategory.qualityInspector => 'Quality Inspector',
        WorkerCategory.driver => 'Driver',
        WorkerCategory.mechanic => 'Mechanic',
        WorkerCategory.other => 'Other',
      };

  static WorkerCategory fromString(String? value) {
    return WorkerCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => WorkerCategory.helper,
    );
  }
}

enum EmploymentType {
  permanent,
  dailyWage,
  contract;

  String get firestoreValue => name;

  String get label => switch (this) {
        EmploymentType.permanent => 'Permanent',
        EmploymentType.dailyWage => 'Daily Wage',
        EmploymentType.contract => 'Contract',
      };

  static EmploymentType fromString(String? value) {
    return EmploymentType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => EmploymentType.dailyWage,
    );
  }
}

enum SalaryType {
  monthlyFixed,
  dailyRate,
  perPieceRate;

  String get firestoreValue => name;

  String get label => switch (this) {
        SalaryType.monthlyFixed => 'Monthly Fixed',
        SalaryType.dailyRate => 'Daily Rate',
        SalaryType.perPieceRate => 'Per Piece Rate',
      };

  static SalaryType fromString(String? value) {
    return SalaryType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => SalaryType.dailyRate,
    );
  }
}

enum EmployeeStatus {
  active,
  inactive;

  String get firestoreValue => name;

  String get label => switch (this) {
        EmployeeStatus.active => 'Active',
        EmployeeStatus.inactive => 'Inactive',
      };

  static EmployeeStatus fromString(String? value) {
    return EmployeeStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => EmployeeStatus.active,
    );
  }
}

enum EmployeeListFilter {
  all,
  active,
  inactive;

  String get label => switch (this) {
        EmployeeListFilter.all => 'All',
        EmployeeListFilter.active => 'Active',
        EmployeeListFilter.inactive => 'Inactive',
      };
}

enum AttendanceStatus {
  present,
  absent,
  halfDay,
  leave,
  holiday;

  String get firestoreValue => name;

  String get label => switch (this) {
        AttendanceStatus.present => 'Present',
        AttendanceStatus.absent => 'Absent',
        AttendanceStatus.halfDay => 'Half Day',
        AttendanceStatus.leave => 'Leave',
        AttendanceStatus.holiday => 'Holiday',
      };

  static AttendanceStatus fromString(String? value) {
    return AttendanceStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => AttendanceStatus.present,
    );
  }
}

typedef AttendanceShift = ProductionShift;
