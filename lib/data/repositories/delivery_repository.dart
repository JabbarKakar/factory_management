import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/stock_output_calculator.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/delivery_enums.dart';
import '../models/delivery_model.dart';
import '../services/delivery_quantity_helper.dart';
import '../services/sales_order_dispatch_status_helper.dart';
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

  Stream<List<Delivery>> watchDeliveriesForSalesOrder({
    required String factoryId,
    required String salesOrderId,
  }) {
    return _collection
        .where('factoryId', isEqualTo: factoryId)
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

  Future<List<Delivery>> fetchDeliveriesForSalesOrder({
    required String factoryId,
    required String salesOrderId,
  }) async {
    final snapshot = await _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('salesOrderId', isEqualTo: salesOrderId)
        .get();
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
          (order) => SalesOrderDispatchStatusHelper.canScheduleDispatch(
            order.status,
          ),
        )
        .toList();
  }

  static bool isSalesOrderEligible(SalesOrder order) {
    return SalesOrderDispatchStatusHelper.canScheduleDispatch(order.status);
  }

  static List<DeliveryLineItem> lineItemsFromSalesOrder(SalesOrder order) {
    final items = <DeliveryLineItem>[];
    for (final orderLine in order.lineItems) {
      for (final stock in orderLine.stockRows) {
        items.add(
          DeliveryLineItem(
            productType: orderLine.productType,
            marbleVariety: orderLine.marbleVariety,
            sizeThickness: stock.size,
            pieces: stock.pieces,
            squareFeet: stock.squareFeet,
          ),
        );
      }
    }
    return items;
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
      if (item.pieces <= 0) {
        throw const DeliveryException(
          'Dispatch quantities must be greater than zero.',
        );
      }
    }
    if (delivery.deliveryAddress.trim().isEmpty) {
      throw const DeliveryException('Delivery address is required.');
    }

    final existingDeliveries = await fetchDeliveriesForSalesOrder(
      factoryId: delivery.factoryId,
      salesOrderId: delivery.salesOrderId,
    );
    _validateLineQuantities(
      order: order,
      lineItems: delivery.lineItems,
      existingDeliveries: existingDeliveries,
    );

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
    await _syncSalesOrderDispatchStatus(
      factoryId: delivery.factoryId,
      salesOrderId: delivery.salesOrderId,
    );
    final created = await getDelivery(id);
    return created ?? record;
  }

  Future<Delivery> updateDelivery({
    required Delivery existing,
    required String deliveryAddress,
    required DateTime scheduledDate,
    required List<DeliveryLineItem> lineItems,
    String? vehicleNumber,
    String? driverName,
    String? driverEmployeeId,
    String? loadingSupervisor,
    String? notes,
  }) async {
    if (!existing.status.canEditLogistics) {
      throw const DeliveryException(
        'This delivery can no longer be edited.',
      );
    }
    if (deliveryAddress.trim().isEmpty) {
      throw const DeliveryException('Delivery address is required.');
    }

    final order =
        await _salesOrderRepository.getSalesOrder(existing.salesOrderId);
    if (order == null) {
      throw const DeliveryException('Sales order not found.');
    }

    final isScheduledEdit = existing.status.canEditScheduled;
    final effectiveLineItems = isScheduledEdit ? lineItems : existing.lineItems;

    if (isScheduledEdit) {
      if (effectiveLineItems.isEmpty) {
        throw const DeliveryException('Add at least one item to deliver.');
      }
      for (final item in effectiveLineItems) {
        if (item.pieces <= 0) {
          throw const DeliveryException(
            'Dispatch quantities must be greater than zero.',
          );
        }
      }

      final existingDeliveries = await fetchDeliveriesForSalesOrder(
        factoryId: existing.factoryId,
        salesOrderId: existing.salesOrderId,
      );
      _validateLineQuantities(
        order: order,
        lineItems: effectiveLineItems,
        existingDeliveries: existingDeliveries,
        excludeDeliveryId: existing.id,
      );
    }

    final updated = existing.copyWith(
      deliveryAddress: deliveryAddress.trim(),
      scheduledDate: scheduledDate,
      lineItems: effectiveLineItems,
      vehicleNumber: vehicleNumber?.trim().isEmpty ?? true
          ? null
          : vehicleNumber?.trim(),
      driverName:
          driverName?.trim().isEmpty ?? true ? null : driverName?.trim(),
      driverEmployeeId: driverEmployeeId,
      loadingSupervisor: loadingSupervisor?.trim().isEmpty ?? true
          ? null
          : loadingSupervisor?.trim(),
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      updatedAt: DateTime.now(),
    );

    final model = DeliveryModel.fromEntity(updated);
    await _collection.doc(existing.id).update(model.toFirestore());
    if (isScheduledEdit) {
      await _syncSalesOrderDispatchStatus(
        factoryId: existing.factoryId,
        salesOrderId: existing.salesOrderId,
      );
    }
    final saved = await getDelivery(existing.id);
    return saved ?? updated;
  }

  void _validateLineQuantities({
    required SalesOrder order,
    required List<DeliveryLineItem> lineItems,
    required List<Delivery> existingDeliveries,
    String? excludeDeliveryId,
  }) {
    for (final item in lineItems) {
      if (item.pieces < 0 || item.squareFeet < 0) {
        throw const DeliveryException('Dispatch quantities cannot be negative.');
      }

      final orderLine = order.lineItems.where(
        (line) =>
            line.productType == item.productType &&
            line.marbleVariety == item.marbleVariety,
      );
      if (orderLine.isEmpty) continue;

      final stock = DeliveryQuantityHelper.findStockRow(
        orderLine.first,
        item.sizeThickness,
      );
      if (stock == null) continue;

      final remainingPieces = DeliveryQuantityHelper.remainingPiecesForStockRow(
        orderLine.first,
        item.sizeThickness,
        existingDeliveries,
        excludeDeliveryId: excludeDeliveryId,
      );
      final remainingSquareFeet =
          DeliveryQuantityHelper.remainingSquareFeetForStockRow(
        orderLine.first,
        item.sizeThickness,
        existingDeliveries,
        excludeDeliveryId: excludeDeliveryId,
      );

      if (item.pieces > remainingPieces) {
        throw DeliveryException(
          'Pieces for ${item.displayLabel} exceed remaining ($remainingPieces pcs).',
        );
      }
      if (item.squareFeet > remainingSquareFeet) {
        throw DeliveryException(
          'Square feet for ${item.displayLabel} exceed remaining '
          '(${remainingSquareFeet.toStringAsFixed(2)} sq. ft).',
        );
      }
    }
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
    await _syncSalesOrderDispatchStatus(
      factoryId: delivery.factoryId,
      salesOrderId: delivery.salesOrderId,
    );
  }

  Future<void> confirmDelivery({
    required String id,
    required DateTime actualDeliveryDate,
    required List<DeliveryLineItem> lineItems,
    String? notes,
    String? receiverName,
  }) async {
    final delivery = await getDelivery(id);
    if (delivery == null) {
      throw const DeliveryException('Delivery not found.');
    }
    if (!delivery.status.canConfirmDelivery) {
      throw const DeliveryException(
        'This delivery cannot be confirmed in its current status.',
      );
    }

    if (lineItems.isEmpty) {
      throw const DeliveryException('Delivery items are required.');
    }

    final confirmedItems = <DeliveryLineItem>[];
    for (final item in lineItems) {
      if (item.piecesDelivered == null || item.piecesDelivered! < 0) {
        throw const DeliveryException(
          'Enter dispatched pieces for each item.',
        );
      }
      if (item.piecesDelivered! > item.pieces) {
        throw const DeliveryException(
          'Dispatched pieces cannot exceed scheduled pieces.',
        );
      }
      confirmedItems.add(
        item.copyWith(
          squareFeetDelivered: item.squareFeetDelivered ??
              StockOutputCalculator.compute(
                size: item.sizeThickness,
                pieces: item.piecesDelivered!,
                pricePerSqFt: 0,
              ).squareFeet,
        ),
      );
    }

    final isPartial = confirmedItems.any((item) => item.isPartiallyFulfilled);
    final finalStatus = isPartial
        ? DeliveryStatus.partiallyDelivered
        : DeliveryStatus.delivered;

    final updatedDelivery = delivery.copyWith(
      status: finalStatus,
      lineItems: confirmedItems,
      actualDeliveryDate: actualDeliveryDate,
      receiverName: receiverName?.trim().isEmpty ?? true
          ? delivery.receiverName
          : receiverName?.trim(),
      notes: notes?.trim().isEmpty ?? true ? delivery.notes : notes?.trim(),
    );

    final model = DeliveryModel.fromEntity(updatedDelivery);
    final batch = _firestore.batch();
    batch.update(_collection.doc(id), model.toFirestore());

    final order = await _salesOrderRepository.getSalesOrder(delivery.salesOrderId);
    if (order != null) {
      final deliveries = await fetchDeliveriesForSalesOrder(
        factoryId: delivery.factoryId,
        salesOrderId: delivery.salesOrderId,
      );
      final projectedDeliveries = deliveries
          .map((item) => item.id == id ? updatedDelivery : item)
          .toList();
      final targetStatus = SalesOrderDispatchStatusHelper.resolveTargetStatus(
        order: order,
        deliveries: projectedDeliveries,
      );
      if (targetStatus != null && targetStatus != order.status) {
        batch.update(
          _salesOrderRepository.salesOrderDoc(delivery.salesOrderId),
          {
            'status': targetStatus.firestoreValue,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }
    }

    await batch.commit();
  }

  Future<void> _syncSalesOrderDispatchStatus({
    required String factoryId,
    required String salesOrderId,
  }) async {
    final order = await _salesOrderRepository.getSalesOrder(salesOrderId);
    if (order == null) return;

    final deliveries = await fetchDeliveriesForSalesOrder(
      factoryId: factoryId,
      salesOrderId: salesOrderId,
    );
    final targetStatus = SalesOrderDispatchStatusHelper.resolveTargetStatus(
      order: order,
      deliveries: deliveries,
    );
    if (targetStatus == null || targetStatus == order.status) return;

    await _salesOrderRepository.updateDispatchStatus(salesOrderId, targetStatus);
  }

  Future<String> _generateDeliveryNumber(String factoryId) async {
    final year = DateTime.now().year;
    final snapshot =
        await _collection.where('factoryId', isEqualTo: factoryId).get();
    final count = snapshot.docs.length + 1;
    return 'DEL-$year-${count.toString().padLeft(4, '0')}';
  }
}
