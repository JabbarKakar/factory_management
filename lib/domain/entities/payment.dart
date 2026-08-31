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
    double? appliedAmount,
    this.reference,
    this.notes,
    this.isAdvance = false,
    this.orderId,
    this.loadId,
    this.status = PaymentStatus.completed,
  }) : appliedAmount = appliedAmount ?? amount;

  final String id;
  final String factoryId;
  final String customerId;
  final String customerName;
  final String invoiceId;
  final InvoiceType invoiceType;
  final String invoiceNumber;

  /// Cash actually received. Credit applications use 0.
  final double amount;

  /// Portion of this row allocated to [invoiceId] / [loadId].
  /// Legacy rows omit the field; it then equals [amount].
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

  double get unallocatedAmount =>
      (amount - appliedAmount).clamp(0.0, double.infinity).toDouble();

  bool get isCreditApplication =>
      amount <= 0.005 && appliedAmount > 0.005;

  static double unallocatedTotal(Iterable<Payment> payments) {
    final valid = payments.where(
      (payment) => payment.status != PaymentStatus.voided,
    );
    final cash = valid.fold<double>(0, (sum, payment) => sum + payment.amount);
    final applied =
        valid.fold<double>(0, (sum, payment) => sum + payment.appliedAmount);
    return (cash - applied).clamp(0.0, double.infinity).toDouble();
  }

  Payment copyWith({
    String? id,
    String? factoryId,
    String? customerId,
    String? customerName,
    String? invoiceId,
    InvoiceType? invoiceType,
    String? invoiceNumber,
    double? amount,
    double? appliedAmount,
    PaymentMethod? method,
    DateTime? paymentDate,
    String? reference,
    String? notes,
    DateTime? createdAt,
    bool? isAdvance,
    String? orderId,
    String? loadId,
    PaymentStatus? status,
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
      appliedAmount: appliedAmount ?? this.appliedAmount,
      method: method ?? this.method,
      paymentDate: paymentDate ?? this.paymentDate,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isAdvance: isAdvance ?? this.isAdvance,
      orderId: orderId ?? this.orderId,
      loadId: loadId ?? this.loadId,
      status: status ?? this.status,
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
        appliedAmount,
        method,
        paymentDate,
        reference,
        notes,
        createdAt,
        isAdvance,
        orderId,
        loadId,
        status,
      ];
}
