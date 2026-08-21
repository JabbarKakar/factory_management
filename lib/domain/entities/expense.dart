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
    this.paidAmount = 0.0,
    this.dueAmount,
    this.paymentStatus = ExpensePaymentStatus.paid,
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
  final double paidAmount;
  final double? dueAmount;
  final ExpensePaymentStatus paymentStatus;
  final String? payeeName;
  final String? supplierId;
  final String? billNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  double get totalAmount => amount;

  double get effectiveDueAmount =>
      dueAmount ?? (amount - paidAmount).clamp(0.0, double.infinity);

  bool get isFullyPaid =>
      paymentStatus == ExpensePaymentStatus.paid || effectiveDueAmount <= 0.005;

  bool get isUnpaid =>
      paymentStatus == ExpensePaymentStatus.unpaid || paidAmount <= 0.005;

  bool get isPartiallyPaid =>
      paymentStatus == ExpensePaymentStatus.partiallyPaid ||
      (paidAmount > 0.005 && effectiveDueAmount > 0.005);

  bool get isPaidInstantly => paidAmount >= amount && amount > 0;

  Expense copyWith({
    String? id,
    String? expenseNumber,
    String? factoryId,
    DateTime? expenseDate,
    ExpenseCategory? category,
    String? description,
    double? amount,
    PaymentMethod? paymentMethod,
    double? paidAmount,
    double? dueAmount,
    ExpensePaymentStatus? paymentStatus,
    String? payeeName,
    String? supplierId,
    String? billNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final newAmount = amount ?? this.amount;
    final newPaid = paidAmount ?? this.paidAmount;
    return Expense(
      id: id ?? this.id,
      expenseNumber: expenseNumber ?? this.expenseNumber,
      factoryId: factoryId ?? this.factoryId,
      expenseDate: expenseDate ?? this.expenseDate,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: newAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAmount: newPaid,
      dueAmount: dueAmount ?? (newAmount - newPaid).clamp(0.0, double.infinity),
      paymentStatus: paymentStatus ??
          ExpensePaymentStatus.fromAmounts(
            totalAmount: newAmount,
            paidAmount: newPaid,
          ),
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
        paidAmount,
        dueAmount,
        paymentStatus,
        payeeName,
        supplierId,
        billNumber,
        notes,
        createdAt,
        updatedAt,
      ];
}
