import 'dart:math' as math;

import '../../domain/entities/delivery.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/entities/stock_output.dart';
import '../../domain/enums/delivery_enums.dart';

class DeliveryRemainingLine {
  const DeliveryRemainingLine({
    required this.lineItem,
    required this.orderedPieces,
    required this.orderedSquareFeet,
    required this.remainingPieces,
    required this.remainingSquareFeet,
  });

  final DeliveryLineItem lineItem;
  final int orderedPieces;
  final double orderedSquareFeet;
  final int remainingPieces;
  final double remainingSquareFeet;

  /// Legacy sq. ft. accessors.
  double get orderedQuantity => orderedSquareFeet;

  double get remainingQuantity => remainingSquareFeet;
}

class OrderDispatchTotals {
  const OrderDispatchTotals({
    required this.totalPieces,
    required this.totalSquareFeet,
    required this.dispatchedPieces,
    required this.dispatchedSquareFeet,
  });

  final int totalPieces;
  final double totalSquareFeet;
  final int dispatchedPieces;
  final double dispatchedSquareFeet;

  int get remainingPieces =>
      math.max(0, totalPieces - dispatchedPieces);

  double get remainingSquareFeet =>
      math.max(0, totalSquareFeet - dispatchedSquareFeet);

  bool get hasDispatches => dispatchedPieces > 0 || dispatchedSquareFeet > 0;

  bool get isFullyDispatched =>
      totalPieces > 0 &&
      remainingPieces == 0 &&
      remainingSquareFeet <= 0.001;
}

abstract final class DeliveryQuantityHelper {
  static bool matchesStockRow(
    DeliveryLineItem item,
    SalesOrderLineItem orderLine,
    String size,
  ) {
    return item.productType == orderLine.productType &&
        item.marbleVariety == orderLine.marbleVariety &&
        item.sizeThickness == size;
  }

  static StockOutput? findStockRow(
    SalesOrderLineItem orderLine,
    String size,
  ) {
    for (final stock in orderLine.stockRows) {
      if (stock.size == size) return stock;
    }
    return null;
  }

  static int consumedPieces(Delivery delivery, DeliveryLineItem item) {
    if (delivery.status == DeliveryStatus.failed) return 0;
    if (delivery.status.isTerminal) {
      return item.piecesDelivered ?? item.pieces;
    }
    return item.pieces;
  }

  static double consumedSquareFeet(Delivery delivery, DeliveryLineItem item) {
    if (delivery.status == DeliveryStatus.failed) return 0;
    if (delivery.status.isTerminal) {
      return item.squareFeetDelivered ?? item.squareFeet;
    }
    return item.squareFeet;
  }

  static int consumedPiecesForStockRow(
    SalesOrderLineItem orderLine,
    String size,
    List<Delivery> deliveries, {
    String? excludeDeliveryId,
  }) {
    var total = 0;
    for (final delivery in deliveries) {
      if (excludeDeliveryId != null && delivery.id == excludeDeliveryId) {
        continue;
      }
      if (delivery.status == DeliveryStatus.failed) continue;
      for (final item in delivery.lineItems) {
        if (matchesStockRow(item, orderLine, size)) {
          total += consumedPieces(delivery, item);
        }
      }
    }
    return total;
  }

  static double consumedSquareFeetForStockRow(
    SalesOrderLineItem orderLine,
    String size,
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
        if (matchesStockRow(item, orderLine, size)) {
          total += consumedSquareFeet(delivery, item);
        }
      }
    }
    return total;
  }

  static int remainingPiecesForStockRow(
    SalesOrderLineItem orderLine,
    String size,
    List<Delivery> deliveries, {
    String? excludeDeliveryId,
  }) {
    final stock = findStockRow(orderLine, size);
    if (stock == null) return 0;
    final remaining = stock.pieces -
        consumedPiecesForStockRow(
          orderLine,
          size,
          deliveries,
          excludeDeliveryId: excludeDeliveryId,
        );
    return remaining < 0 ? 0 : remaining;
  }

  static double remainingSquareFeetForStockRow(
    SalesOrderLineItem orderLine,
    String size,
    List<Delivery> deliveries, {
    String? excludeDeliveryId,
  }) {
    final stock = findStockRow(orderLine, size);
    if (stock == null) return 0;
    final remaining = stock.squareFeet -
        consumedSquareFeetForStockRow(
          orderLine,
          size,
          deliveries,
          excludeDeliveryId: excludeDeliveryId,
        );
    return remaining < 0 ? 0 : remaining;
  }

  static OrderDispatchTotals orderTotals(
    SalesOrder order,
    List<Delivery> deliveries, {
    String? excludeDeliveryId,
  }) {
    var dispatchedPieces = 0;
    var dispatchedSquareFeet = 0.0;

    for (final delivery in deliveries) {
      if (excludeDeliveryId != null && delivery.id == excludeDeliveryId) {
        continue;
      }
      if (delivery.status == DeliveryStatus.failed) continue;
      for (final item in delivery.lineItems) {
        dispatchedPieces += consumedPieces(delivery, item);
        dispatchedSquareFeet += consumedSquareFeet(delivery, item);
      }
    }

    return OrderDispatchTotals(
      totalPieces: order.totalPieces,
      totalSquareFeet: order.totalSquareFeet,
      dispatchedPieces: dispatchedPieces,
      dispatchedSquareFeet: dispatchedSquareFeet,
    );
  }

  static List<DeliveryRemainingLine> remainingLines(
    SalesOrder order,
    List<Delivery> deliveries, {
    String? excludeDeliveryId,
  }) {
    final lines = <DeliveryRemainingLine>[];
    for (final orderLine in order.lineItems) {
      for (final stock in orderLine.stockRows) {
        final remainingPieces = remainingPiecesForStockRow(
          orderLine,
          stock.size,
          deliveries,
          excludeDeliveryId: excludeDeliveryId,
        );
        final remainingSquareFeet = remainingSquareFeetForStockRow(
          orderLine,
          stock.size,
          deliveries,
          excludeDeliveryId: excludeDeliveryId,
        );
        if (remainingPieces <= 0 && remainingSquareFeet <= 0) continue;
        lines.add(
          DeliveryRemainingLine(
            orderedPieces: stock.pieces,
            orderedSquareFeet: stock.squareFeet,
            remainingPieces: remainingPieces,
            remainingSquareFeet: remainingSquareFeet,
            lineItem: DeliveryLineItem(
              productType: orderLine.productType,
              marbleVariety: orderLine.marbleVariety,
              sizeThickness: stock.size,
              pieces: remainingPieces,
              squareFeet: remainingSquareFeet,
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
    ).where(
      (line) => line.remainingPieces > 0 || line.remainingSquareFeet > 0,
    ).toList();
  }
}
