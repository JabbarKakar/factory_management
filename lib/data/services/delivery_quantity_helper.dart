import '../../core/constants/job_work_sizes.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/delivery_enums.dart';
import '../../domain/enums/sales_enums.dart';

class DeliveryRemainingLine {
  const DeliveryRemainingLine({
    required this.lineItem,
    required this.orderedQuantity,
    required this.remainingQuantity,
  });

  final DeliveryLineItem lineItem;
  final double orderedQuantity;
  final double remainingQuantity;
}

abstract final class DeliveryQuantityHelper {
  static bool matchesOrderLine(
    DeliveryLineItem item,
    SalesOrderLineItem orderLine,
  ) {
    return item.productType == orderLine.productType &&
        item.marbleVariety == orderLine.marbleVariety &&
        item.sizeThickness == orderLine.sizeThickness &&
        item.quantityUnit == orderLine.quantityUnit;
  }

  static double consumedQuantity(Delivery delivery, DeliveryLineItem item) {
    if (delivery.status == DeliveryStatus.failed) return 0;
    if (delivery.status.isTerminal) {
      return item.quantityDelivered ?? item.quantity;
    }
    return item.quantity;
  }

  static double consumedForOrderLine(
    SalesOrderLineItem orderLine,
    List<Delivery> deliveries, {
    String? excludeDeliveryId,
  }) {
    var total = 0.0;
    for (final delivery in deliveries) {
      if (excludeDeliveryId != null && delivery.id == excludeDeliveryId) {
        continue;
      }
      if (delivery.status == DeliveryStatus.failed) continue;
      for (final item in delivery.lineItems) {
        if (matchesOrderLine(item, orderLine)) {
          total += consumedQuantity(delivery, item);
        }
      }
    }
    return total;
  }

  static double remainingForOrderLine(
    SalesOrderLineItem orderLine,
    List<Delivery> deliveries, {
    String? excludeDeliveryId,
  }) {
    final remaining = orderLine.quantity -
        consumedForOrderLine(
          orderLine,
          deliveries,
          excludeDeliveryId: excludeDeliveryId,
        );
    return remaining < 0 ? 0 : remaining;
  }

  static List<DeliveryRemainingLine> remainingLines(
    SalesOrder order,
    List<Delivery> deliveries, {
    String? excludeDeliveryId,
  }) {
    final lines = <DeliveryRemainingLine>[];
    for (final orderLine in order.lineItems) {
      for (final stock in orderLine.stockRows) {
        final synthetic = SalesOrderLineItem(
          productType: orderLine.productType,
          marbleVariety: orderLine.marbleVariety,
          smallStockOutputs: JobWorkSizes.isSmall(stock.size)
              ? [stock]
              : const [],
          largeStockOutputs: JobWorkSizes.isLarge(stock.size)
              ? [stock]
              : const [],
        );
        final remaining = remainingForOrderLine(
          synthetic,
          deliveries,
          excludeDeliveryId: excludeDeliveryId,
        );
        if (remaining <= 0) continue;
        lines.add(
          DeliveryRemainingLine(
            orderedQuantity: stock.squareFeet,
            remainingQuantity: remaining,
            lineItem: DeliveryLineItem(
              productType: orderLine.productType,
              marbleVariety: orderLine.marbleVariety,
              sizeThickness: stock.size,
              quantity: remaining,
              quantityUnit: SalesQuantityUnit.sqFt,
            ),
          ),
        );
      }
    }
    return lines;
  }

  static List<DeliveryRemainingLine> remainingLinesWithStock(
    SalesOrder order,
    List<Delivery> deliveries, {
    String? excludeDeliveryId,
  }) {
    return remainingLines(
      order,
      deliveries,
      excludeDeliveryId: excludeDeliveryId,
    )
        .where((line) => line.remainingQuantity > 0)
        .toList();
  }
}
