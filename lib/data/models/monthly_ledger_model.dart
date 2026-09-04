import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/date_keys.dart';
import '../../domain/entities/monthly_ledger.dart';
import '../../domain/enums/labour_enums.dart';

class MonthlyLedgerModel {
  const MonthlyLedgerModel({
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

  factory MonthlyLedgerModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final parsed = DateKeys.monthStart(id);
    return MonthlyLedgerModel(
      id: id,
      employeeId: data['employeeId'] as String? ?? '',
      factoryId: data['factoryId'] as String? ?? 'default',
      month: (data['month'] as num?)?.toInt() ?? parsed.month,
      year: (data['year'] as num?)?.toInt() ?? parsed.year,
      wageType: SalaryType.fromString(
        data['wageType'] as String? ?? data['salaryType'] as String?,
      ),
      baseRate: (data['baseRate'] as num?)?.toDouble() ?? 0,
      openingBalance: (data['openingBalance'] as num?)?.toDouble() ?? 0,
      adjustments: (data['adjustments'] as num?)?.toDouble() ?? 0,
      billableDays: (data['billableDays'] as num?)?.toDouble() ?? 0,
      totalPayable: (data['totalPayable'] as num?)?.toDouble() ?? 0,
      totalPaid: (data['totalPaid'] as num?)?.toDouble() ?? 0,
      remainingBalance: (data['remainingBalance'] as num?)?.toDouble() ?? 0,
      status: MonthlyLedgerStatus.fromString(data['status'] as String?),
      isOverpaid: data['isOverpaid'] as bool? ?? false,
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
      closedBy: data['closedBy'] as String?,
      rolloverAction: _rolloverFrom(data['rolloverAction'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'id': id,
      'employeeId': employeeId,
      'factoryId': factoryId,
      'month': month,
      'year': year,
      'wageType': wageType.firestoreValue,
      'baseRate': baseRate,
      'openingBalance': openingBalance,
      'adjustments': adjustments,
      'billableDays': billableDays,
      'totalPayable': totalPayable,
      'totalPaid': totalPaid,
      'remainingBalance': remainingBalance,
      'status': status.firestoreValue,
      'isOverpaid': isOverpaid,
      if (closedAt != null) 'closedAt': Timestamp.fromDate(closedAt!),
      if (closedBy != null && closedBy!.isNotEmpty) 'closedBy': closedBy,
      if (rolloverAction != null)
        'rolloverAction': rolloverAction!.firestoreValue,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  MonthlyLedger toEntity() => MonthlyLedger(
        id: id,
        employeeId: employeeId,
        factoryId: factoryId,
        month: month,
        year: year,
        wageType: wageType,
        baseRate: baseRate,
        openingBalance: openingBalance,
        adjustments: adjustments,
        billableDays: billableDays,
        totalPayable: totalPayable,
        totalPaid: totalPaid,
        remainingBalance: remainingBalance,
        status: status,
        isOverpaid: isOverpaid,
        closedAt: closedAt,
        closedBy: closedBy,
        rolloverAction: rolloverAction,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory MonthlyLedgerModel.fromEntity(MonthlyLedger ledger) =>
      MonthlyLedgerModel(
        id: ledger.id,
        employeeId: ledger.employeeId,
        factoryId: ledger.factoryId,
        month: ledger.month,
        year: ledger.year,
        wageType: ledger.wageType,
        baseRate: ledger.baseRate,
        openingBalance: ledger.openingBalance,
        adjustments: ledger.adjustments,
        billableDays: ledger.billableDays,
        totalPayable: ledger.totalPayable,
        totalPaid: ledger.totalPaid,
        remainingBalance: ledger.remainingBalance,
        status: ledger.status,
        isOverpaid: ledger.isOverpaid,
        closedAt: ledger.closedAt,
        closedBy: ledger.closedBy,
        rolloverAction: ledger.rolloverAction,
        createdAt: ledger.createdAt,
        updatedAt: ledger.updatedAt,
      );

  static WageCycleRolloverAction? _rolloverFrom(String? value) {
    if (value == null || value.isEmpty) return null;
    return WageCycleRolloverAction.values.firstWhere(
      (action) => action.name == value,
      orElse: () => WageCycleRolloverAction.carryForward,
    );
  }
}
