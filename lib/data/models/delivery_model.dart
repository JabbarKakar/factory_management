import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/delivery.dart';
import '../../domain/enums/delivery_enums.dart';
import '../../domain/enums/sales_enums.dart';

class DeliveryModel {
  const DeliveryModel({
    required this.id,
    required this.deliveryNumber,
    required this.factoryId,
    required this.salesOrderId,
    required this.salesOrderNumber,
    required this.customerId,
    required this.customerName,
    required this.deliveryAddress,
    required this.scheduledDate,
    required this.status,
    required this.lineItems,
    required this.createdAt,
    this.vehicleNumber,
    this.driverName,
    this.driverEmployeeId,
    this.loadingSupervisor,
    this.notes,
    this.actualDeliveryDate,
    this.updatedAt,
  });

  final String id;
  final String deliveryNumber;
  final String factoryId;
  final String salesOrderId;
  final String salesOrderNumber;
  final String customerId;
  final String customerName;
  final String deliveryAddress;
  final DateTime scheduledDate;
  final DeliveryStatus status;
  final List<DeliveryLineItem> lineItems;
  final String? vehicleNumber;
  final String? driverName;
  final String? driverEmployeeId;
  final String? loadingSupervisor;
  final String? notes;
  final DateTime? actualDeliveryDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory DeliveryModel.fromFirestore(String id, Map<String, dynamic> data) {
    final items = (data['lineItems'] as List?) ?? const [];
    return DeliveryModel(
      id: id,
      deliveryNumber: data['deliveryNumber'] as String? ?? '',
      factoryId: data['factoryId'] as String? ?? 'default',
      salesOrderId: data['salesOrderId'] as String? ?? '',
      salesOrderNumber: data['salesOrderNumber'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      deliveryAddress: data['deliveryAddress'] as String? ?? '',
      scheduledDate:
          (data['scheduledDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: DeliveryStatus.fromString(data['status'] as String?),
      lineItems: items.whereType<Map>().map(_lineItemFromMap).toList(),
      vehicleNumber: data['vehicleNumber'] as String?,
      driverName: data['driverName'] as String?,
      driverEmployeeId: data['driverEmployeeId'] as String?,
      loadingSupervisor: data['loadingSupervisor'] as String?,
      notes: data['notes'] as String?,
      actualDeliveryDate:
          (data['actualDeliveryDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static DeliveryLineItem _lineItemFromMap(Map<dynamic, dynamic> data) {
    final legacyQuantity = (data['quantity'] as num?)?.toDouble() ?? 0;
    final squareFeet =
        (data['squareFeet'] as num?)?.toDouble() ?? legacyQuantity;
    final legacyDelivered = (data['quantityDelivered'] as num?)?.toDouble();
    return DeliveryLineItem(
      productType: SalesProductType.fromString(data['productType'] as String?),
      marbleVariety: data['marbleVariety'] as String? ?? '',
      sizeThickness: data['sizeThickness'] as String? ?? '',
      pieces: (data['pieces'] as num?)?.toInt() ?? 0,
      squareFeet: squareFeet,
      piecesDelivered: (data['piecesDelivered'] as num?)?.toInt(),
      squareFeetDelivered:
          (data['squareFeetDelivered'] as num?)?.toDouble() ?? legacyDelivered,
    );
  }

  static Map<String, dynamic> _lineItemToMap(DeliveryLineItem item) {
    return {
      'productType': item.productType.firestoreValue,
      'marbleVariety': item.marbleVariety,
      'sizeThickness': item.sizeThickness,
      'pieces': item.pieces,
      'squareFeet': item.squareFeet,
      if (item.piecesDelivered != null) 'piecesDelivered': item.piecesDelivered,
      if (item.squareFeetDelivered != null)
        'squareFeetDelivered': item.squareFeetDelivered,
      // Legacy fields for older clients.
      'quantity': item.squareFeet,
      'quantityUnit': SalesQuantityUnit.sqFt.firestoreValue,
      if (item.squareFeetDelivered != null)
        'quantityDelivered': item.squareFeetDelivered,
    };
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'deliveryNumber': deliveryNumber,
      'factoryId': factoryId,
      'salesOrderId': salesOrderId,
      'salesOrderNumber': salesOrderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'deliveryAddress': deliveryAddress,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'status': status.firestoreValue,
      'lineItems': lineItems.map(_lineItemToMap).toList(),
      if (vehicleNumber != null && vehicleNumber!.isNotEmpty)
        'vehicleNumber': vehicleNumber,
      if (driverName != null && driverName!.isNotEmpty) 'driverName': driverName,
      if (driverEmployeeId != null && driverEmployeeId!.isNotEmpty)
        'driverEmployeeId': driverEmployeeId,
      if (loadingSupervisor != null && loadingSupervisor!.isNotEmpty)
        'loadingSupervisor': loadingSupervisor,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (actualDeliveryDate != null)
        'actualDeliveryDate': Timestamp.fromDate(actualDeliveryDate!),
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Delivery toEntity() => Delivery(
        id: id,
        deliveryNumber: deliveryNumber,
        factoryId: factoryId,
        salesOrderId: salesOrderId,
        salesOrderNumber: salesOrderNumber,
        customerId: customerId,
        customerName: customerName,
        deliveryAddress: deliveryAddress,
        scheduledDate: scheduledDate,
        status: status,
        lineItems: lineItems,
        vehicleNumber: vehicleNumber,
        driverName: driverName,
        driverEmployeeId: driverEmployeeId,
        loadingSupervisor: loadingSupervisor,
        notes: notes,
        actualDeliveryDate: actualDeliveryDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory DeliveryModel.fromEntity(Delivery delivery) => DeliveryModel(
        id: delivery.id,
        deliveryNumber: delivery.deliveryNumber,
        factoryId: delivery.factoryId,
        salesOrderId: delivery.salesOrderId,
        salesOrderNumber: delivery.salesOrderNumber,
        customerId: delivery.customerId,
        customerName: delivery.customerName,
        deliveryAddress: delivery.deliveryAddress,
        scheduledDate: delivery.scheduledDate,
        status: delivery.status,
        lineItems: delivery.lineItems,
        vehicleNumber: delivery.vehicleNumber,
        driverName: delivery.driverName,
        driverEmployeeId: delivery.driverEmployeeId,
        loadingSupervisor: delivery.loadingSupervisor,
        notes: delivery.notes,
        actualDeliveryDate: delivery.actualDeliveryDate,
        createdAt: delivery.createdAt,
        updatedAt: delivery.updatedAt,
      );
}
