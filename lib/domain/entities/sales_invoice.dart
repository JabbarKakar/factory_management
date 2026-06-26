import 'package:equatable/equatable.dart';

import '../enums/invoice_enums.dart';
import 'job_work_invoice.dart';

class SalesInvoice extends Equatable {
  const SalesInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.factoryId,
    required this.salesOrderId,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.lineItems,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.status,
    required this.createdAt,
    this.dueDate,
    this.updatedAt,
  });

  final String id;
  final String invoiceNumber;
  final String factoryId;
  final String salesOrderId;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final List<InvoiceLineItem> lineItems;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final DateTime? dueDate;
  final InvoiceStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SalesInvoice copyWith({
    String? id,
    String? invoiceNumber,
    String? factoryId,
    String? salesOrderId,
    String? orderNumber,
    String? customerId,
    String? customerName,
    List<InvoiceLineItem>? lineItems,
    double? totalAmount,
    double? paidAmount,
    double? dueAmount,
    DateTime? dueDate,
    InvoiceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SalesInvoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      factoryId: factoryId ?? this.factoryId,
      salesOrderId: salesOrderId ?? this.salesOrderId,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      lineItems: lineItems ?? this.lineItems,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        invoiceNumber,
        factoryId,
        salesOrderId,
        orderNumber,
        customerId,
        customerName,
        lineItems,
        totalAmount,
        paidAmount,
        dueAmount,
        dueDate,
        status,
        createdAt,
        updatedAt,
      ];
}
