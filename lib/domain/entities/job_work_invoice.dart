import 'package:equatable/equatable.dart';

import '../enums/invoice_enums.dart';

class InvoiceLineItem extends Equatable {
  const InvoiceLineItem({
    required this.description,
    required this.amount,
  });

  final String description;
  final double amount;

  @override
  List<Object?> get props => [description, amount];
}

class JobWorkInvoice extends Equatable {
  const JobWorkInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.factoryId,
    required this.jobWorkId,
    required this.jobWorkNumber,
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
  final String jobWorkId;
  final String jobWorkNumber;
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

  JobWorkInvoice copyWith({
    String? id,
    String? invoiceNumber,
    String? factoryId,
    String? jobWorkId,
    String? jobWorkNumber,
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
    return JobWorkInvoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      factoryId: factoryId ?? this.factoryId,
      jobWorkId: jobWorkId ?? this.jobWorkId,
      jobWorkNumber: jobWorkNumber ?? this.jobWorkNumber,
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
        jobWorkId,
        jobWorkNumber,
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
