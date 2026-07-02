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
      order.hasAnySize &&
      (order.smallStockPrice > 0 || order.largeStockPrice > 0);

  static List<JobWorkChargeLine> breakdown({
    required JobWorkOrder order,
    required JobWorkOutput output,
  }) {
    if (output.hasStockOutputs) {
      return _stockOutputBreakdown(output);
    }
    if (usesStockPricing(order)) {
      return _legacyStockSizeBreakdown(order);
    }
    return _modelBreakdown(order: order, output: output);
  }

  static double calculate({
    required JobWorkOrder order,
    required JobWorkOutput output,
  }) {
    if (output.hasStockOutputs) {
      return output.grandCuttingTotal;
    }
    return breakdown(order: order, output: output)
        .fold<double>(0, (sum, line) => sum + line.amount);
  }

  static List<JobWorkChargeLine> _stockOutputBreakdown(JobWorkOutput output) {
    return output.allStockOutputs
        .where((stock) => stock.hasProduction)
        .map(
          (stock) => JobWorkChargeLine(
            label: stock.size,
            detail:
                '${stock.pieces} pcs · ${stock.squareFeet.toStringAsFixed(2)} sq. ft × PKR ${stock.pricePerSqFt.toStringAsFixed(0)}',
            amount: stock.amount,
          ),
        )
        .toList();
  }

  static List<JobWorkChargeLine> _legacyStockSizeBreakdown(JobWorkOrder order) {
    final lines = <JobWorkChargeLine>[];
    final smallCount = order.smallSizes.length + order.legacySizes.length;
    final largeCount = order.largeSizes.length;

    if (smallCount > 0 && order.smallStockPrice > 0) {
      lines.add(
        JobWorkChargeLine(
          label: 'Small sizes',
          detail: '$smallCount × PKR ${order.smallStockPrice.toStringAsFixed(0)}',
          amount: order.smallStockPrice * smallCount,
        ),
      );
    }
    if (largeCount > 0 && order.largeStockPrice > 0) {
      lines.add(
        JobWorkChargeLine(
          label: 'Large sizes',
          detail: '$largeCount × PKR ${order.largeStockPrice.toStringAsFixed(0)}',
          amount: order.largeStockPrice * largeCount,
        ),
      );
    }
    return lines;
  }

  static List<JobWorkChargeLine> _modelBreakdown({
    required JobWorkOrder order,
    required JobWorkOutput output,
  }) {
    if (order.agreedRate <= 0) return const [];

    return switch (order.pricingModel) {
      PricingModel.perTon => [
          JobWorkChargeLine(
            label: order.pricingModel.label,
            detail:
                '${order.totalTons.toStringAsFixed(2)} t × PKR ${order.agreedRate.toStringAsFixed(0)}',
            amount: order.agreedRate * order.totalTons,
          ),
        ],
      PricingModel.perSqFt => [
          JobWorkChargeLine(
            label: order.pricingModel.label,
            detail:
                '${output.totalUsableSqFt.toStringAsFixed(0)} sq. ft × PKR ${order.agreedRate.toStringAsFixed(0)}',
            amount: order.agreedRate * output.totalUsableSqFt,
          ),
        ],
      PricingModel.perBlock => [
          JobWorkChargeLine(
            label: order.pricingModel.label,
            detail:
                '${order.blockCount} blocks × PKR ${order.agreedRate.toStringAsFixed(0)}',
            amount: order.agreedRate * order.blockCount,
          ),
        ],
      PricingModel.lumpSum => [
          JobWorkChargeLine(
            label: order.pricingModel.label,
            detail: 'Lump sum',
            amount: order.agreedRate,
          ),
        ],
    };
  }

  static double defaultSmallPricePerSqFt(JobWorkOrder order) {
    if (order.smallStockPrice > 0) return order.smallStockPrice;
    if (order.pricingModel == PricingModel.perSqFt && order.agreedRate > 0) {
      return order.agreedRate;
    }
    return 0;
  }

  static double defaultLargePricePerSqFt(JobWorkOrder order) {
    if (order.largeStockPrice > 0) return order.largeStockPrice;
    if (order.pricingModel == PricingModel.perSqFt && order.agreedRate > 0) {
      return order.agreedRate;
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
