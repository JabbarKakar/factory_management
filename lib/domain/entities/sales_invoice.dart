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
    this.agreementId,
    this.agreementNumber,
    this.dueDate,
    this.updatedAt,
  });

  final String id;
  final String invoiceNumber;
  final String factoryId;

  /// Parent Agreement id (Phase 0). Optional on legacy invoices until backfill.
  final String? agreementId;
  final String? agreementNumber;

  /// Empty for Grand Sales Invoice; set for Single Order Invoice.
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

  bool get isGrandInvoice => salesOrderId.trim().isEmpty;

  SalesInvoice copyWith({
    String? id,
    String? invoiceNumber,
    String? factoryId,
    String? agreementId,
    String? agreementNumber,
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
      agreementId: agreementId ?? this.agreementId,
      agreementNumber: agreementNumber ?? this.agreementNumber,
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
        agreementId,
        agreementNumber,
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
