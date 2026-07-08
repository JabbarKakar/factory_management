import 'package:equatable/equatable.dart';

import '../../core/constants/job_work_sizes.dart';
import '../../core/utils/stock_output_calculator.dart';
import '../enums/customer_enums.dart';
import '../enums/sales_enums.dart';
import 'stock_output.dart';

class SalesOrderLineItem extends Equatable {
  const SalesOrderLineItem({
    required this.productType,
    required this.marbleVariety,
    this.smallStockOutputs = const [],
    this.largeStockOutputs = const [],
    this.smallPricePerSqFt = 0,
    this.largePricePerSqFt = 0,
  });

  final SalesProductType productType;
  final String marbleVariety;
  final List<StockOutput> smallStockOutputs;
  final List<StockOutput> largeStockOutputs;
  final double smallPricePerSqFt;
  final double largePricePerSqFt;

  List<StockOutput> get activeSmallOutputs =>
      smallStockOutputs.where((output) => output.hasEntry).toList();

  List<StockOutput> get activeLargeOutputs =>
      largeStockOutputs.where((output) => output.hasEntry).toList();

  List<StockOutput> get activeOutputs => [
        ...activeSmallOutputs,
        ...activeLargeOutputs,
      ];

  int get totalPieces => StockOutputCalculator.totalPieces(activeOutputs);

  double get totalSquareFeet =>
      StockOutputCalculator.totalSquareFeet(activeOutputs);

  double get smallTotalAmount =>
      StockOutputCalculator.grandTotal(activeSmallOutputs);

  double get largeTotalAmount =>
      StockOutputCalculator.grandTotal(activeLargeOutputs);

  double get lineTotal => StockOutputCalculator.grandTotal(activeOutputs);

  bool get hasContent => activeOutputs.isNotEmpty && lineTotal > 0;

  /// Legacy delivery/invoice helpers — aggregate sq ft at line level.
  double get quantity => totalSquareFeet;

  SalesQuantityUnit get quantityUnit => SalesQuantityUnit.sqFt;

  String get sizeThickness => JobWorkSizes.joinForDisplay(
        smallSizes: activeSmallOutputs.map((o) => o.size).toList(),
        largeSizes: activeLargeOutputs.map((o) => o.size).toList(),
      );

  double get unitRate => totalSquareFeet > 0 ? lineTotal / totalSquareFeet : 0;

  double get discountPercent => 0;

  /// Per-size rows for delivery matching.
  List<StockOutput> get stockRows => activeOutputs;

  SalesOrderLineItem copyWith({
    SalesProductType? productType,
    String? marbleVariety,
    List<StockOutput>? smallStockOutputs,
    List<StockOutput>? largeStockOutputs,
    double? smallPricePerSqFt,
    double? largePricePerSqFt,
  }) {
    return SalesOrderLineItem(
      productType: productType ?? this.productType,
      marbleVariety: marbleVariety ?? this.marbleVariety,
      smallStockOutputs: smallStockOutputs ?? this.smallStockOutputs,
      largeStockOutputs: largeStockOutputs ?? this.largeStockOutputs,
      smallPricePerSqFt: smallPricePerSqFt ?? this.smallPricePerSqFt,
      largePricePerSqFt: largePricePerSqFt ?? this.largePricePerSqFt,
    );
  }

  @override
  List<Object?> get props => [
        productType,
        marbleVariety,
        smallStockOutputs,
        largeStockOutputs,
        smallPricePerSqFt,
        largePricePerSqFt,
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

  int get totalPieces =>
      lineItems.fold<int>(0, (sum, item) => sum + item.totalPieces);

  double get totalSquareFeet =>
      lineItems.fold<double>(0, (sum, item) => sum + item.totalSquareFeet);

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
    DateTime? closedAt,
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
      closedAt: closedAt ?? this.closedAt,
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
        closedAt,
        createdAt,
        updatedAt,
      ];
}
