import 'package:factory_management/data/services/delivery_quantity_helper.dart';
import 'package:factory_management/data/services/sales_order_dispatch_status_helper.dart';
import 'package:factory_management/domain/entities/delivery.dart';
import 'package:factory_management/domain/entities/sales_order.dart';
import 'package:factory_management/domain/entities/stock_output.dart';
import 'package:factory_management/domain/enums/customer_enums.dart';
import 'package:factory_management/domain/enums/delivery_enums.dart';
import 'package:factory_management/domain/enums/sales_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SalesOrder buildOrder({SalesOrderStatus status = SalesOrderStatus.ready}) {
    return SalesOrder(
      id: 'order-1',
      orderNumber: 'SO-001',
      factoryId: 'factory-1',
      customerId: 'customer-1',
      customerName: 'Customer',
      status: status,
      orderDate: DateTime(2026, 1, 1),
      orderSource: SalesOrderSource.walkIn,
      lineItems: const [
        SalesOrderLineItem(
          productType: SalesProductType.tile,
          marbleVariety: 'Black Galaxy',
          smallStockOutputs: [
            StockOutput(size: '12x12', pieces: 100, squareFeet: 100),
          ],
          smallPricePerSqFt: 100,
          largePricePerSqFt: 120,
        ),
      ],
      subtotal: 10000,
      orderDiscount: 0,
      tax: 0,
      grandTotal: 10000,
      paymentTerms: PaymentTerms.cash,
      advanceReceived: 0,
      balanceDue: 10000,
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

  group('SalesOrderDispatchStatusHelper', () {
    test('scheduled dispatch moves ready order to partiallyDispatched', () {
      final order = buildOrder();
      final deliveries = [
        buildDelivery(
          id: 'd1',
          status: DeliveryStatus.scheduled,
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

      final target = SalesOrderDispatchStatusHelper.resolveTargetStatus(
        order: order,
        deliveries: deliveries,
      );

      expect(target, SalesOrderStatus.partiallyDispatched);
    });

    test('fully confirmed dispatch moves order to delivered', () {
      final order = buildOrder(status: SalesOrderStatus.partiallyDispatched);
      final deliveries = [
        buildDelivery(
          id: 'd1',
          status: DeliveryStatus.delivered,
          lineItems: const [
            DeliveryLineItem(
              productType: SalesProductType.tile,
              marbleVariety: 'Black Galaxy',
              sizeThickness: '12x12',
              pieces: 100,
              squareFeet: 100,
              piecesDelivered: 100,
              squareFeetDelivered: 100,
            ),
          ],
        ),
      ];

      final target = SalesOrderDispatchStatusHelper.resolveTargetStatus(
        order: order,
        deliveries: deliveries,
      );

      expect(target, SalesOrderStatus.delivered);
      expect(
        DeliveryQuantityHelper.orderTotals(order, deliveries).isFullyDispatched,
        isTrue,
      );
    });

    test('failed delivery reverts partiallyDispatched order to ready', () {
      final order = buildOrder(status: SalesOrderStatus.partiallyDispatched);
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

      final target = SalesOrderDispatchStatusHelper.resolveTargetStatus(
        order: order,
        deliveries: deliveries,
      );

      expect(target, SalesOrderStatus.ready);
    });

    test('fully delivered invoiced order becomes delivered', () {
      final order = buildOrder(status: SalesOrderStatus.invoiced);
      final deliveries = [
        buildDelivery(
          id: 'd1',
          status: DeliveryStatus.delivered,
          lineItems: const [
            DeliveryLineItem(
              productType: SalesProductType.tile,
              marbleVariety: 'Black Galaxy',
              sizeThickness: '12x12',
              pieces: 100,
              squareFeet: 100,
              piecesDelivered: 100,
              squareFeetDelivered: 100,
            ),
          ],
        ),
      ];

      final target = SalesOrderDispatchStatusHelper.resolveTargetStatus(
        order: order,
        deliveries: deliveries,
      );

      expect(target, SalesOrderStatus.delivered);
    });

    test('fully delivered paid order keeps paid status', () {
      final order = buildOrder(status: SalesOrderStatus.paid);
      final deliveries = [
        buildDelivery(
          id: 'd1',
          status: DeliveryStatus.delivered,
          lineItems: const [
            DeliveryLineItem(
              productType: SalesProductType.tile,
              marbleVariety: 'Black Galaxy',
              sizeThickness: '12x12',
              pieces: 100,
              squareFeet: 100,
              piecesDelivered: 100,
              squareFeetDelivered: 100,
            ),
          ],
        ),
      ];

      final target = SalesOrderDispatchStatusHelper.resolveTargetStatus(
        order: order,
        deliveries: deliveries,
      );

      expect(target, isNull);
    });

    test('invoiced order with partial dispatch keeps invoiced status', () {
      final order = buildOrder(status: SalesOrderStatus.invoiced);
      final deliveries = [
        buildDelivery(
          id: 'd1',
          status: DeliveryStatus.scheduled,
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

      final target = SalesOrderDispatchStatusHelper.resolveTargetStatus(
        order: order,
        deliveries: deliveries,
      );

      expect(target, isNull);
    });

    test('protected statuses are never auto-changed', () {
      final deliveries = [
        buildDelivery(
          id: 'd1',
          status: DeliveryStatus.delivered,
          lineItems: const [
            DeliveryLineItem(
              productType: SalesProductType.tile,
              marbleVariety: 'Black Galaxy',
              sizeThickness: '12x12',
              pieces: 100,
              squareFeet: 100,
              piecesDelivered: 100,
              squareFeetDelivered: 100,
            ),
          ],
        ),
      ];

      expect(
        SalesOrderDispatchStatusHelper.resolveTargetStatus(
          order: buildOrder(status: SalesOrderStatus.cancelled),
          deliveries: deliveries,
        ),
        isNull,
      );
      expect(
        SalesOrderDispatchStatusHelper.resolveTargetStatus(
          order: buildOrder(status: SalesOrderStatus.closed),
          deliveries: deliveries,
        ),
        isNull,
      );
      expect(
        SalesOrderDispatchStatusHelper.resolveTargetStatus(
          order: buildOrder(status: SalesOrderStatus.received),
          deliveries: deliveries,
        ),
        isNull,
      );
    });
  });
}
