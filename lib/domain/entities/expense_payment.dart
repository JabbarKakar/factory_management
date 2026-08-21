import 'package:equatable/equatable.dart';

import '../enums/invoice_enums.dart';

class ExpensePayment extends Equatable {
  const ExpensePayment({
    required this.id,
    required this.factoryId,
    required this.expenseId,
    required this.expenseNumber,
    required this.amount,
    required this.method,
    required this.paymentDate,
    required this.createdAt,
    this.supplierId,
    this.payeeName,
    this.reference,
    this.notes,
  });

  final String id;
  final String factoryId;
  final String expenseId;
  final String expenseNumber;
  final double amount;
  final PaymentMethod method;
  final DateTime paymentDate;
  final DateTime createdAt;
  final String? supplierId;
  final String? payeeName;
  final String? reference;
  final String? notes;

  ExpensePayment copyWith({
    String? id,
    String? factoryId,
    String? expenseId,
    String? expenseNumber,
    double? amount,
    PaymentMethod? method,
    DateTime? paymentDate,
    DateTime? createdAt,
    String? supplierId,
    String? payeeName,
    String? reference,
    String? notes,
  }) {
    return ExpensePayment(
      id: id ?? this.id,
      factoryId: factoryId ?? this.factoryId,
      expenseId: expenseId ?? this.expenseId,
      expenseNumber: expenseNumber ?? this.expenseNumber,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
      supplierId: supplierId ?? this.supplierId,
      payeeName: payeeName ?? this.payeeName,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        factoryId,
        expenseId,
        expenseNumber,
        amount,
        method,
        paymentDate,
        createdAt,
        supplierId,
        payeeName,
        reference,
        notes,
      ];
}
