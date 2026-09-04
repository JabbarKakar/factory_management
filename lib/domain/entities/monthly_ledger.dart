import 'package:equatable/equatable.dart';

import '../enums/labour_enums.dart';

class MonthlyLedger extends Equatable {
  const MonthlyLedger({
    required this.id,
    required this.employeeId,
    required this.factoryId,
    required this.month,
    required this.year,
    required this.wageType,
    required this.totalPayable,
    required this.totalPaid,
    required this.remainingBalance,
    required this.status,
    required this.createdAt,
    this.baseRate = 0,
    this.openingBalance = 0,
    this.adjustments = 0,
    this.billableDays = 0,
    this.isOverpaid = false,
    this.closedAt,
    this.closedBy,
    this.rolloverAction,
    this.updatedAt,
  });

  /// Document id / month key, format `yyyy-MM`.
  final String id;
  final String employeeId;
  final String factoryId;
  final int month;
  final int year;
  final SalaryType wageType;
  final double baseRate;
  final double openingBalance;
  final double adjustments;
  final double billableDays;
  final double totalPayable;
  final double totalPaid;
  final double remainingBalance;
  final MonthlyLedgerStatus status;
  final bool isOverpaid;
  final DateTime? closedAt;
  final String? closedBy;
  final WageCycleRolloverAction? rolloverAction;
  final DateTime createdAt;
  final DateTime? updatedAt;

  String get monthKey => id;

  bool get isClosed => status == MonthlyLedgerStatus.closed;

  bool get canRecordPayment => !isClosed;

  bool get isSettled =>
      status == MonthlyLedgerStatus.settled || remainingBalance.abs() < 0.005;

  MonthlyLedger copyWith({
    String? id,
    String? employeeId,
    String? factoryId,
    int? month,
    int? year,
    SalaryType? wageType,
    double? baseRate,
    double? openingBalance,
    double? adjustments,
    double? billableDays,
    double? totalPayable,
    double? totalPaid,
    double? remainingBalance,
    MonthlyLedgerStatus? status,
    bool? isOverpaid,
    DateTime? closedAt,
    String? closedBy,
    WageCycleRolloverAction? rolloverAction,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearClosedAt = false,
    bool clearClosedBy = false,
    bool clearRolloverAction = false,
  }) {
    return MonthlyLedger(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      factoryId: factoryId ?? this.factoryId,
      month: month ?? this.month,
      year: year ?? this.year,
      wageType: wageType ?? this.wageType,
      baseRate: baseRate ?? this.baseRate,
      openingBalance: openingBalance ?? this.openingBalance,
      adjustments: adjustments ?? this.adjustments,
      billableDays: billableDays ?? this.billableDays,
      totalPayable: totalPayable ?? this.totalPayable,
      totalPaid: totalPaid ?? this.totalPaid,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      status: status ?? this.status,
      isOverpaid: isOverpaid ?? this.isOverpaid,
      closedAt: clearClosedAt ? null : (closedAt ?? this.closedAt),
      closedBy: clearClosedBy ? null : (closedBy ?? this.closedBy),
      rolloverAction:
          clearRolloverAction ? null : (rolloverAction ?? this.rolloverAction),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        employeeId,
        factoryId,
        month,
        year,
        wageType,
        baseRate,
        openingBalance,
        adjustments,
        billableDays,
        totalPayable,
        totalPaid,
        remainingBalance,
        status,
        isOverpaid,
        closedAt,
        closedBy,
        rolloverAction,
        createdAt,
        updatedAt,
      ];
}
