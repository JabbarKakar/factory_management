import 'package:factory_management/data/services/delivery_quantity_helper.dart';
import 'package:factory_management/domain/entities/delivery.dart';
import 'package:factory_management/domain/entities/sales_order.dart';
import 'package:factory_management/domain/entities/stock_output.dart';
import 'package:factory_management/domain/enums/customer_enums.dart';
import 'package:factory_management/domain/enums/delivery_enums.dart';
import 'package:factory_management/domain/enums/sales_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SalesOrder buildOrder() {
    return SalesOrder(
      id: 'order-1',
      orderNumber: 'SO-001',
      factoryId: 'factory-1',
      customerId: 'customer-1',
      customerName: 'Customer',
      status: SalesOrderStatus.ready,
      orderDate: DateTime(2026, 1, 1),
      orderSource: SalesOrderSource.walkIn,
      lineItems: const [
        SalesOrderLineItem(
          productType: SalesProductType.tile,
          marbleVariety: 'Black Galaxy',
          smallStockOutputs: [
            StockOutput(size: '12x12', pieces: 100, squareFeet: 100),
          ],
          largeStockOutputs: [
            StockOutput(size: '24x24', pieces: 50, squareFeet: 200),
          ],
          smallPricePerSqFt: 100,
          largePricePerSqFt: 120,
        ),
      ],
      subtotal: 34000,
      orderDiscount: 0,
      tax: 0,
      grandTotal: 34000,
      paymentTerms: PaymentTerms.cash,
      advanceReceived: 0,
      balanceDue: 34000,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  Delivery buildDelivery({
    required String id,
    required DeliveryStatus status,
    required List<DeliveryLineItem> lineItems,
  }) {
    return Delivery(
      id: id,
      deliveryNumber: 'DEL-1',
      factoryId: 'factory-1',
      salesOrderId: 'order-1',
      salesOrderNumber: 'SO-001',
      customerId: 'customer-1',
      customerName: 'Customer',
      deliveryAddress: 'Factory',
      scheduledDate: DateTime(2026, 1, 2),
      status: status,
      lineItems: lineItems,
      createdAt: DateTime(2026, 1, 2),
    );
  }

  group('DeliveryQuantityHelper', () {
    test('remainingLines returns per-size rows with pieces and square feet', () {
      final order = buildOrder();
      final lines = DeliveryQuantityHelper.remainingLines(order, const []);

      expect(lines, hasLength(2));
      expect(lines.first.remainingPieces, 100);
      expect(lines.first.remainingSquareFeet, 100);
      expect(lines.last.remainingPieces, 50);
      expect(lines.last.remainingSquareFeet, 200);
    });

    test('orderTotals subtracts confirmed and reserves active dispatches', () {
      final order = buildOrder();
      final deliveries = [
        buildDelivery(
          id: 'd1',
          status: DeliveryStatus.delivered,
          lineItems: const [
            DeliveryLineItem(
              productType: SalesProductType.tile,
              marbleVariety: 'Black Galaxy',
              sizeThickness: '12x12',
              pieces: 40,
              squareFeet: 40,
              piecesDelivered: 40,
              squareFeetDelivered: 40,
            ),
          ],
        ),
        buildDelivery(
          id: 'd2',
          status: DeliveryStatus.scheduled,
          lineItems: const [
            DeliveryLineItem(
              productType: SalesProductType.tile,
              marbleVariety: 'Black Galaxy',
              sizeThickness: '24x24',
              pieces: 10,
              squareFeet: 50,
            ),
          ],
        ),
      ];

      final totals = DeliveryQuantityHelper.orderTotals(order, deliveries);

      expect(totals.totalPieces, 150);
      expect(totals.totalSquareFeet, 300);
      expect(totals.dispatchedPieces, 50);
      expect(totals.dispatchedSquareFeet, 90);
      expect(totals.remainingPieces, 100);
      expect(totals.remainingSquareFeet, 210);
    });

    test('failed deliveries do not consume remaining stock', () {
      final order = buildOrder();
      final deliveries = [
        buildDelivery(
          id: 'd1',
          status: DeliveryStatus.failed,
          lineItems: const [
            DeliveryLineItem(
              productType: SalesProductType.tile,
              marbleVariety: 'Black Galaxy',
              sizeThickness: '12x12',
              pieces: 40,
              squareFeet: 40,
            ),
          ],
        ),
      ];

      final totals = DeliveryQuantityHelper.orderTotals(order, deliveries);

      expect(totals.dispatchedPieces, 0);
      expect(totals.dispatchedSquareFeet, 0);
      expect(totals.remainingPieces, 150);
      expect(totals.remainingSquareFeet, 300);
    });
  });
}
