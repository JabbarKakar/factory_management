import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/job_work_output.dart';

abstract final class DashboardJobWorkMetrics {
  /// Prefer Load shift/output when Loads exist; fall back to nested JW data.
  static double sqFtOnDay(
    JobWorkOrder order,
    DateTime day, {
    List<JobWorkLoad> loads = const [],
  }) {
    final orderLoads = loads
        .where((load) => load.jobWorkId == order.id && !load.isVirtual)
        .toList();
    if (orderLoads.isNotEmpty) {
      return orderLoads.fold<double>(
        0,
        (sum, load) => sum + sqFtOnDayForLoad(load, day),
      );
    }
    return _sqFtOnDayFromShiftsOrOutput(
      shiftLogs: order.shiftLogs,
      outputUsableSqFt: order.output?.isRecorded == true
          ? order.output!.totalUsableSqFt
          : null,
      outputRecordedAt: order.output?.recordedAt,
      day: day,
    );
  }

  static double sqFtInMonth(
    JobWorkOrder order,
    int year,
    int month, {
    List<JobWorkLoad> loads = const [],
  }) {
    final orderLoads = loads
        .where((load) => load.jobWorkId == order.id && !load.isVirtual)
        .toList();
    if (orderLoads.isNotEmpty) {
      return orderLoads.fold<double>(
        0,
        (sum, load) => sum + sqFtInMonthForLoad(load, year, month),
      );
    }
    return _sqFtInMonthFromShiftsOrOutput(
      shiftLogs: order.shiftLogs,
      outputUsableSqFt: order.output?.isRecorded == true
          ? order.output!.totalUsableSqFt
          : null,
      outputRecordedAt: order.output?.recordedAt,
      year: year,
      month: month,
    );
  }

  static double sqFtOnDayForLoad(JobWorkLoad load, DateTime day) {
    return _sqFtOnDayFromShiftsOrOutput(
      shiftLogs: load.shiftLogs,
      outputUsableSqFt: load.output?.isRecorded == true
          ? load.output!.totalUsableSqFt
          : null,
      outputRecordedAt: load.output?.recordedAt,
      day: day,
    );
  }

  static double sqFtInMonthForLoad(JobWorkLoad load, int year, int month) {
    return _sqFtInMonthFromShiftsOrOutput(
      shiftLogs: load.shiftLogs,
      outputUsableSqFt: load.output?.isRecorded == true
          ? load.output!.totalUsableSqFt
          : null,
      outputRecordedAt: load.output?.recordedAt,
      year: year,
      month: month,
    );
  }

  static double _sqFtOnDayFromShiftsOrOutput({
    required List<JobWorkShiftLog> shiftLogs,
    required double? outputUsableSqFt,
    required DateTime? outputRecordedAt,
    required DateTime day,
  }) {
    final target = DateTime(day.year, day.month, day.day);

    if (shiftLogs.isNotEmpty) {
      return shiftLogs
          .where((shift) => _isSameDay(shift.shiftDate, target))
          .fold<double>(0, (sum, shift) => sum + shift.totalUsableSqFt);
    }

    if (outputUsableSqFt != null &&
        outputRecordedAt != null &&
        _isSameDay(outputRecordedAt, target)) {
      return outputUsableSqFt;
    }

    return 0;
  }

  static double _sqFtInMonthFromShiftsOrOutput({
    required List<JobWorkShiftLog> shiftLogs,
    required double? outputUsableSqFt,
    required DateTime? outputRecordedAt,
    required int year,
    required int month,
  }) {
    if (shiftLogs.isNotEmpty) {
      return shiftLogs
          .where((shift) {
            final date = shift.shiftDate;
            return date.year == year && date.month == month;
          })
          .fold<double>(0, (sum, shift) => sum + shift.totalUsableSqFt);
    }

    if (outputUsableSqFt != null &&
        outputRecordedAt != null &&
        outputRecordedAt.year == year &&
        outputRecordedAt.month == month) {
      return outputUsableSqFt;
    }

    return 0;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
