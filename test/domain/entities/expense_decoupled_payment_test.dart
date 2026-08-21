import 'package:factory_management/data/models/expense_model.dart';
import 'package:factory_management/data/models/expense_payment_model.dart';
import 'package:factory_management/domain/entities/expense.dart';
import 'package:factory_management/domain/entities/expense_payment.dart';
import 'package:factory_management/domain/enums/expense_enums.dart';
import 'package:factory_management/domain/enums/invoice_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Expense & ExpensePayment Entities and Models', () {
    test('creates unpaid expense with zero paidAmount and full dueAmount', () {
      final expense = Expense(
        id: 'exp-1',
        expenseNumber: 'EXP-2026-0001',
        factoryId: 'factory-1',
        expenseDate: DateTime(2026, 2, 1),
        category: ExpenseCategory.rawMaterialPurchase,
        description: 'Marble block purchase',
        amount: 100000,
        paymentMethod: PaymentMethod.cash,
        paidAmount: 0.0,
        dueAmount: 100000,
        paymentStatus: ExpensePaymentStatus.unpaid,
        createdAt: DateTime(2026, 2, 1),
      );

      expect(expense.isUnpaid, isTrue);
      expect(expense.isFullyPaid, isFalse);
      expect(expense.isPartiallyPaid, isFalse);
      expect(expense.effectiveDueAmount, 100000);
      expect(expense.totalAmount, 100000);
    });

    test('creates partially paid and fully paid expense accurately', () {
      final partialExpense = Expense(
        id: 'exp-2',
        expenseNumber: 'EXP-2026-0002',
        factoryId: 'factory-1',
        expenseDate: DateTime(2026, 2, 1),
        category: ExpenseCategory.rawMaterialPurchase,
        description: 'Blades purchase',
        amount: 100000,
        paymentMethod: PaymentMethod.bankTransfer,
        paidAmount: 40000,
        dueAmount: 60000,
        paymentStatus: ExpensePaymentStatus.partiallyPaid,
        createdAt: DateTime(2026, 2, 1),
      );

      expect(partialExpense.isPartiallyPaid, isTrue);
      expect(partialExpense.isUnpaid, isFalse);
      expect(partialExpense.isFullyPaid, isFalse);
      expect(partialExpense.effectiveDueAmount, 60000);

      final paidExpense = partialExpense.copyWith(
        paidAmount: 100000,
        dueAmount: 0,
        paymentStatus: ExpensePaymentStatus.paid,
      );

      expect(paidExpense.isFullyPaid, isTrue);
      expect(paidExpense.isPartiallyPaid, isFalse);
      expect(paidExpense.effectiveDueAmount, 0);
    });

    test('ExpenseModel fromFirestore backward compatibility with legacy docs', () {
      final legacyData = {
        'expenseNumber': 'EXP-2025-0099',
        'factoryId': 'factory-1',
        'amount': 50000,
        'category': 'electricity',
        'description': 'Electricity bill',
        'paymentMethod': 'cash',
      };

      final model = ExpenseModel.fromFirestore('exp-legacy', legacyData);
      final entity = model.toEntity();

      expect(entity.amount, 50000);
      expect(entity.paidAmount, 50000);
      expect(entity.effectiveDueAmount, 0);
      expect(entity.paymentStatus, ExpensePaymentStatus.paid);
      expect(entity.isFullyPaid, isTrue);
    });

    test('ExpenseModel toFirestore serialization includes payment status and amounts', () {
      final expense = Expense(
        id: 'exp-3',
        expenseNumber: 'EXP-2026-0003',
        factoryId: 'factory-1',
        expenseDate: DateTime(2026, 2, 10),
        category: ExpenseCategory.rawMaterialPurchase,
        description: 'Sand bags',
        amount: 25000,
        paymentMethod: PaymentMethod.cash,
        paidAmount: 5000,
        dueAmount: 20000,
        paymentStatus: ExpensePaymentStatus.partiallyPaid,
        createdAt: DateTime(2026, 2, 10),
      );

      final model = ExpenseModel.fromEntity(expense);
      final firestoreData = model.toFirestore();

      expect(firestoreData['amount'], 25000);
      expect(firestoreData['paidAmount'], 5000);
      expect(firestoreData['dueAmount'], 20000);
      expect(firestoreData['paymentStatus'], 'partiallyPaid');
    });

    test('ExpensePayment entity and model serialization', () {
      final payment = ExpensePayment(
        id: 'pay-1',
        factoryId: 'factory-1',
        expenseId: 'exp-3',
        expenseNumber: 'EXP-2026-0003',
        supplierId: 'sup-1',
        amount: 5000,
        method: PaymentMethod.bankTransfer,
        paymentDate: DateTime(2026, 2, 11),
        reference: 'TRX-12345',
        notes: 'First installment',
        createdAt: DateTime(2026, 2, 11),
      );

      final model = ExpensePaymentModel.fromEntity(payment);
      final data = model.toFirestore();

      expect(data['expenseId'], 'exp-3');
      expect(data['amount'], 5000);
      expect(data['method'], 'bankTransfer');
      expect(data['reference'], 'TRX-12345');

      final roundTrip = ExpensePaymentModel.fromFirestore('pay-1', data).toEntity();
      expect(roundTrip.id, 'pay-1');
      expect(roundTrip.amount, 5000);
      expect(roundTrip.method, PaymentMethod.bankTransfer);
      expect(roundTrip.reference, 'TRX-12345');
    });
  });
}
