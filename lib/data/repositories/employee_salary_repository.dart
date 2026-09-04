import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/observability/tracked_firestore.dart';
import '../../core/utils/date_keys.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/monthly_ledger.dart';
import '../../domain/entities/wage_payment.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/labour_enums.dart';
import '../models/employee_model.dart';
import '../models/monthly_ledger_model.dart';
import '../models/wage_payment_model.dart';
import '../services/wage_payable_calculator.dart';
import 'attendance_repository.dart';
import 'employee_repository.dart';

class EmployeeSalaryRepository {
  EmployeeSalaryRepository({
    required EmployeeRepository employeeRepository,
    required AttendanceRepository attendanceRepository,
    FirebaseFirestore? firestore,
  })  : _employeeRepository = employeeRepository,
        _attendanceRepository = attendanceRepository,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final EmployeeRepository _employeeRepository;
  final AttendanceRepository _attendanceRepository;
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _ledgers(String employeeId) {
    return trackedCollection(_firestore, 'employees')
        .doc(employeeId)
        .collection('monthly_ledgers');
  }

  CollectionReference<Map<String, dynamic>> _payments({
    required String employeeId,
    required String monthKey,
  }) {
    return _ledgers(employeeId).doc(monthKey).collection('payments');
  }

  DocumentReference<Map<String, dynamic>> _employeeDoc(String employeeId) {
    return trackedCollection(_firestore, 'employees').doc(employeeId);
  }

  Stream<MonthlyLedger?> watchLedger({
    required String employeeId,
    required String monthKey,
  }) {
    return _ledgers(employeeId).doc(monthKey).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return MonthlyLedgerModel.fromFirestore(doc.id, doc.data()!).toEntity();
    });
  }

  Future<MonthlyLedger?> getLedger({
    required String employeeId,
    required String monthKey,
  }) async {
    final doc = await _ledgers(employeeId).doc(monthKey).get();
    if (!doc.exists || doc.data() == null) return null;
    return MonthlyLedgerModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Stream<List<MonthlyLedger>> watchLedgers({
    required String employeeId,
    required String factoryId,
  }) {
    return _ledgers(employeeId)
        .where('factoryId', isEqualTo: factoryId)
        .snapshots()
        .map((snapshot) {
      final ledgers = snapshot.docs
          .map((doc) => MonthlyLedgerModel.fromFirestore(doc.id, doc.data()))
          .map((model) => model.toEntity())
          .toList();
      ledgers.sort((a, b) => b.id.compareTo(a.id));
      return ledgers;
    });
  }

  Stream<List<WagePayment>> watchPayments({
    required String employeeId,
    required String monthKey,
    required String factoryId,
  }) {
    return _payments(employeeId: employeeId, monthKey: monthKey)
        .where('factoryId', isEqualTo: factoryId)
        .snapshots()
        .map((snapshot) {
      final payments = snapshot.docs
          .map((doc) => WagePaymentModel.fromFirestore(doc.id, doc.data()))
          .map((model) => model.toEntity())
          .toList();
      payments.sort((a, b) {
        final byDate = b.paymentDate.compareTo(a.paymentDate);
        if (byDate != 0) return byDate;
        return b.createdAt.compareTo(a.createdAt);
      });
      return payments;
    });
  }

  Future<MonthlyLedger> ensureOpenLedger({
    required String employeeId,
    String? monthKey,
  }) async {
    final employee = await _employeeRepository.getEmployee(employeeId);
    if (employee == null) {
      throw StateError('Worker not found.');
    }

    final key = monthKey ??
        employee.activeMonthKey ??
        DateKeys.monthKey(DateTime.now());
    final billableDays = await _billableDaysFor(employee, key);

    return _firestore.runTransaction<MonthlyLedger>((transaction) async {
      final employeeRef = _employeeDoc(employeeId);
      final ledgerRef = _ledgers(employeeId).doc(key);
      final employeeSnap = await transaction.get(employeeRef);
      final ledgerSnap = await transaction.get(ledgerRef);

      if (!employeeSnap.exists || employeeSnap.data() == null) {
        throw StateError('Worker not found.');
      }

      if (ledgerSnap.exists && ledgerSnap.data() != null) {
        return MonthlyLedgerModel.fromFirestore(
          ledgerSnap.id,
          ledgerSnap.data()!,
        ).toEntity();
      }

      final liveEmployee = EmployeeModel.fromFirestore(
        employeeSnap.id,
        employeeSnap.data()!,
      ).toEntity();
      final ledger = _buildNewLedger(
        employee: liveEmployee,
        monthKey: key,
        openingBalance: 0,
        billableDays: billableDays,
      );

      transaction.set(
        ledgerRef,
        MonthlyLedgerModel.fromEntity(ledger).toFirestore(isCreate: true),
      );
      transaction.update(employeeRef, {
        'activeMonthKey': key,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return ledger;
    });
  }

  Future<WagePayment> recordWorkerPayment({
    required String employeeId,
    required String monthKey,
    required double amount,
    required String paymentMethod,
    required String recordedBy,
    String? notes,
    String? recordedByName,
    DateTime? paymentDate,
  }) async {
    final roundedAmount = WagePayableCalculator.roundMoney(amount);
    if (roundedAmount <= 0) {
      throw StateError('Payment amount must be greater than zero.');
    }
    if (recordedBy.trim().isEmpty) {
      throw StateError('A signed-in user is required to record a payment.');
    }

    final employee = await _employeeRepository.getEmployee(employeeId);
    if (employee == null) {
      throw StateError('Worker not found.');
    }

    final billableDays = await _billableDaysFor(employee, monthKey);
    final method = PaymentMethod.fromString(paymentMethod);
    final paymentId = _uuid.v4();
    final when = paymentDate ?? DateTime.now();

    return _firestore.runTransaction<WagePayment>((transaction) async {
      final employeeRef = _employeeDoc(employeeId);
      final ledgerRef = _ledgers(employeeId).doc(monthKey);
      final paymentRef =
          _payments(employeeId: employeeId, monthKey: monthKey).doc(paymentId);

      final employeeSnap = await transaction.get(employeeRef);
      final ledgerSnap = await transaction.get(ledgerRef);

      if (!employeeSnap.exists || employeeSnap.data() == null) {
        throw StateError('Worker not found.');
      }

      final liveEmployee = EmployeeModel.fromFirestore(
        employeeSnap.id,
        employeeSnap.data()!,
      ).toEntity();

      final existing = ledgerSnap.exists && ledgerSnap.data() != null
          ? MonthlyLedgerModel.fromFirestore(
              ledgerSnap.id,
              ledgerSnap.data()!,
            ).toEntity()
          : null;

      if (existing != null && existing.isClosed) {
        throw StateError(
          'This month is closed. Reopen the cycle before recording a payment.',
        );
      }

      final ledger = existing ??
          _buildNewLedger(
            employee: liveEmployee,
            monthKey: monthKey,
            openingBalance: 0,
            billableDays: billableDays,
          );

      final newPaid = WagePayableCalculator.roundMoney(
        ledger.totalPaid + roundedAmount,
      );
      final remaining = WagePayableCalculator.remainingBalance(
        totalPayable: ledger.totalPayable,
        totalPaid: newPaid,
      );
      final overpaid = WagePayableCalculator.isOverpaid(remaining);
      final status = WagePayableCalculator.statusFor(
        remaining: remaining,
        closed: false,
      );

      if (existing == null) {
        transaction.set(
          ledgerRef,
          MonthlyLedgerModel.fromEntity(
            ledger.copyWith(
              totalPaid: newPaid,
              remainingBalance: remaining,
              status: status,
              isOverpaid: overpaid,
            ),
          ).toFirestore(isCreate: true),
        );
      } else {
        transaction.update(ledgerRef, {
          'totalPaid': newPaid,
          'remainingBalance': remaining,
          'status': status.firestoreValue,
          'isOverpaid': overpaid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final activeKey = liveEmployee.activeMonthKey;
      if (activeKey == null || activeKey.isEmpty) {
        transaction.update(employeeRef, {
          'activeMonthKey': monthKey,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final payment = WagePayment(
        id: paymentId,
        employeeId: employeeId,
        factoryId: liveEmployee.factoryId,
        monthKey: monthKey,
        amount: roundedAmount,
        paymentDate: when,
        paymentMethod: method,
        notes: notes?.trim().isEmpty ?? true ? null : notes!.trim(),
        recordedBy: recordedBy.trim(),
        recordedByName: recordedByName?.trim().isEmpty ?? true
            ? null
            : recordedByName!.trim(),
        createdAt: DateTime.now(),
      );

      transaction.set(
        paymentRef,
        WagePaymentModel.fromEntity(payment).toFirestore(isCreate: true),
      );

      return payment;
    });
  }

  Future<void> refreshLedgerPayable({
    required String employeeId,
    required String monthKey,
  }) async {
    final employee = await _employeeRepository.getEmployee(employeeId);
    if (employee == null) {
      throw StateError('Worker not found.');
    }
    final billableDays = await _billableDaysFor(employee, monthKey);

    await _firestore.runTransaction<void>((transaction) async {
      final employeeRef = _employeeDoc(employeeId);
      final ledgerRef = _ledgers(employeeId).doc(monthKey);
      final employeeSnap = await transaction.get(employeeRef);
      final ledgerSnap = await transaction.get(ledgerRef);

      if (!employeeSnap.exists || employeeSnap.data() == null) {
        throw StateError('Worker not found.');
      }
      if (!ledgerSnap.exists || ledgerSnap.data() == null) {
        throw StateError('No ledger exists for this month.');
      }

      final liveEmployee = EmployeeModel.fromFirestore(
        employeeSnap.id,
        employeeSnap.data()!,
      ).toEntity();
      final ledger = MonthlyLedgerModel.fromFirestore(
        ledgerSnap.id,
        ledgerSnap.data()!,
      ).toEntity();

      if (ledger.isClosed) {
        throw StateError('Cannot recalculate a closed month.');
      }

      final totalPayable = WagePayableCalculator.computeTotalPayable(
        wageType: liveEmployee.salaryType,
        baseRate: liveEmployee.rateAmount,
        openingBalance: ledger.openingBalance,
        adjustments: ledger.adjustments,
        billableDays: billableDays,
      );
      final remaining = WagePayableCalculator.remainingBalance(
        totalPayable: totalPayable,
        totalPaid: ledger.totalPaid,
      );

      transaction.update(ledgerRef, {
        'wageType': liveEmployee.salaryType.firestoreValue,
        'baseRate': liveEmployee.rateAmount,
        'billableDays': billableDays,
        'totalPayable': totalPayable,
        'remainingBalance': remaining,
        'status': WagePayableCalculator.statusFor(
          remaining: remaining,
          closed: false,
        ).firestoreValue,
        'isOverpaid': WagePayableCalculator.isOverpaid(remaining),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<MonthlyLedger> closeMonthlyCycle({
    required String employeeId,
    required String monthKey,
    String? rollOverAction,
    String? closedBy,
  }) async {
    final action = WageCycleRolloverAction.values.firstWhere(
      (value) => value.name == rollOverAction,
      orElse: () => WageCycleRolloverAction.carryForward,
    );

    final employee = await _employeeRepository.getEmployee(employeeId);
    if (employee == null) {
      throw StateError('Worker not found.');
    }

    final nextKey = DateKeys.nextMonthKey(monthKey);
    final nextBillableDays = await _billableDaysFor(employee, nextKey);

    return _firestore.runTransaction<MonthlyLedger>((transaction) async {
      final employeeRef = _employeeDoc(employeeId);
      final currentRef = _ledgers(employeeId).doc(monthKey);
      final nextRef = _ledgers(employeeId).doc(nextKey);

      final employeeSnap = await transaction.get(employeeRef);
      final currentSnap = await transaction.get(currentRef);
      final nextSnap = await transaction.get(nextRef);

      if (!employeeSnap.exists || employeeSnap.data() == null) {
        throw StateError('Worker not found.');
      }
      if (!currentSnap.exists || currentSnap.data() == null) {
        throw StateError('No ledger exists for this month.');
      }

      final liveEmployee = EmployeeModel.fromFirestore(
        employeeSnap.id,
        employeeSnap.data()!,
      ).toEntity();
      final current = MonthlyLedgerModel.fromFirestore(
        currentSnap.id,
        currentSnap.data()!,
      ).toEntity();

      if (current.isClosed) {
        throw StateError('This month is already closed.');
      }

      final openingBalance = action == WageCycleRolloverAction.carryForward
          ? current.remainingBalance
          : 0.0;

      transaction.update(currentRef, {
        'status': MonthlyLedgerStatus.closed.firestoreValue,
        'closedAt': FieldValue.serverTimestamp(),
        if (closedBy != null && closedBy.isNotEmpty) 'closedBy': closedBy,
        'rolloverAction': action.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (nextSnap.exists && nextSnap.data() != null) {
        final next = MonthlyLedgerModel.fromFirestore(
          nextSnap.id,
          nextSnap.data()!,
        ).toEntity();
        if (!next.isClosed) {
          final totalPayable = WagePayableCalculator.computeTotalPayable(
            wageType: next.wageType,
            baseRate: next.baseRate,
            openingBalance: next.openingBalance + openingBalance,
            adjustments: next.adjustments,
            billableDays: next.billableDays,
          );
          final remaining = WagePayableCalculator.remainingBalance(
            totalPayable: totalPayable,
            totalPaid: next.totalPaid,
          );
          transaction.update(nextRef, {
            'openingBalance': WagePayableCalculator.roundMoney(
              next.openingBalance + openingBalance,
            ),
            'totalPayable': totalPayable,
            'remainingBalance': remaining,
            'status': WagePayableCalculator.statusFor(
              remaining: remaining,
              closed: false,
            ).firestoreValue,
            'isOverpaid': WagePayableCalculator.isOverpaid(remaining),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        final nextLedger = _buildNewLedger(
          employee: liveEmployee,
          monthKey: nextKey,
          openingBalance: openingBalance,
          billableDays: nextBillableDays,
        );
        transaction.set(
          nextRef,
          MonthlyLedgerModel.fromEntity(nextLedger).toFirestore(isCreate: true),
        );
      }

      transaction.update(employeeRef, {
        'activeMonthKey': nextKey,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return current.copyWith(
        status: MonthlyLedgerStatus.closed,
        closedAt: DateTime.now(),
        closedBy: closedBy,
        rolloverAction: action,
      );
    });
  }

  Future<void> reopenMonthlyCycle({
    required String employeeId,
    required String monthKey,
  }) async {
    await _firestore.runTransaction<void>((transaction) async {
      final employeeRef = _employeeDoc(employeeId);
      final ledgerRef = _ledgers(employeeId).doc(monthKey);
      final employeeSnap = await transaction.get(employeeRef);
      final ledgerSnap = await transaction.get(ledgerRef);

      if (!employeeSnap.exists || employeeSnap.data() == null) {
        throw StateError('Worker not found.');
      }
      if (!ledgerSnap.exists || ledgerSnap.data() == null) {
        throw StateError('No ledger exists for this month.');
      }

      final ledger = MonthlyLedgerModel.fromFirestore(
        ledgerSnap.id,
        ledgerSnap.data()!,
      ).toEntity();
      if (!ledger.isClosed) {
        throw StateError('This month is already open.');
      }

      final status = WagePayableCalculator.statusFor(
        remaining: ledger.remainingBalance,
        closed: false,
      );

      transaction.update(ledgerRef, {
        'status': status.firestoreValue,
        'closedAt': FieldValue.delete(),
        'closedBy': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(employeeRef, {
        'activeMonthKey': monthKey,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<double> _billableDaysFor(Employee employee, String monthKey) async {
    if (employee.salaryType != SalaryType.dailyRate) return 0;
    final records = await _attendanceRepository.getForEmployeeMonth(
      factoryId: employee.factoryId,
      employeeId: employee.id,
      monthKey: monthKey,
    );
    return WagePayableCalculator.billableDays(records);
  }

  MonthlyLedger _buildNewLedger({
    required Employee employee,
    required String monthKey,
    required double openingBalance,
    required double billableDays,
  }) {
    final start = DateKeys.monthStart(monthKey);
    final totalPayable = WagePayableCalculator.computeTotalPayable(
      wageType: employee.salaryType,
      baseRate: employee.rateAmount,
      openingBalance: openingBalance,
      adjustments: 0,
      billableDays: billableDays,
    );
    final remaining = WagePayableCalculator.remainingBalance(
      totalPayable: totalPayable,
      totalPaid: 0,
    );
    final now = DateTime.now();
    return MonthlyLedger(
      id: monthKey,
      employeeId: employee.id,
      factoryId: employee.factoryId,
      month: start.month,
      year: start.year,
      wageType: employee.salaryType,
      baseRate: employee.rateAmount,
      openingBalance: WagePayableCalculator.roundMoney(openingBalance),
      adjustments: 0,
      billableDays: billableDays,
      totalPayable: totalPayable,
      totalPaid: 0,
      remainingBalance: remaining,
      status: WagePayableCalculator.statusFor(
        remaining: remaining,
        closed: false,
      ),
      isOverpaid: WagePayableCalculator.isOverpaid(remaining),
      createdAt: now,
      updatedAt: now,
    );
  }
}
