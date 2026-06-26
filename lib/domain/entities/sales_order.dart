import 'package:equatable/equatable.dart';

import '../enums/customer_enums.dart';
import '../enums/sales_enums.dart';

class SalesOrderLineItem extends Equatable {
  const SalesOrderLineItem({
    required this.productType,
    required this.marbleVariety,
    required this.sizeThickness,
    required this.quantity,
    required this.quantityUnit,
    required this.unitRate,
    this.discountPercent = 0,
  });

  final SalesProductType productType;
  final String marbleVariety;
  final String sizeThickness;
  final double quantity;
  final SalesQuantityUnit quantityUnit;
  final double unitRate;
  final double discountPercent;

  double get lineTotal {
    final gross = quantity * unitRate;
    return gross - (gross * discountPercent / 100);
  }

  @override
  List<Object?> get props => [
        productType,
        marbleVariety,
        sizeThickness,
        quantity,
        quantityUnit,
        unitRate,
        discountPercent,
      ];
}

class SalesOrder extends Equatable {
  const SalesOrder({
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
  final DateTime createdAt;
  final DateTime? updatedAt;

  static double computeSubtotal(List<SalesOrderLineItem> items) {
    return items.fold<double>(0, (sum, item) => sum + item.lineTotal);
  }

  static double computeGrandTotal({
    required double subtotal,
    required double orderDiscount,
    required double tax,
  }) {
    return (subtotal - orderDiscount + tax).clamp(0, double.infinity);
  }

  SalesOrder copyWith({
    String? id,
    String? orderNumber,
    String? factoryId,
    String? customerId,
    String? customerName,
    SalesOrderStatus? status,
    DateTime? orderDate,
    SalesOrderSource? orderSource,
    String? deliveryAddress,
    DateTime? expectedDeliveryDate,
    List<SalesOrderLineItem>? lineItems,
    double? subtotal,
    double? orderDiscount,
    double? tax,
    double? grandTotal,
    PaymentTerms? paymentTerms,
    double? advanceReceived,
    double? balanceDue,
    DateTime? paymentDueDate,
    String? specialInstructions,
    String? invoiceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SalesOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      factoryId: factoryId ?? this.factoryId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      orderSource: orderSource ?? this.orderSource,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      lineItems: lineItems ?? this.lineItems,
      subtotal: subtotal ?? this.subtotal,
      orderDiscount: orderDiscount ?? this.orderDiscount,
      tax: tax ?? this.tax,
      grandTotal: grandTotal ?? this.grandTotal,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      advanceReceived: advanceReceived ?? this.advanceReceived,
      balanceDue: balanceDue ?? this.balanceDue,
      paymentDueDate: paymentDueDate ?? this.paymentDueDate,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      invoiceId: invoiceId ?? this.invoiceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        factoryId,
        customerId,
        customerName,
        status,
        orderDate,
        orderSource,
        deliveryAddress,
        expectedDeliveryDate,
        lineItems,
        subtotal,
        orderDiscount,
        tax,
        grandTotal,
        paymentTerms,
        advanceReceived,
        balanceDue,
        paymentDueDate,
        specialInstructions,
        invoiceId,
        createdAt,
        updatedAt,
      ];
}
