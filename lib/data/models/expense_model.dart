import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/expense.dart';
import '../../domain/enums/expense_enums.dart';
import '../../domain/enums/invoice_enums.dart';

class ExpenseModel {
  const ExpenseModel({
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

  factory ExpenseModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ExpenseModel(
      id: id,
      expenseNumber: data['expenseNumber'] as String? ?? '',
      factoryId: data['factoryId'] as String? ?? 'default',
      expenseDate:
          (data['expenseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: ExpenseCategory.fromString(data['category'] as String?),
      description: data['description'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod:
          PaymentMethod.fromString(data['paymentMethod'] as String?),
      payeeName: data['payeeName'] as String?,
      supplierId: data['supplierId'] as String?,
      billNumber: data['billNumber'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'expenseNumber': expenseNumber,
      'factoryId': factoryId,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'category': category.firestoreValue,
      'description': description,
      'amount': amount,
      'paymentMethod': paymentMethod.firestoreValue,
      if (payeeName != null && payeeName!.isNotEmpty) 'payeeName': payeeName,
      if (supplierId != null && supplierId!.isNotEmpty) 'supplierId': supplierId,
      if (billNumber != null && billNumber!.isNotEmpty) 'billNumber': billNumber,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Expense toEntity() => Expense(
        id: id,
        expenseNumber: expenseNumber,
        factoryId: factoryId,
        expenseDate: expenseDate,
        category: category,
        description: description,
        amount: amount,
        paymentMethod: paymentMethod,
        payeeName: payeeName,
        supplierId: supplierId,
        billNumber: billNumber,
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory ExpenseModel.fromEntity(Expense expense) => ExpenseModel(
        id: expense.id,
        expenseNumber: expense.expenseNumber,
        factoryId: expense.factoryId,
        expenseDate: expense.expenseDate,
        category: expense.category,
        description: expense.description,
        amount: expense.amount,
        paymentMethod: expense.paymentMethod,
        payeeName: expense.payeeName,
        supplierId: expense.supplierId,
        billNumber: expense.billNumber,
        notes: expense.notes,
        createdAt: expense.createdAt,
        updatedAt: expense.updatedAt,
      );
}
