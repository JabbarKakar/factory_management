import 'package:equatable/equatable.dart';

import '../enums/expense_enums.dart';
import '../enums/invoice_enums.dart';

class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.expenseNumber,
    required this.factoryId,
    required this.expenseDate,
    required this.category,
    required this.description,
    required this.amount,
    required this.paymentMethod,
    required this.createdAt,
    this.payeeName,
    this.supplierId,
    this.billNumber,
    this.notes,
    this.updatedAt,
  });

  final String id;
  final String expenseNumber;
  final String factoryId;
  final DateTime expenseDate;
  final ExpenseCategory category;
  final String description;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? payeeName;
  final String? supplierId;
  final String? billNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Expense copyWith({
    String? id,
    String? expenseNumber,
    String? factoryId,
    DateTime? expenseDate,
    ExpenseCategory? category,
    String? description,
    double? amount,
    PaymentMethod? paymentMethod,
    String? payeeName,
    String? supplierId,
    String? billNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      expenseNumber: expenseNumber ?? this.expenseNumber,
      factoryId: factoryId ?? this.factoryId,
      expenseDate: expenseDate ?? this.expenseDate,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      payeeName: payeeName ?? this.payeeName,
      supplierId: supplierId ?? this.supplierId,
      billNumber: billNumber ?? this.billNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        expenseNumber,
        factoryId,
        expenseDate,
        category,
        description,
        amount,
        paymentMethod,
        payeeName,
        supplierId,
        billNumber,
        notes,
        createdAt,
        updatedAt,
      ];
}
