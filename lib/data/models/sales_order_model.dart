import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/sales_order.dart';
import '../../domain/enums/customer_enums.dart';
import '../../domain/enums/sales_enums.dart';

class SalesOrderModel {
  const SalesOrderModel({
    required this.id,
    required this.orderNumber,
    required this.factoryId,
    required this.customerId,
    required this.customerName,
    required this.status,
    required this.orderDate,
    required this.orderSource,
    required this.lineItems,
    required this.subtotal,
    required this.orderDiscount,
    required this.tax,
    required this.grandTotal,
    required this.paymentTerms,
    required this.advanceReceived,
    required this.balanceDue,
    required this.createdAt,
    this.deliveryAddress,
    this.expectedDeliveryDate,
    this.paymentDueDate,
    this.specialInstructions,
    this.invoiceId,
    this.closedAt,
    this.updatedAt,
  });

  final String id;
  final String orderNumber;
  final String factoryId;
  final String customerId;
  final String customerName;
  final SalesOrderStatus status;
  final DateTime orderDate;
  final SalesOrderSource orderSource;
  final String? deliveryAddress;
  final DateTime? expectedDeliveryDate;
  final List<SalesOrderLineItem> lineItems;
  final double subtotal;
  final double orderDiscount;
  final double tax;
  final double grandTotal;
  final PaymentTerms paymentTerms;
  final double advanceReceived;
  final double balanceDue;
  final DateTime? paymentDueDate;
  final String? specialInstructions;
  final String? invoiceId;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory SalesOrderModel.fromFirestore(String id, Map<String, dynamic> data) {
    final items = (data['lineItems'] as List?) ?? const [];
    return SalesOrderModel(
      id: id,
      orderNumber: data['orderNumber'] as String? ?? '',
      factoryId: data['factoryId'] as String? ?? 'default',
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      status: SalesOrderStatus.fromString(data['status'] as String?),
      orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      orderSource: SalesOrderSource.fromString(data['orderSource'] as String?),
      deliveryAddress: data['deliveryAddress'] as String?,
      expectedDeliveryDate:
          (data['expectedDeliveryDate'] as Timestamp?)?.toDate(),
      lineItems: items.whereType<Map>().map(_lineItemFromMap).toList(),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      orderDiscount: (data['orderDiscount'] as num?)?.toDouble() ?? 0,
      tax: (data['tax'] as num?)?.toDouble() ?? 0,
      grandTotal: (data['grandTotal'] as num?)?.toDouble() ?? 0,
      paymentTerms: PaymentTerms.fromString(data['paymentTerms'] as String?),
      advanceReceived: (data['advanceReceived'] as num?)?.toDouble() ?? 0,
      balanceDue: (data['balanceDue'] as num?)?.toDouble() ?? 0,
      paymentDueDate: (data['paymentDueDate'] as Timestamp?)?.toDate(),
      specialInstructions: data['specialInstructions'] as String?,
      invoiceId: data['invoiceId'] as String?,
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static SalesOrderLineItem _lineItemFromMap(Map<dynamic, dynamic> data) {
    return SalesOrderLineItem(
      productType: SalesProductType.fromString(data['productType'] as String?),
      marbleVariety: data['marbleVariety'] as String? ?? '',
      sizeThickness: data['sizeThickness'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0,
      quantityUnit:
          SalesQuantityUnit.fromString(data['quantityUnit'] as String?),
      unitRate: (data['unitRate'] as num?)?.toDouble() ?? 0,
      discountPercent: (data['discountPercent'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'orderNumber': orderNumber,
      'factoryId': factoryId,
      'customerId': customerId,
      'customerName': customerName,
      'status': status.firestoreValue,
      'orderDate': Timestamp.fromDate(orderDate),
      'orderSource': orderSource.firestoreValue,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (expectedDeliveryDate != null)
        'expectedDeliveryDate': Timestamp.fromDate(expectedDeliveryDate!),
      'lineItems': lineItems
          .map(
            (item) => {
              'productType': item.productType.firestoreValue,
              'marbleVariety': item.marbleVariety,
              'sizeThickness': item.sizeThickness,
              'quantity': item.quantity,
              'quantityUnit': item.quantityUnit.firestoreValue,
              'unitRate': item.unitRate,
              'discountPercent': item.discountPercent,
              'lineTotal': item.lineTotal,
            },
          )
          .toList(),
      'subtotal': subtotal,
      'orderDiscount': orderDiscount,
      'tax': tax,
      'grandTotal': grandTotal,
      'paymentTerms': paymentTerms.name,
      'advanceReceived': advanceReceived,
      'balanceDue': balanceDue,
      if (paymentDueDate != null)
        'paymentDueDate': Timestamp.fromDate(paymentDueDate!),
      if (specialInstructions != null) 'specialInstructions': specialInstructions,
      if (invoiceId != null) 'invoiceId': invoiceId,
      if (closedAt != null) 'closedAt': Timestamp.fromDate(closedAt!),
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  SalesOrder toEntity() => SalesOrder(
        id: id,
        orderNumber: orderNumber,
        factoryId: factoryId,
        customerId: customerId,
        customerName: customerName,
        status: status,
        orderDate: orderDate,
        orderSource: orderSource,
        deliveryAddress: deliveryAddress,
        expectedDeliveryDate: expectedDeliveryDate,
        lineItems: lineItems,
        subtotal: subtotal,
        orderDiscount: orderDiscount,
        tax: tax,
        grandTotal: grandTotal,
        paymentTerms: paymentTerms,
        advanceReceived: advanceReceived,
        balanceDue: balanceDue,
        paymentDueDate: paymentDueDate,
        specialInstructions: specialInstructions,
        invoiceId: invoiceId,
        closedAt: closedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory SalesOrderModel.fromEntity(SalesOrder order) => SalesOrderModel(
        id: order.id,
        orderNumber: order.orderNumber,
        factoryId: order.factoryId,
        customerId: order.customerId,
        customerName: order.customerName,
        status: order.status,
        orderDate: order.orderDate,
        orderSource: order.orderSource,
        deliveryAddress: order.deliveryAddress,
        expectedDeliveryDate: order.expectedDeliveryDate,
        lineItems: order.lineItems,
        subtotal: order.subtotal,
        orderDiscount: order.orderDiscount,
        tax: order.tax,
        grandTotal: order.grandTotal,
        paymentTerms: order.paymentTerms,
        advanceReceived: order.advanceReceived,
        balanceDue: order.balanceDue,
        paymentDueDate: order.paymentDueDate,
        specialInstructions: order.specialInstructions,
        invoiceId: order.invoiceId,
        closedAt: order.closedAt,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
      );
}
