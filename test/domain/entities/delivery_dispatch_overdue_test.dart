import 'package:factory_management/domain/entities/delivery.dart';
import 'package:factory_management/domain/enums/delivery_enums.dart';
import 'package:factory_management/domain/enums/sales_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Delivery buildDelivery({
    required DateTime scheduledDate,
    DeliveryStatus status = DeliveryStatus.scheduled,
  }) {
    return Delivery(
      id: 'delivery-1',
      deliveryNumber: 'DL-001',
      factoryId: 'factory-1',
      salesOrderId: 'order-1',
      salesOrderNumber: 'SO-001',
      customerId: 'customer-1',
      customerName: 'Customer',
      deliveryAddress: 'Address',
      scheduledDate: scheduledDate,
      status: status,
      lineItems: const [
        DeliveryLineItem(
          productType: SalesProductType.tile,
          marbleVariety: 'Black Galaxy',
          sizeThickness: '12x12',
          pieces: 10,
          squareFeet: 10,
        ),
      ],
      createdAt: DateTime(2026, 1, 1),
    );
  }

  group('Delivery.isDispatchOverdue', () {
    test('returns false for future scheduled date', () {
      final delivery = buildDelivery(
        scheduledDate: DateTime(2026, 7, 15),
      );

      expect(
        delivery.isDispatchOverdue(reference: DateTime(2026, 7, 10)),
        isFalse,
      );
    });

    test('returns true when scheduled date is before today and active', () {
      final delivery = buildDelivery(
        scheduledDate: DateTime(2026, 7, 5),
      );

      expect(
        delivery.isDispatchOverdue(reference: DateTime(2026, 7, 10)),
        isTrue,
      );
      expect(delivery.dispatchDaysOverdue(reference: DateTime(2026, 7, 10)), 5);
    });

    test('returns false for terminal deliveries even if date passed', () {
      final delivery = buildDelivery(
        scheduledDate: DateTime(2026, 7, 1),
        status: DeliveryStatus.delivered,
      );

      expect(
        delivery.isDispatchOverdue(reference: DateTime(2026, 7, 10)),
        isFalse,
      );
    });

    test('scheduled status can confirm delivery', () {
      expect(DeliveryStatus.scheduled.canConfirmDelivery, isTrue);
    });
  });
}
