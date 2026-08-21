import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/expense_payment.dart';
import '../../domain/enums/invoice_enums.dart';

class ExpensePaymentModel {
  const ExpensePaymentModel({
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

  factory ExpensePaymentModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return ExpensePaymentModel(
      id: id,
      factoryId: data['factoryId'] as String? ?? 'default',
      expenseId: data['expenseId'] as String? ?? '',
      expenseNumber: data['expenseNumber'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      method: PaymentMethod.fromString(data['method'] as String?),
      paymentDate:
          (data['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      supplierId: data['supplierId'] as String?,
      payeeName: data['payeeName'] as String?,
      reference: data['reference'] as String?,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'factoryId': factoryId,
      'expenseId': expenseId,
      'expenseNumber': expenseNumber,
      'amount': amount,
      'method': method.firestoreValue,
      'paymentDate': Timestamp.fromDate(paymentDate),
      if (supplierId != null && supplierId!.isNotEmpty) 'supplierId': supplierId,
      if (payeeName != null && payeeName!.isNotEmpty) 'payeeName': payeeName,
      if (reference != null && reference!.isNotEmpty) 'reference': reference,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ExpensePayment toEntity() => ExpensePayment(
        id: id,
        factoryId: factoryId,
        expenseId: expenseId,
        expenseNumber: expenseNumber,
        amount: amount,
        method: method,
        paymentDate: paymentDate,
        createdAt: createdAt,
        supplierId: supplierId,
        payeeName: payeeName,
        reference: reference,
        notes: notes,
      );

  factory ExpensePaymentModel.fromEntity(ExpensePayment payment) =>
      ExpensePaymentModel(
        id: payment.id,
        factoryId: payment.factoryId,
        expenseId: payment.expenseId,
        expenseNumber: payment.expenseNumber,
        amount: payment.amount,
        method: payment.method,
        paymentDate: paymentDateFix(payment.paymentDate),
        createdAt: payment.createdAt,
        supplierId: payment.supplierId,
        payeeName: payment.payeeName,
        reference: payment.reference,
        notes: payment.notes,
      );

  static DateTime paymentDateFix(DateTime dt) => dt;
}
