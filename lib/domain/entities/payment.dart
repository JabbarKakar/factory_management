import 'package:equatable/equatable.dart';

import '../enums/invoice_enums.dart';

class Payment extends Equatable {
  const Payment({
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

  Payment copyWith({
    String? id,
    String? factoryId,
    String? customerId,
    String? customerName,
    String? invoiceId,
    InvoiceType? invoiceType,
    String? invoiceNumber,
    double? amount,
    PaymentMethod? method,
    DateTime? paymentDate,
    String? reference,
    String? notes,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      factoryId: factoryId ?? this.factoryId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceType: invoiceType ?? this.invoiceType,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      paymentDate: paymentDate ?? this.paymentDate,
      reference: reference,
      notes: notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        factoryId,
        customerId,
        customerName,
        invoiceId,
        invoiceType,
        invoiceNumber,
        amount,
        method,
        paymentDate,
        reference,
        notes,
        createdAt,
      ];
}
