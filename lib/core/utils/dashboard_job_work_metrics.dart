import '../../domain/entities/dashboard_cashflow_metrics.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/job_work_output.dart';
import '../../domain/entities/stock_output.dart';
import '../../domain/enums/job_work_enums.dart';
import 'stock_output_calculator.dart';

/// Small / large stock-cut square feet and monetary values for a date window.
class DashboardStockCutTotals {
  const DashboardStockCutTotals({
    required this.smallSqFt,
    required this.largeSqFt,
    this.smallAmount = 0,
    this.largeAmount = 0,
  });

  final double smallSqFt;
  final double largeSqFt;
  final double smallAmount;
  final double largeAmount;

  double get totalSqFt => smallSqFt + largeSqFt;
  double get totalAmount => smallAmount + largeAmount;
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

  /// Small / large sq.ft cut & PKR amounts for [order] within an inclusive date range.
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
      var smallAmt = 0.0;
      var largeAmt = 0.0;
      for (final load in orderLoads) {
        final cut = stockCutInRangeForLoad(
          load,
          start: start,
          end: end,
        );
        small += cut.smallSqFt;
        large += cut.largeSqFt;
        smallAmt += cut.smallAmount;
        largeAmt += cut.largeAmount;
      }
      return DashboardStockCutTotals(
        smallSqFt: small,
        largeSqFt: large,
        smallAmount: smallAmt,
        largeAmount: largeAmt,
      );
    }
    final sRate = order.smallStockPrice > 0
        ? order.smallStockPrice
        : (order.pricingModel == PricingModel.perSqFt ? order.agreedRate : 0.0);
    final lRate = order.largeStockPrice > 0
        ? order.largeStockPrice
        : (order.pricingModel == PricingModel.perSqFt ? order.agreedRate : 0.0);
    return _stockCutFromShiftsOrOutput(
      shiftLogs: order.shiftLogs,
      output: order.output,
      start: start,
      end: end,
      smallRate: sRate,
      largeRate: lRate,
    );
  }

  static DashboardStockCutTotals stockCutInRangeForLoad(
    JobWorkLoad load, {
    required DateTime start,
    required DateTime end,
  }) {
    final sRate = load.smallStockPrice > 0
        ? load.smallStockPrice
        : (load.pricingModel == PricingModel.perSqFt ? load.agreedRate : 0.0);
    final lRate = load.largeStockPrice > 0
        ? load.largeStockPrice
        : (load.pricingModel == PricingModel.perSqFt ? load.agreedRate : 0.0);
    return _stockCutFromShiftsOrOutput(
      shiftLogs: load.shiftLogs,
      output: load.output,
      start: start,
      end: end,
      smallRate: sRate,
      largeRate: lRate,
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
    var smallAmt = 0.0;
    var largeAmt = 0.0;

    for (final load in persistedLoads) {
      final cut = stockCutInRangeForLoad(load, start: start, end: end);
      small += cut.smallSqFt;
      large += cut.largeSqFt;
      smallAmt += cut.smallAmount;
      largeAmt += cut.largeAmount;
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
      smallAmt += cut.smallAmount;
      largeAmt += cut.largeAmount;
    }

    return DashboardStockCutTotals(
      smallSqFt: small,
      largeSqFt: large,
      smallAmount: smallAmt,
      largeAmount: largeAmt,
    );
  }

  static DashboardStockCutTotals _stockCutFromShiftsOrOutput({
    required List<JobWorkShiftLog> shiftLogs,
    required JobWorkOutput? output,
    required DateTime start,
    required DateTime end,
    double smallRate = 0,
    double largeRate = 0,
  }) {
    if (shiftLogs.isNotEmpty) {
      var small = 0.0;
      var large = 0.0;
      var smallAmt = 0.0;
      var largeAmt = 0.0;
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
        smallAmt += _amount(shift.smallStockOutputs, smallRate);
        largeAmt += _amount(shift.largeStockOutputs, largeRate);
        if (!shift.hasStockOutputs) {
          // Legacy grade totals count as large/usable when no size rows.
          final legacy = shift.gradeASqFt + shift.gradeBSqFt + shift.gradeCSqFt;
          large += legacy;
          largeAmt += legacy * largeRate;
        }
      }
      return DashboardStockCutTotals(
        smallSqFt: small,
        largeSqFt: large,
        smallAmount: smallAmt,
        largeAmount: largeAmt,
      );
    }

    if (output?.isRecorded == true &&
        output!.recordedAt != null &&
        DashboardFinancePeriodRange.contains(
          output.recordedAt!,
          start,
          end,
        )) {
      if (output.hasStockOutputs) {
        final smallSq = output.smallStockSquareFeet;
        final largeSq = output.grossLargeStockSqFt;
        final smallAmt = output.smallStockAmount > 0
            ? output.smallStockAmount
            : smallSq * smallRate;
        final largeAmt = output.grossLargeStockAmount > 0
            ? output.grossLargeStockAmount
            : largeSq * largeRate;
        return DashboardStockCutTotals(
          smallSqFt: smallSq,
          largeSqFt: largeSq,
          smallAmount: smallAmt,
          largeAmount: largeAmt,
        );
      }
      final legacy =
          output.gradeASqFt + output.gradeBSqFt + output.gradeCSqFt;
      return DashboardStockCutTotals(
        smallSqFt: 0,
        largeSqFt: legacy,
        smallAmount: 0,
        largeAmount: legacy * largeRate,
      );
    }

    return const DashboardStockCutTotals(
      smallSqFt: 0,
      largeSqFt: 0,
      smallAmount: 0,
      largeAmount: 0,
    );
  }

  static double _squareFeet(Iterable<StockOutput> outputs) =>
      StockOutputCalculator.totalSquareFeet(
        outputs.where((output) => output.hasProduction),
      );

  static double _amount(Iterable<StockOutput> outputs, double fallbackRate) {
    var total = 0.0;
    for (final o in outputs.where((output) => output.hasProduction)) {
      if (o.amount > 0) {
        total += o.amount;
      } else {
        total += o.squareFeet * (o.pricePerSqFt > 0 ? o.pricePerSqFt : fallbackRate);
      }
    }
    return total;
  }
}
