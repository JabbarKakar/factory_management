import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/payment.dart';
import '../../domain/enums/invoice_enums.dart';

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.factoryId,
    required this.customerId,
    required this.customerName,
    required this.invoiceId,
    required this.invoiceType,
    required this.invoiceNumber,
    required this.amount,
    required this.method,
    required this.paymentDate,
    required this.createdAt,
    this.reference,
    this.notes,
  });

  final String id;
  final String factoryId;
  final String customerId;
  final String customerName;
  final String invoiceId;
  final InvoiceType invoiceType;
  final String invoiceNumber;
  final double amount;
  final PaymentMethod method;
  final DateTime paymentDate;
  final String? reference;
  final String? notes;
  final DateTime createdAt;

  factory PaymentModel.fromFirestore(String id, Map<String, dynamic> data) {
    return PaymentModel(
      id: id,
      factoryId: data['factoryId'] as String? ?? 'default',
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      invoiceId: data['invoiceId'] as String? ?? '',
      invoiceType: InvoiceType.fromString(data['invoiceType'] as String?),
      invoiceNumber: data['invoiceNumber'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      method: PaymentMethod.fromString(data['method'] as String?),
      paymentDate:
          (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reference: data['reference'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'factoryId': factoryId,
      'customerId': customerId,
      'customerName': customerName,
      'invoiceId': invoiceId,
      'invoiceType': invoiceType.firestoreValue,
      'invoiceNumber': invoiceNumber,
      'amount': amount,
      'method': method.firestoreValue,
      'date': Timestamp.fromDate(paymentDate),
      if (reference != null) 'reference': reference,
      if (notes != null) 'notes': notes,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Payment toEntity() {
    return Payment(
      id: id,
      factoryId: factoryId,
      customerId: customerId,
      customerName: customerName,
      invoiceId: invoiceId,
      invoiceType: invoiceType,
      invoiceNumber: invoiceNumber,
      amount: amount,
      method: method,
      paymentDate: paymentDate,
      reference: reference,
      notes: notes,
      createdAt: createdAt,
    );
  }
}
