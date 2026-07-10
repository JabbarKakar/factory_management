import '../../domain/entities/delivery.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/sales_enums.dart';
import 'delivery_quantity_helper.dart';

/// Derives automated sales-order dispatch statuses from delivery consumption.
abstract final class SalesOrderDispatchStatusHelper {
  static bool isProtectedFromDispatchSync(SalesOrderStatus status) {
    return status == SalesOrderStatus.cancelled ||
        status == SalesOrderStatus.closed ||
        status == SalesOrderStatus.received;
  }

  static bool canScheduleDispatch(SalesOrderStatus status) {
    return status == SalesOrderStatus.ready ||
        status == SalesOrderStatus.partiallyDispatched ||
        status == SalesOrderStatus.invoiced ||
        status == SalesOrderStatus.paid;
  }

  /// Returns the status the order should have, or `null` when unchanged.
  static SalesOrderStatus? resolveTargetStatus({
    required SalesOrder order,
    required List<Delivery> deliveries,
  }) {
    final current = order.status;
    if (isProtectedFromDispatchSync(current)) return null;

    final totals = DeliveryQuantityHelper.orderTotals(order, deliveries);

    if (current == SalesOrderStatus.invoiced ||
        current == SalesOrderStatus.paid) {
      if (current == SalesOrderStatus.invoiced &&
          totals.isFullyDispatched) {
        return SalesOrderStatus.delivered;
      }
      return null;
    }

    if (totals.isFullyDispatched) {
      return SalesOrderStatus.delivered;
    }

    if (totals.hasDispatches) {
      return SalesOrderStatus.partiallyDispatched;
    }

    if (current == SalesOrderStatus.partiallyDispatched ||
        current == SalesOrderStatus.delivered) {
      return SalesOrderStatus.ready;
    }

    return null;
  }
}
