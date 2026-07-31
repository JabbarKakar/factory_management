import 'dart:math' as math;

import '../../domain/entities/stock_output.dart';
import '../../domain/enums/job_work_enums.dart';
import 'stock_output_calculator.dart';

/// Net large-stock totals after Waste + Yield deductions.
///
/// Deduction applies only when [wasteUnit] is [WasteUnit.sqFt] so units stay
/// consistent with large-stock square footage. Tons-based waste remains
/// metadata and does not reduce large stock.
abstract final class JobWorkLargeStockNet {
  static double roundSqFt(double value) =>
      double.parse(value.toStringAsFixed(2));

  static double roundAmount(double value) =>
      double.parse(value.toStringAsFixed(2));

  static List<StockOutput> activeLarge(Iterable<StockOutput> outputs) =>
      outputs.where((o) => o.hasProduction).toList();

  static double grossSquareFeet(Iterable<StockOutput> largeOutputs) =>
      StockOutputCalculator.totalSquareFeet(activeLarge(largeOutputs));

  static double grossAmount(Iterable<StockOutput> largeOutputs) =>
      StockOutputCalculator.grandTotal(activeLarge(largeOutputs));

  /// Waste + Yield in sq.ft when unit is sq.ft; otherwise 0.
  static double deductionSquareFeet({
    required double wasteAmount,
    required double yieldAmount,
    required WasteUnit wasteUnit,
  }) {
    if (wasteUnit != WasteUnit.sqFt) return 0;
    final waste = wasteAmount < 0 ? 0.0 : wasteAmount;
    final yieldAmt = yieldAmount < 0 ? 0.0 : yieldAmount;
    return roundSqFt(waste + yieldAmt);
  }

  static bool deductionExceedsGross({
    required Iterable<StockOutput> largeOutputs,
    required double wasteAmount,
    required double yieldAmount,
    required WasteUnit wasteUnit,
  }) {
    final deduction = deductionSquareFeet(
      wasteAmount: wasteAmount,
      yieldAmount: yieldAmount,
      wasteUnit: wasteUnit,
    );
    if (deduction <= 0) return false;
    return deduction > grossSquareFeet(largeOutputs) + 0.0001;
  }

  static double netSquareFeet({
    required Iterable<StockOutput> largeOutputs,
    required double wasteAmount,
    required double yieldAmount,
    required WasteUnit wasteUnit,
  }) {
    final net = grossSquareFeet(largeOutputs) -
        deductionSquareFeet(
          wasteAmount: wasteAmount,
          yieldAmount: yieldAmount,
          wasteUnit: wasteUnit,
        );
    return roundSqFt(math.max(0, net));
  }

  /// Scales gross large cutting charges by the net/gross sq.ft ratio.
  static double netAmount({
    required Iterable<StockOutput> largeOutputs,
    required double wasteAmount,
    required double yieldAmount,
    required WasteUnit wasteUnit,
  }) {
    final grossSq = grossSquareFeet(largeOutputs);
    final grossAmt = grossAmount(largeOutputs);
    if (grossSq <= 0 || grossAmt <= 0) return 0;
    final netSq = netSquareFeet(
      largeOutputs: largeOutputs,
      wasteAmount: wasteAmount,
      yieldAmount: yieldAmount,
      wasteUnit: wasteUnit,
    );
    return roundAmount(grossAmt * (netSq / grossSq));
  }

  static double deductionAmount({
    required Iterable<StockOutput> largeOutputs,
    required double wasteAmount,
    required double yieldAmount,
    required WasteUnit wasteUnit,
  }) {
    final gross = grossAmount(largeOutputs);
    final net = netAmount(
      largeOutputs: largeOutputs,
      wasteAmount: wasteAmount,
      yieldAmount: yieldAmount,
      wasteUnit: wasteUnit,
    );
    return roundAmount(math.max(0, gross - net));
  }
}
