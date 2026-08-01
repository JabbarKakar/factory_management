import '../../domain/entities/dashboard_cashflow_metrics.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/sales_enums.dart';
import 'stock_output_calculator.dart';

/// Sales square-foot totals for dashboard period windows.
abstract final class DashboardSalesSqFtHelper {
  static ({double smallSqFt, double largeSqFt}) factorySalesSqFtInRange({
    required List<SalesOrder> orders,
    required DateTime start,
    required DateTime end,
  }) {
    var small = 0.0;
    var large = 0.0;

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
    }

    return (smallSqFt: small, largeSqFt: large);
  }

  static ({double smallSqFt, double largeSqFt}) _sqFtForOrder(SalesOrder order) {
    var small = 0.0;
    var large = 0.0;
    for (final item in order.lineItems) {
      small += StockOutputCalculator.totalSquareFeet(item.activeSmallOutputs);
      large += StockOutputCalculator.totalSquareFeet(item.activeLargeOutputs);
    }
    return (smallSqFt: small, largeSqFt: large);
  }
}
