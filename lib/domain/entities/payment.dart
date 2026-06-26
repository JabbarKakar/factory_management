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
