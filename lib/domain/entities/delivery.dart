import 'package:equatable/equatable.dart';

import '../enums/delivery_enums.dart';
import '../enums/sales_enums.dart';

class DeliveryLineItem extends Equatable {
  const DeliveryLineItem({
    required this.productType,
    required this.marbleVariety,
    required this.sizeThickness,
    required this.quantity,
    required this.quantityUnit,
    this.quantityDelivered,
  });

  final SalesProductType productType;
  final String marbleVariety;
  final String sizeThickness;
  final double quantity;
  final SalesQuantityUnit quantityUnit;
  final double? quantityDelivered;

  String get displayLabel {
    final parts = [
      productType.label,
      marbleVariety,
      sizeThickness,
    ].where((part) => part.isNotEmpty);
    return parts.join(' · ');
  }

  double get effectiveDelivered => quantityDelivered ?? quantity;

  bool get isPartiallyFulfilled =>
      quantityDelivered != null && quantityDelivered! < quantity;

  DeliveryLineItem copyWith({
    SalesProductType? productType,
    String? marbleVariety,
    String? sizeThickness,
    double? quantity,
    SalesQuantityUnit? quantityUnit,
    double? quantityDelivered,
    bool clearQuantityDelivered = false,
  }) {
    return DeliveryLineItem(
      productType: productType ?? this.productType,
      marbleVariety: marbleVariety ?? this.marbleVariety,
      sizeThickness: sizeThickness ?? this.sizeThickness,
      quantity: quantity ?? this.quantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      quantityDelivered:
          clearQuantityDelivered ? null : (quantityDelivered ?? this.quantityDelivered),
    );
  }

  @override
  List<Object?> get props => [
        productType,
        marbleVariety,
        sizeThickness,
        quantity,
        quantityUnit,
        quantityDelivered,
      ];
}

class Delivery extends Equatable {
  const Delivery({
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
    this.driverName,
    this.driverEmployeeId,
    this.vehicleNumber,
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

  double get totalQuantity =>
      lineItems.fold<double>(0, (sum, item) => sum + item.quantity);

  Delivery copyWith({
    String? id,
    String? deliveryNumber,
    String? factoryId,
    String? salesOrderId,
    String? salesOrderNumber,
    String? customerId,
    String? customerName,
    String? deliveryAddress,
    DateTime? scheduledDate,
    DeliveryStatus? status,
    List<DeliveryLineItem>? lineItems,
    String? vehicleNumber,
    String? driverName,
    String? driverEmployeeId,
    String? loadingSupervisor,
    String? notes,
    DateTime? actualDeliveryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Delivery(
      id: id ?? this.id,
      deliveryNumber: deliveryNumber ?? this.deliveryNumber,
      factoryId: factoryId ?? this.factoryId,
      salesOrderId: salesOrderId ?? this.salesOrderId,
      salesOrderNumber: salesOrderNumber ?? this.salesOrderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      lineItems: lineItems ?? this.lineItems,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      driverName: driverName ?? this.driverName,
      driverEmployeeId: driverEmployeeId ?? this.driverEmployeeId,
      loadingSupervisor: loadingSupervisor ?? this.loadingSupervisor,
      notes: notes ?? this.notes,
      actualDeliveryDate: actualDeliveryDate ?? this.actualDeliveryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        deliveryNumber,
        factoryId,
        salesOrderId,
        salesOrderNumber,
        customerId,
        customerName,
        deliveryAddress,
        scheduledDate,
        status,
        lineItems,
        vehicleNumber,
        driverName,
        driverEmployeeId,
        loadingSupervisor,
        notes,
        actualDeliveryDate,
        createdAt,
        updatedAt,
      ];
}
