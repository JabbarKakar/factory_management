import '../../domain/entities/attendance_record.dart';
import '../../domain/enums/labour_enums.dart';

abstract final class WagePayableCalculator {
  static const double settledEpsilon = 0.005;

  static double roundMoney(double value) =>
      double.parse(value.toStringAsFixed(2));

  static double billableDays(Iterable<AttendanceRecord> records) {
    var days = 0.0;
    for (final record in records) {
      days += switch (record.status) {
        AttendanceStatus.present => 1.0,
        AttendanceStatus.halfDay => 0.5,
        AttendanceStatus.absent ||
        AttendanceStatus.leave ||
        AttendanceStatus.holiday =>
          0.0,
      };
    }
    return roundMoney(days);
  }

  /// [baseRate] is monthly salary for [SalaryType.monthlyFixed] / per-piece,
  /// or the daily rate for [SalaryType.dailyRate].
  static double computeTotalPayable({
    required SalaryType wageType,
    required double baseRate,
    required double openingBalance,
    required double adjustments,
    required double billableDays,
  }) {
    final earned = switch (wageType) {
      SalaryType.dailyRate => roundMoney(baseRate * billableDays),
      SalaryType.monthlyFixed || SalaryType.perPieceRate => roundMoney(baseRate),
    };
    return roundMoney(earned + openingBalance + adjustments);
  }

  static double remainingBalance({
    required double totalPayable,
    required double totalPaid,
  }) {
    return roundMoney(totalPayable - totalPaid);
  }

  static bool isOverpaid(double remaining) => remaining < -settledEpsilon;

  static bool isSettled(double remaining) => remaining.abs() < settledEpsilon;

  static MonthlyLedgerStatus statusFor({
    required double remaining,
    required bool closed,
  }) {
    if (closed) return MonthlyLedgerStatus.closed;
    if (isSettled(remaining)) return MonthlyLedgerStatus.settled;
    return MonthlyLedgerStatus.open;
  }
}
