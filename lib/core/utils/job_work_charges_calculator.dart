import 'formatters.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/job_work_output.dart';
import '../../domain/entities/stock_output.dart';
import '../../domain/enums/job_work_enums.dart';

/// Line item in a cutting-charges breakdown.
class JobWorkChargeLine {
  const JobWorkChargeLine({
    required this.label,
    required this.detail,
    required this.amount,
  });

  final String label;
  final String detail;
  final double amount;
}

/// Calculates final cutting charges from actual output and agreed rates.
abstract final class JobWorkChargesCalculator {
  static bool usesStockPricing(JobWorkOrder order) =>
      _usesStockPricing(_PricingSource.fromOrder(order));

  static bool usesStockPricingForLoad(JobWorkLoad load) =>
      _usesStockPricing(_PricingSource.fromLoad(load));

  static List<JobWorkChargeLine> breakdown({
    required JobWorkOrder order,
    required JobWorkOutput output,
  }) =>
      _breakdown(source: _PricingSource.fromOrder(order), output: output);

  static List<JobWorkChargeLine> breakdownForLoad({
    required JobWorkLoad load,
    required JobWorkOutput output,
  }) =>
      _breakdown(source: _PricingSource.fromLoad(load), output: output);

  static double calculate({
    required JobWorkOrder order,
    required JobWorkOutput output,
    List<JobWorkShiftLog> shiftLogs = const [],
  }) {
    return resolveFinalCuttingCharges(
      order: order,
      output: output,
      shiftLogs: shiftLogs,
    );
  }

  static double calculateForLoad({
    required JobWorkLoad load,
    required JobWorkOutput output,
    List<JobWorkShiftLog> shiftLogs = const [],
  }) {
    return resolveFinalCuttingChargesForLoad(
      load: load,
      output: output,
      shiftLogs: shiftLogs,
    );
  }

  /// Final cutting charges from shift totals, stock output, or pricing model.
  static double resolveFinalCuttingCharges({
    required JobWorkOrder order,
    required JobWorkOutput output,
    List<JobWorkShiftLog> shiftLogs = const [],
    double? manualOverride,
  }) {
    return _resolveFinalCuttingCharges(
      source: _PricingSource.fromOrder(order),
      output: output,
      shiftLogs: shiftLogs,
      manualOverride: manualOverride,
    );
  }

  static double resolveFinalCuttingChargesForLoad({
    required JobWorkLoad load,
    required JobWorkOutput output,
    List<JobWorkShiftLog> shiftLogs = const [],
    double? manualOverride,
  }) {
    return _resolveFinalCuttingCharges(
      source: _PricingSource.fromLoad(load),
      output: output,
      shiftLogs: shiftLogs,
      manualOverride: manualOverride,
    );
  }

  static double _resolveFinalCuttingCharges({
    required _PricingSource source,
    required JobWorkOutput output,
    List<JobWorkShiftLog> shiftLogs = const [],
    double? manualOverride,
  }) {
    if (shiftLogs.isNotEmpty) {
      final shiftTotal = _roundAmount(
        shiftLogs.fold<double>(0, (sum, shift) => sum + shift.grandCuttingTotal),
      );
      if (shiftTotal > 0) return shiftTotal;
    }

    if (output.hasStockOutputs) {
      return output.grandCuttingTotal;
    }

    if (manualOverride != null && manualOverride > 0) {
      return manualOverride;
    }

    return _breakdown(source: source, output: output)
        .fold<double>(0, (sum, line) => sum + line.amount);
  }

  static double _roundAmount(double value) =>
      double.parse(value.toStringAsFixed(2));

  static double effectiveFinalCuttingCharges(JobWorkOrder order) {
    final output = order.output;
    if (output == null || !output.isRecorded) {
      return order.finalCuttingCharges;
    }

    final calculated = calculate(
      order: order,
      output: output,
      shiftLogs: order.shiftLogs,
    );
    if (calculated > 0) return calculated;
    return order.finalCuttingCharges;
  }

  static double effectiveFinalCuttingChargesForLoad(JobWorkLoad load) {
    final output = load.output;
    if (output == null || !output.isRecorded) {
      return load.finalCuttingCharges;
    }

    final calculated = calculateForLoad(
      load: load,
      output: output,
      shiftLogs: load.shiftLogs,
    );
    if (calculated > 0) return calculated;
    return load.finalCuttingCharges;
  }

  static double effectiveBalanceDue(JobWorkOrder order) {
    return effectiveFinalCuttingCharges(order) - order.advanceReceived;
  }

  static double effectiveBalanceDueForLoad(JobWorkLoad load) {
    return effectiveFinalCuttingChargesForLoad(load) - load.advanceReceived;
  }

  static bool _usesStockPricing(_PricingSource source) =>
      source.hasAnySize &&
      (source.smallStockPrice > 0 || source.largeStockPrice > 0);

  static List<JobWorkChargeLine> _breakdown({
    required _PricingSource source,
    required JobWorkOutput output,
  }) {
    if (output.hasStockOutputs) {
      return _stockOutputBreakdown(output);
    }
    if (_usesStockPricing(source)) {
      return _legacyStockSizeBreakdown(source);
    }
    return _modelBreakdown(source: source, output: output);
  }

  static List<JobWorkChargeLine> _stockOutputBreakdown(JobWorkOutput output) {
    final sym = Formatters.activeCurrency;
    return output.allStockOutputs
        .where((stock) => stock.hasProduction)
        .map(
          (stock) => JobWorkChargeLine(
            label: stock.size,
            detail:
                '${stock.pieces} pcs · ${stock.squareFeet.toStringAsFixed(2)} sq. ft × $sym ${stock.pricePerSqFt.toStringAsFixed(0)}',
            amount: stock.amount,
          ),
        )
        .toList();
  }

  static List<JobWorkChargeLine> _legacyStockSizeBreakdown(
    _PricingSource source,
  ) {
    final lines = <JobWorkChargeLine>[];
    final smallCount = source.smallSizes.length + source.legacySizes.length;
    final largeCount = source.largeSizes.length;
    final sym = Formatters.activeCurrency;

    if (smallCount > 0 && source.smallStockPrice > 0) {
      lines.add(
        JobWorkChargeLine(
          label: 'Small sizes',
          detail:
              '$smallCount × $sym ${source.smallStockPrice.toStringAsFixed(0)}',
          amount: source.smallStockPrice * smallCount,
        ),
      );
    }
    if (largeCount > 0 && source.largeStockPrice > 0) {
      lines.add(
        JobWorkChargeLine(
          label: 'Large sizes',
          detail:
              '$largeCount × $sym ${source.largeStockPrice.toStringAsFixed(0)}',
          amount: source.largeStockPrice * largeCount,
        ),
      );
    }
    return lines;
  }

  static List<JobWorkChargeLine> _modelBreakdown({
    required _PricingSource source,
    required JobWorkOutput output,
  }) {
    if (source.agreedRate <= 0) return const [];
    final sym = Formatters.activeCurrency;

    return switch (source.pricingModel) {
      PricingModel.perTon => [
          JobWorkChargeLine(
            label: source.pricingModel.label,
            detail:
                '${source.totalTons.toStringAsFixed(2)} t × $sym ${source.agreedRate.toStringAsFixed(0)}',
            amount: source.agreedRate * source.totalTons,
          ),
        ],
      PricingModel.perSqFt => [
          JobWorkChargeLine(
            label: source.pricingModel.label,
            detail:
                '${output.totalUsableSqFt.toStringAsFixed(0)} sq. ft × $sym ${source.agreedRate.toStringAsFixed(0)}',
            amount: source.agreedRate * output.totalUsableSqFt,
          ),
        ],
      PricingModel.perBlock => [
          JobWorkChargeLine(
            label: source.pricingModel.label,
            detail:
                '${source.blockCount} blocks × $sym ${source.agreedRate.toStringAsFixed(0)}',
            amount: source.agreedRate * source.blockCount,
          ),
        ],
      PricingModel.lumpSum => [
          JobWorkChargeLine(
            label: source.pricingModel.label,
            detail: 'Lump sum',
            amount: source.agreedRate,
          ),
        ],
    };
  }

  static double defaultSmallPricePerSqFt(JobWorkOrder order) =>
      _defaultSmallPricePerSqFt(_PricingSource.fromOrder(order));

  static double defaultSmallPricePerSqFtForLoad(JobWorkLoad load) =>
      _defaultSmallPricePerSqFt(_PricingSource.fromLoad(load));

  static double defaultLargePricePerSqFt(JobWorkOrder order) =>
      _defaultLargePricePerSqFt(_PricingSource.fromOrder(order));

  static double defaultLargePricePerSqFtForLoad(JobWorkLoad load) =>
      _defaultLargePricePerSqFt(_PricingSource.fromLoad(load));

  static double _defaultSmallPricePerSqFt(_PricingSource source) {
    if (source.smallStockPrice > 0) return source.smallStockPrice;
    if (source.pricingModel == PricingModel.perSqFt && source.agreedRate > 0) {
      return source.agreedRate;
    }
    return 0;
  }

  static double _defaultLargePricePerSqFt(_PricingSource source) {
    if (source.largeStockPrice > 0) return source.largeStockPrice;
    if (source.pricingModel == PricingModel.perSqFt && source.agreedRate > 0) {
      return source.agreedRate;
    }
    return 0;
  }

  static JobWorkOutput outputFromStockRows({
    required List<StockOutput> smallStockOutputs,
    required List<StockOutput> largeStockOutputs,
    double rejectSqFt = 0,
    double wasteAmount = 0,
    WasteUnit wasteUnit = WasteUnit.tons,
    String? slurryDust,
    WasteDisposition wasteDisposition = WasteDisposition.customerTakes,
  }) {
    return JobWorkOutput(
      smallStockOutputs: smallStockOutputs
          .where((output) => output.hasProduction)
          .toList(),
      largeStockOutputs: largeStockOutputs
          .where((output) => output.hasProduction)
          .toList(),
      rejectSqFt: rejectSqFt,
      wasteAmount: wasteAmount,
      wasteUnit: wasteUnit,
      slurryDust: slurryDust,
      wasteDisposition: wasteDisposition,
    );
  }
}

class _PricingSource {
  const _PricingSource({
    required this.hasAnySize,
    required this.smallSizes,
    required this.largeSizes,
    required this.legacySizes,
    required this.smallStockPrice,
    required this.largeStockPrice,
    required this.pricingModel,
    required this.agreedRate,
    required this.totalTons,
    required this.blockCount,
  });

  factory _PricingSource.fromOrder(JobWorkOrder order) {
    return _PricingSource(
      hasAnySize: order.hasAnySize,
      smallSizes: order.smallSizes,
      largeSizes: order.largeSizes,
      legacySizes: order.legacySizes,
      smallStockPrice: order.smallStockPrice,
      largeStockPrice: order.largeStockPrice,
      pricingModel: order.pricingModel,
      agreedRate: order.agreedRate,
      totalTons: order.totalTons,
      blockCount: order.blockCount,
    );
  }

  factory _PricingSource.fromLoad(JobWorkLoad load) {
    return _PricingSource(
      hasAnySize: load.hasAnySize,
      smallSizes: load.smallSizes,
      largeSizes: load.largeSizes,
      legacySizes: load.legacySizes,
      smallStockPrice: load.smallStockPrice,
      largeStockPrice: load.largeStockPrice,
      pricingModel: load.pricingModel,
      agreedRate: load.agreedRate,
      totalTons: load.totalTons,
      blockCount: load.blockCount,
    );
  }

  final bool hasAnySize;
  final List<String> smallSizes;
  final List<String> largeSizes;
  final List<String> legacySizes;
  final double smallStockPrice;
  final double largeStockPrice;
  final PricingModel pricingModel;
  final double agreedRate;
  final double totalTons;
  final int blockCount;
}
