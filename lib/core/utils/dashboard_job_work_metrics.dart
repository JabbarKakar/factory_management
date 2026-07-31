import '../../domain/entities/dashboard_cashflow_metrics.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/job_work_output.dart';
import '../../domain/entities/stock_output.dart';
import 'stock_output_calculator.dart';

/// Small / large stock-cut square feet for a date window.
class DashboardStockCutTotals {
  const DashboardStockCutTotals({
    required this.smallSqFt,
    required this.largeSqFt,
  });

  final double smallSqFt;
  final double largeSqFt;

  double get totalSqFt => smallSqFt + largeSqFt;
}

abstract final class DashboardJobWorkMetrics {
  /// Prefer Load shift/output when Loads exist; fall back to nested JW data.
  static double sqFtOnDay(
    JobWorkOrder order,
    DateTime day, {
    List<JobWorkLoad> loads = const [],
  }) {
    final cut = stockCutOnDay(order, day, loads: loads);
    return cut.smallSqFt + cut.largeSqFt;
  }

  static double sqFtInMonth(
    JobWorkOrder order,
    int year,
    int month, {
    List<JobWorkLoad> loads = const [],
  }) {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);
    final cut = stockCutInRange(
      order,
      start: monthStart,
      end: monthEnd,
      loads: loads,
    );
    return cut.smallSqFt + cut.largeSqFt;
  }

  static double sqFtOnDayForLoad(JobWorkLoad load, DateTime day) {
    final cut = stockCutOnDayForLoad(load, day);
    return cut.smallSqFt + cut.largeSqFt;
  }

  static double sqFtInMonthForLoad(JobWorkLoad load, int year, int month) {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);
    final cut = stockCutInRangeForLoad(
      load,
      start: monthStart,
      end: monthEnd,
    );
    return cut.smallSqFt + cut.largeSqFt;
  }

  static DashboardStockCutTotals stockCutOnDay(
    JobWorkOrder order,
    DateTime day, {
    List<JobWorkLoad> loads = const [],
  }) {
    return stockCutInRange(
      order,
      start: DashboardFinancePeriodRange.dateOnly(day),
      end: DashboardFinancePeriodRange.dateOnly(day),
      loads: loads,
    );
  }

  static DashboardStockCutTotals stockCutOnDayForLoad(
    JobWorkLoad load,
    DateTime day,
  ) {
    return stockCutInRangeForLoad(
      load,
      start: DashboardFinancePeriodRange.dateOnly(day),
      end: DashboardFinancePeriodRange.dateOnly(day),
    );
  }

  /// Small / large sq.ft cut for [order] within an inclusive date range.
  static DashboardStockCutTotals stockCutInRange(
    JobWorkOrder order, {
    required DateTime start,
    required DateTime end,
    List<JobWorkLoad> loads = const [],
  }) {
    final orderLoads = loads
        .where((load) => load.jobWorkId == order.id && !load.isVirtual)
        .toList();
    if (orderLoads.isNotEmpty) {
      var small = 0.0;
      var large = 0.0;
      for (final load in orderLoads) {
        final cut = stockCutInRangeForLoad(
          load,
          start: start,
          end: end,
        );
        small += cut.smallSqFt;
        large += cut.largeSqFt;
      }
      return DashboardStockCutTotals(smallSqFt: small, largeSqFt: large);
    }
    return _stockCutFromShiftsOrOutput(
      shiftLogs: order.shiftLogs,
      output: order.output,
      start: start,
      end: end,
    );
  }

  static DashboardStockCutTotals stockCutInRangeForLoad(
    JobWorkLoad load, {
    required DateTime start,
    required DateTime end,
  }) {
    return _stockCutFromShiftsOrOutput(
      shiftLogs: load.shiftLogs,
      output: load.output,
      start: start,
      end: end,
    );
  }

  /// Factory-wide totals across all orders/loads for the range.
  static DashboardStockCutTotals factoryStockCutInRange({
    required List<JobWorkOrder> orders,
    required List<JobWorkLoad> loads,
    required DateTime start,
    required DateTime end,
  }) {
    final persistedLoads = loads.where((load) => !load.isVirtual).toList();
    final ordersWithLoads = {
      for (final load in persistedLoads) load.jobWorkId,
    };

    var small = 0.0;
    var large = 0.0;

    for (final load in persistedLoads) {
      final cut = stockCutInRangeForLoad(load, start: start, end: end);
      small += cut.smallSqFt;
      large += cut.largeSqFt;
    }

    for (final order in orders) {
      if (ordersWithLoads.contains(order.id)) continue;
      final cut = stockCutInRange(
        order,
        start: start,
        end: end,
      );
      small += cut.smallSqFt;
      large += cut.largeSqFt;
    }

    return DashboardStockCutTotals(smallSqFt: small, largeSqFt: large);
  }

  static DashboardStockCutTotals _stockCutFromShiftsOrOutput({
    required List<JobWorkShiftLog> shiftLogs,
    required JobWorkOutput? output,
    required DateTime start,
    required DateTime end,
  }) {
    if (shiftLogs.isNotEmpty) {
      var small = 0.0;
      var large = 0.0;
      for (final shift in shiftLogs) {
        if (!DashboardFinancePeriodRange.contains(
          shift.shiftDate,
          start,
          end,
        )) {
          continue;
        }
        small += _squareFeet(shift.smallStockOutputs);
        large += _squareFeet(shift.largeStockOutputs);
        if (!shift.hasStockOutputs) {
          // Legacy grade totals count as large/usable when no size rows.
          final legacy = shift.gradeASqFt + shift.gradeBSqFt + shift.gradeCSqFt;
          large += legacy;
        }
      }
      return DashboardStockCutTotals(smallSqFt: small, largeSqFt: large);
    }

    if (output?.isRecorded == true &&
        output!.recordedAt != null &&
        DashboardFinancePeriodRange.contains(
          output.recordedAt!,
          start,
          end,
        )) {
      if (output.hasStockOutputs) {
        return DashboardStockCutTotals(
          smallSqFt: output.smallStockSquareFeet,
          // Gross large production (cut), not waste/yield net.
          largeSqFt: output.grossLargeStockSqFt,
        );
      }
      final legacy =
          output.gradeASqFt + output.gradeBSqFt + output.gradeCSqFt;
      return DashboardStockCutTotals(smallSqFt: 0, largeSqFt: legacy);
    }

    return const DashboardStockCutTotals(smallSqFt: 0, largeSqFt: 0);
  }

  static double _squareFeet(Iterable<StockOutput> outputs) =>
      StockOutputCalculator.totalSquareFeet(
        outputs.where((output) => output.hasProduction),
      );
}
