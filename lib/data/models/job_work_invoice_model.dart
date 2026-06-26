import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/job_work_invoice.dart';
import '../../domain/enums/invoice_enums.dart';

class JobWorkInvoiceModel {
  const JobWorkInvoiceModel({
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

  factory JobWorkInvoiceModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final items = (data['items'] as List?) ?? const [];
    return JobWorkInvoiceModel(
      id: id,
      invoiceNumber: data['invoiceNumber'] as String? ?? '',
      factoryId: data['factoryId'] as String? ?? 'default',
      jobWorkId: data['jobWorkId'] as String? ?? '',
      jobWorkNumber: data['jobWorkNumber'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      lineItems: items
          .whereType<Map>()
          .map(
            (item) => InvoiceLineItem(
              description: item['description'] as String? ?? '',
              amount: (item['amount'] as num?)?.toDouble() ?? 0,
            ),
          )
          .toList(),
      totalAmount: (data['total'] as num?)?.toDouble() ?? 0,
      paidAmount: (data['paid'] as num?)?.toDouble() ?? 0,
      dueAmount: (data['due'] as num?)?.toDouble() ?? 0,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      status: InvoiceStatus.fromString(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'invoiceNumber': invoiceNumber,
      'factoryId': factoryId,
      'jobWorkId': jobWorkId,
      'jobWorkNumber': jobWorkNumber,
      'customerId': customerId,
      'customerName': customerName,
      'items': lineItems
          .map(
            (item) => {
              'description': item.description,
              'amount': item.amount,
            },
          )
          .toList(),
      'total': totalAmount,
      'paid': paidAmount,
      'due': dueAmount,
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      'status': status.firestoreValue,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  JobWorkInvoice toEntity() {
    return JobWorkInvoice(
      id: id,
      invoiceNumber: invoiceNumber,
      factoryId: factoryId,
      jobWorkId: jobWorkId,
      jobWorkNumber: jobWorkNumber,
      customerId: customerId,
      customerName: customerName,
      lineItems: lineItems,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      dueAmount: dueAmount,
      dueDate: dueDate,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory JobWorkInvoiceModel.fromEntity(JobWorkInvoice invoice) {
    return JobWorkInvoiceModel(
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      factoryId: invoice.factoryId,
      jobWorkId: invoice.jobWorkId,
      jobWorkNumber: invoice.jobWorkNumber,
      customerId: invoice.customerId,
      customerName: invoice.customerName,
      lineItems: invoice.lineItems,
      totalAmount: invoice.totalAmount,
      paidAmount: invoice.paidAmount,
      dueAmount: invoice.dueAmount,
      dueDate: invoice.dueDate,
      status: invoice.status,
      createdAt: invoice.createdAt,
      updatedAt: invoice.updatedAt,
    );
  }
}
