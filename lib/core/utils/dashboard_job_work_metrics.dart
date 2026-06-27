import '../../domain/entities/job_work_order.dart';

abstract final class DashboardJobWorkMetrics {
  static double sqFtOnDay(JobWorkOrder order, DateTime day) {
    final target = DateTime(day.year, day.month, day.day);

    if (order.shiftLogs.isNotEmpty) {
      return order.shiftLogs
          .where((shift) => _isSameDay(shift.shiftDate, target))
          .fold<double>(0, (sum, shift) => sum + shift.totalUsableSqFt);
    }

    final output = order.output;
    final recordedAt = output?.recordedAt;
    if (output != null &&
        output.isRecorded &&
        recordedAt != null &&
        _isSameDay(recordedAt, target)) {
      return output.totalUsableSqFt;
    }

    return 0;
  }

  static double sqFtInMonth(JobWorkOrder order, int year, int month) {
    if (order.shiftLogs.isNotEmpty) {
      return order.shiftLogs
          .where((shift) {
            final date = shift.shiftDate;
            return date.year == year && date.month == month;
          })
          .fold<double>(0, (sum, shift) => sum + shift.totalUsableSqFt);
    }

    final output = order.output;
    final recordedAt = output?.recordedAt;
    if (output != null &&
        output.isRecorded &&
        recordedAt != null &&
        recordedAt.year == year &&
        recordedAt.month == month) {
      return output.totalUsableSqFt;
    }

    return 0;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
