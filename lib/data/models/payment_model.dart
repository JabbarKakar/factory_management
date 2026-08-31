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
    required this.appliedAmount,
    required this.method,
    required this.paymentDate,
    required this.createdAt,
    this.reference,
    this.notes,
    this.isAdvance = false,
    this.orderId,
    this.loadId,
    this.status = PaymentStatus.completed,
  });

  final String id;
  final String factoryId;
  final String customerId;
  final String customerName;
  final String invoiceId;
  final InvoiceType invoiceType;
  final String invoiceNumber;
  final double amount;
  final double appliedAmount;
  final PaymentMethod method;
  final DateTime paymentDate;
  final String? reference;
  final String? notes;
  final DateTime createdAt;
  final bool isAdvance;
  final String? orderId;
  final String? loadId;
  final PaymentStatus status;

  factory PaymentModel.fromFirestore(String id, Map<String, dynamic> data) {
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    return PaymentModel(
      id: id,
      factoryId: data['factoryId'] as String? ?? 'default',
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      invoiceId: data['invoiceId'] as String? ?? '',
      invoiceType: InvoiceType.fromString(data['invoiceType'] as String?),
      invoiceNumber: data['invoiceNumber'] as String? ?? '',
      amount: amount,
      appliedAmount: (data['appliedAmount'] as num?)?.toDouble() ?? amount,
      method: PaymentMethod.fromString(data['method'] as String?),
      paymentDate:
          (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reference: data['reference'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAdvance: data['isAdvance'] as bool? ?? false,
      orderId: data['orderId'] as String?,
      loadId: data['loadId'] as String?,
      status: PaymentStatus.fromString(data['status'] as String?),
    );
  }

  /// Invoice/load paid uses applied cash; missing field means the full amount.
  static double appliedFromFirestore(Map<String, dynamic> data) {
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    return (data['appliedAmount'] as num?)?.toDouble() ?? amount;
  }

  factory PaymentModel.fromEntity(Payment entity) {
    return PaymentModel(
      id: entity.id,
      factoryId: entity.factoryId,
      customerId: entity.customerId,
      customerName: entity.customerName,
      invoiceId: entity.invoiceId,
      invoiceType: entity.invoiceType,
      invoiceNumber: entity.invoiceNumber,
      amount: entity.amount,
      appliedAmount: entity.appliedAmount,
      method: entity.method,
      paymentDate: entity.paymentDate,
      reference: entity.reference,
      notes: entity.notes,
      createdAt: entity.createdAt,
      isAdvance: entity.isAdvance,
      orderId: entity.orderId,
      loadId: entity.loadId,
      status: entity.status,
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
      'appliedAmount': appliedAmount,
      'method': method.firestoreValue,
      'date': Timestamp.fromDate(paymentDate),
      if (reference != null) 'reference': reference,
      if (notes != null) 'notes': notes,
      if (isAdvance) 'isAdvance': true,
      if (orderId != null) 'orderId': orderId,
      if (loadId != null) 'loadId': loadId,
      'status': status.firestoreValue,
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
      appliedAmount: appliedAmount,
      method: method,
      paymentDate: paymentDate,
      reference: reference,
      notes: notes,
      createdAt: createdAt,
      isAdvance: isAdvance,
      orderId: orderId,
      loadId: loadId,
      status: status,
    );
  }
}
