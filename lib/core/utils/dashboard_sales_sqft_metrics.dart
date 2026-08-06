import '../../domain/entities/dashboard_cashflow_metrics.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/sales_enums.dart';
import 'stock_output_calculator.dart';

/// Sales square-foot and monetary totals for dashboard period windows.
abstract final class DashboardSalesSqFtHelper {
  static ({
    double smallSqFt,
    double largeSqFt,
    double smallAmount,
    double largeAmount,
  }) factorySalesSqFtInRange({
    required List<SalesOrder> orders,
    required DateTime start,
    required DateTime end,
  }) {
    var small = 0.0;
    var large = 0.0;
    var smallAmt = 0.0;
    var largeAmt = 0.0;

    for (final order in orders) {
      if (order.status == SalesOrderStatus.cancelled) continue;
      if (!DashboardFinancePeriodRange.contains(
        order.orderDate,
        start,
        end,
      )) {
        continue;
      }
      final cut = _sqFtForOrder(order);
      small += cut.smallSqFt;
      large += cut.largeSqFt;
      smallAmt += cut.smallAmount;
      largeAmt += cut.largeAmount;
    }

    return (
      smallSqFt: small,
      largeSqFt: large,
      smallAmount: smallAmt,
      largeAmount: largeAmt,
    );
  }

  static ({
    double smallSqFt,
    double largeSqFt,
    double smallAmount,
    double largeAmount,
  }) _sqFtForOrder(SalesOrder order) {
    var small = 0.0;
    var large = 0.0;
    var smallAmt = 0.0;
    var largeAmt = 0.0;
    for (final item in order.lineItems) {
      final sSq = StockOutputCalculator.totalSquareFeet(item.activeSmallOutputs);
      final lSq = StockOutputCalculator.totalSquareFeet(item.activeLargeOutputs);
      small += sSq;
      large += lSq;
      smallAmt += item.smallTotalAmount > 0
          ? item.smallTotalAmount
          : sSq * item.smallPricePerSqFt;
      largeAmt += item.largeTotalAmount > 0
          ? item.largeTotalAmount
          : lSq * item.largePricePerSqFt;
    }
    return (
      smallSqFt: small,
      largeSqFt: large,
      smallAmount: smallAmt,
      largeAmount: largeAmt,
    );
  }
}
