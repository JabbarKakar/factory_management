import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/delivery.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/delivery_enums.dart';
import '../../domain/enums/sales_enums.dart';
import '../models/delivery_model.dart';
import '../services/delivery_quantity_helper.dart';
import 'sales_order_repository.dart';

class DeliveryException implements Exception {
  const DeliveryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DeliveryRepository {
  DeliveryRepository({
    FirebaseFirestore? firestore,
    SalesOrderRepository? salesOrderRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _salesOrderRepository =
            salesOrderRepository ?? SalesOrderRepository(firestore: firestore);

  final FirebaseFirestore _firestore;
  final SalesOrderRepository _salesOrderRepository;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('deliveries');

  Stream<List<Delivery>> watchDeliveries(String factoryId) {
    return _collection.where('factoryId', isEqualTo: factoryId).snapshots().map(
      (snapshot) {
        final deliveries = snapshot.docs
            .map((doc) => DeliveryModel.fromFirestore(doc.id, doc.data()))
            .map((model) => model.toEntity())
            .toList();
        deliveries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return deliveries;
      },
    );
  }

  Stream<Delivery?> watchDelivery(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return DeliveryModel.fromFirestore(doc.id, doc.data()!).toEntity();
    });
  }

  Future<Delivery?> getDelivery(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return DeliveryModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Stream<List<Delivery>> watchDeliveriesForSalesOrder(String salesOrderId) {
    return _collection
        .where('salesOrderId', isEqualTo: salesOrderId)
        .snapshots()
        .map(
      (snapshot) {
        final deliveries = snapshot.docs
            .map((doc) => DeliveryModel.fromFirestore(doc.id, doc.data()))
            .map((model) => model.toEntity())
            .toList();
        deliveries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return deliveries;
      },
    );
  }

  Future<List<Delivery>> fetchDeliveriesForSalesOrder(String salesOrderId) async {
    final snapshot =
        await _collection.where('salesOrderId', isEqualTo: salesOrderId).get();
    final deliveries = snapshot.docs
        .map((doc) => DeliveryModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .toList();
    deliveries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return deliveries;
  }

  Future<List<SalesOrder>> fetchDeliveryEligibleOrders(String factoryId) async {
    final orders = await _salesOrderRepository
        .watchSalesOrders(factoryId)
        .first;

    return orders
        .where(
          (order) =>
              order.status == SalesOrderStatus.ready ||
              order.status == SalesOrderStatus.invoiced ||
              order.status == SalesOrderStatus.paid,
        )
        .toList();
  }

  static bool isSalesOrderEligible(SalesOrder order) {
    return order.status == SalesOrderStatus.ready ||
        order.status == SalesOrderStatus.invoiced ||
        order.status == SalesOrderStatus.paid;
  }

  static List<DeliveryLineItem> lineItemsFromSalesOrder(SalesOrder order) {
    return order.lineItems
        .map(
          (item) => DeliveryLineItem(
            productType: item.productType,
            marbleVariety: item.marbleVariety,
            sizeThickness: item.sizeThickness,
            quantity: item.quantity,
            quantityUnit: item.quantityUnit,
          ),
        )
        .toList();
  }

  Future<Delivery> createDelivery(Delivery delivery) async {
    final order = await _salesOrderRepository.getSalesOrder(delivery.salesOrderId);
    if (order == null) {
      throw const DeliveryException('Sales order not found.');
    }
    if (!isSalesOrderEligible(order)) {
      throw const DeliveryException(
        'Only ready, invoiced, or paid sales orders can be scheduled for delivery.',
      );
    }
    if (delivery.lineItems.isEmpty) {
      throw const DeliveryException('Add at least one item to deliver.');
    }
    for (final item in delivery.lineItems) {
      if (item.quantity <= 0) {
        throw const DeliveryException('Item quantities must be greater than zero.');
      }
    }
    if (delivery.deliveryAddress.trim().isEmpty) {
      throw const DeliveryException('Delivery address is required.');
    }

    final existingDeliveries =
        await fetchDeliveriesForSalesOrder(delivery.salesOrderId);
    for (final item in delivery.lineItems) {
      final orderLine = order.lineItems.where(
        (line) => DeliveryQuantityHelper.matchesOrderLine(
          item,
          line,
        ),
      );
      if (orderLine.isEmpty) continue;
      final remaining = DeliveryQuantityHelper.remainingForOrderLine(
        orderLine.first,
        existingDeliveries,
      );
      if (item.quantity > remaining) {
        throw DeliveryException(
          'Quantity for ${item.displayLabel} exceeds remaining '
          '(${remaining.toStringAsFixed(1)} ${item.quantityUnit.label}).',
        );
      }
    }

    final id = delivery.id.isEmpty ? _uuid.v4() : delivery.id;
    final deliveryNumber = delivery.deliveryNumber.isEmpty
        ? await _generateDeliveryNumber(delivery.factoryId)
        : delivery.deliveryNumber;

    final record = delivery.copyWith(
      id: id,
      deliveryNumber: deliveryNumber,
      status: DeliveryStatus.scheduled,
      salesOrderNumber: order.orderNumber,
      customerId: order.customerId,
      customerName: order.customerName,
    );

    final model = DeliveryModel.fromEntity(record);
    await _collection.doc(id).set(model.toFirestore(isCreate: true));
    final created = await getDelivery(id);
    return created ?? record;
  }

  Future<void> advanceStatus(String id, DeliveryStatus status) async {
    final delivery = await getDelivery(id);
    if (delivery == null) {
      throw const DeliveryException('Delivery not found.');
    }
    if (delivery.status.nextStatus != status) {
      throw const DeliveryException('Invalid status transition.');
    }

    await _collection.doc(id).update({
      'status': status.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markFailed(String id, {String? notes}) async {
    final delivery = await getDelivery(id);
    if (delivery == null) {
      throw const DeliveryException('Delivery not found.');
    }
    if (!delivery.status.isActive) {
      throw const DeliveryException('This delivery is already completed.');
    }

    await _collection.doc(id).update({
      'status': DeliveryStatus.failed.firestoreValue,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> confirmDelivery({
    required String id,
    required DateTime actualDeliveryDate,
    required List<DeliveryLineItem> lineItems,
    String? notes,
  }) async {
    final delivery = await getDelivery(id);
    if (delivery == null) {
      throw const DeliveryException('Delivery not found.');
    }
    if (!delivery.status.canConfirmDelivery) {
      throw const DeliveryException(
        'Delivery must be loaded or in transit before confirmation.',
      );
    }

    if (lineItems.isEmpty) {
      throw const DeliveryException('Delivery items are required.');
    }

    final confirmedItems = <DeliveryLineItem>[];
    for (final item in lineItems) {
      if (item.quantityDelivered == null || item.quantityDelivered! < 0) {
        throw const DeliveryException('Enter delivered quantity for each item.');
      }
      if (item.quantityDelivered! > item.quantity) {
        throw const DeliveryException(
          'Delivered quantity cannot exceed scheduled quantity.',
        );
      }
      confirmedItems.add(item);
    }

    final isPartial = confirmedItems.any((item) => item.isPartiallyFulfilled);
    final finalStatus = isPartial
        ? DeliveryStatus.partiallyDelivered
        : DeliveryStatus.delivered;

    final model = DeliveryModel.fromEntity(
      delivery.copyWith(
        status: finalStatus,
        lineItems: confirmedItems,
        actualDeliveryDate: actualDeliveryDate,
        notes: notes?.trim().isEmpty ?? true ? delivery.notes : notes?.trim(),
      ),
    );

    await _collection.doc(id).update(model.toFirestore());
  }

  Future<String> _generateDeliveryNumber(String factoryId) async {
    final year = DateTime.now().year;
    final snapshot =
        await _collection.where('factoryId', isEqualTo: factoryId).get();
    final count = snapshot.docs.length + 1;
    return 'DEL-$year-${count.toString().padLeft(4, '0')}';
  }
}
