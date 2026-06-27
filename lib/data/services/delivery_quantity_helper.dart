import '../../domain/entities/delivery.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/delivery_enums.dart';

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
    List<Delivery> deliveries,
  ) {
    var total = 0.0;
    for (final delivery in deliveries) {
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
    List<Delivery> deliveries,
  ) {
    final remaining =
        orderLine.quantity - consumedForOrderLine(orderLine, deliveries);
    return remaining < 0 ? 0 : remaining;
  }

  static List<DeliveryRemainingLine> remainingLines(
    SalesOrder order,
    List<Delivery> deliveries,
  ) {
    return order.lineItems.map((orderLine) {
      final remaining = remainingForOrderLine(orderLine, deliveries);
      return DeliveryRemainingLine(
        orderedQuantity: orderLine.quantity,
        remainingQuantity: remaining,
        lineItem: DeliveryLineItem(
          productType: orderLine.productType,
          marbleVariety: orderLine.marbleVariety,
          sizeThickness: orderLine.sizeThickness,
          quantity: remaining,
          quantityUnit: orderLine.quantityUnit,
        ),
      );
    }).toList();
  }

  static List<DeliveryRemainingLine> remainingLinesWithStock(
    SalesOrder order,
    List<Delivery> deliveries,
  ) {
    return remainingLines(order, deliveries)
        .where((line) => line.remainingQuantity > 0)
        .toList();
  }
}
