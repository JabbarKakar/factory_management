import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/observability/tracked_firestore.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_payment.dart';
import '../../domain/enums/document_sequence.dart';
import '../../domain/enums/expense_enums.dart';
import '../../domain/enums/invoice_enums.dart';
import '../models/expense_model.dart';
import '../models/expense_payment_model.dart';
import '../services/sequence_number_service.dart';

class ExpenseRepository {
  ExpenseRepository({
    FirebaseFirestore? firestore,
    SequenceNumberService? sequenceNumberService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _sequenceNumberService =
            sequenceNumberService ?? SequenceNumberService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final SequenceNumberService _sequenceNumberService;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get collection =>
      trackedCollection(_firestore, 'expenses');

  CollectionReference<Map<String, dynamic>> get paymentsCollection =>
      trackedCollection(_firestore, 'expense_payments');

  Stream<List<Expense>> watchExpenses(String factoryId) {
    return collection.where('factoryId', isEqualTo: factoryId).snapshots().map(
      (snapshot) {
        final expenses = snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc.id, doc.data()))
            .map((model) => model.toEntity())
            .toList();
        expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
        return expenses;
      },
    );
  }

  Future<Expense?> getExpense(String id) async {
    final doc = await collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return ExpenseModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Future<Expense> createExpense(
    Expense expense, {
    bool isPaidNow = false,
    double? initialPaidAmount,
    PaymentMethod? paymentMethod,
    DateTime? paymentDate,
    String? paymentReference,
    String? paymentNotes,
  }) async {
    final id = expense.id.isEmpty ? _uuid.v4() : expense.id;
    final expenseNumber = expense.expenseNumber.isEmpty
        ? await _generateExpenseNumber(expense.factoryId)
        : expense.expenseNumber;

    final method = paymentMethod ?? expense.paymentMethod;

    if (!isPaidNow) {
      // Unpaid bill / liability: 0 cash out
      final model = ExpenseModel.fromEntity(
        expense.copyWith(
          id: id,
          expenseNumber: expenseNumber,
          paymentMethod: method,
          paidAmount: 0.0,
          dueAmount: expense.amount,
          paymentStatus: ExpensePaymentStatus.unpaid,
        ),
      );

      await collection.doc(id).set(model.toFirestore(isCreate: true));
      try {
        final created = await getExpense(id);
        return created ?? model.toEntity();
      } catch (_) {
        return model.toEntity();
      }
    }

    // Instant payment on creation:
    final appliedPaid = (initialPaidAmount ?? expense.amount)
        .clamp(0.0, expense.amount);
    final due = (expense.amount - appliedPaid).clamp(0.0, double.infinity);
    final status = ExpensePaymentStatus.fromAmounts(
      totalAmount: expense.amount,
      paidAmount: appliedPaid,
    );

    final expenseModel = ExpenseModel.fromEntity(
      expense.copyWith(
        id: id,
        expenseNumber: expenseNumber,
        paymentMethod: method,
        paidAmount: appliedPaid,
        dueAmount: due,
        paymentStatus: status,
      ),
    );

    final batch = _firestore.batch();
    batch.set(collection.doc(id), expenseModel.toFirestore(isCreate: true));

    if (appliedPaid > 0) {
      final paymentId = _uuid.v4();
      final paymentModel = ExpensePaymentModel(
        id: paymentId,
        factoryId: expense.factoryId,
        expenseId: id,
        expenseNumber: expenseNumber,
        amount: appliedPaid,
        method: method,
        paymentDate: paymentDate ?? expense.expenseDate,
        createdAt: DateTime.now(),
        supplierId: expense.supplierId,
        payeeName: expense.payeeName,
        reference: paymentReference,
        notes: paymentNotes,
      );
      batch.set(
        paymentsCollection.doc(paymentId),
        paymentModel.toFirestore(isCreate: true),
      );
    }

    await batch.commit();
    try {
      final created = await getExpense(id);
      return created ?? expenseModel.toEntity();
    } catch (_) {
      return expenseModel.toEntity();
    }
  }

  Future<void> updateExpense(Expense expense) async {
    final model = ExpenseModel.fromEntity(expense);
    await collection.doc(expense.id).update(model.toFirestore());
  }

  Future<void> deleteExpense(String id) async {
    final batch = _firestore.batch();
    batch.delete(collection.doc(id));

    // Delete linked expense payments
    final payments = await paymentsCollection
        .where('expenseId', isEqualTo: id)
        .get();
    for (final doc in payments.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<ExpensePayment> recordExpensePayment({
    required String expenseId,
    required double amount,
    required PaymentMethod method,
    required DateTime paymentDate,
    String? reference,
    String? notes,
  }) async {
    if (amount <= 0) {
      throw StateError('Payment amount must be greater than zero.');
    }

    final paymentId = _uuid.v4();
    final paymentDocRef = paymentsCollection.doc(paymentId);
    final expenseDocRef = collection.doc(expenseId);

    final payment = await _firestore.runTransaction<ExpensePayment>((
      transaction,
    ) async {
      final expenseSnapshot = await transaction.get(expenseDocRef);
      if (!expenseSnapshot.exists || expenseSnapshot.data() == null) {
        throw StateError('Purchase record not found.');
      }

      final expense = ExpenseModel.fromFirestore(
        expenseSnapshot.id,
        expenseSnapshot.data()!,
      ).toEntity();

      if (expense.effectiveDueAmount <= 0.005) {
        throw StateError('This purchase is already fully paid.');
      }

      if (amount > expense.effectiveDueAmount + 0.005) {
        throw StateError(
          'Payment amount cannot exceed the remaining balance due '
          '(${expense.effectiveDueAmount.toStringAsFixed(0)} PKR).',
        );
      }

      final newPaidAmount = expense.paidAmount + amount;
      final newDueAmount =
          (expense.amount - newPaidAmount).clamp(0.0, double.infinity);
      final newStatus = ExpensePaymentStatus.fromAmounts(
        totalAmount: expense.amount,
        paidAmount: newPaidAmount,
      );

      transaction.update(expenseDocRef, {
        'paidAmount': newPaidAmount,
        'dueAmount': newDueAmount,
        'paymentStatus': newStatus.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final paymentModel = ExpensePaymentModel(
        id: paymentId,
        factoryId: expense.factoryId,
        expenseId: expense.id,
        expenseNumber: expense.expenseNumber,
        amount: amount,
        method: method,
        paymentDate: paymentDate,
        createdAt: DateTime.now(),
        supplierId: expense.supplierId,
        payeeName: expense.payeeName,
        reference: reference,
        notes: notes,
      );

      transaction.set(
        paymentDocRef,
        paymentModel.toFirestore(isCreate: true),
      );

      return paymentModel.toEntity();
    });

    return payment;
  }

  Stream<List<ExpensePayment>> watchExpensePayments(String expenseId) {
    return paymentsCollection
        .where('expenseId', isEqualTo: expenseId)
        .snapshots()
        .map((snapshot) {
          final payments = snapshot.docs
              .map((doc) =>
                  ExpensePaymentModel.fromFirestore(doc.id, doc.data())
                      .toEntity())
              .toList();
          payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
          return payments;
        });
  }

  Future<List<ExpensePayment>> getExpensePayments(String expenseId) async {
    final snapshot =
        await paymentsCollection.where('expenseId', isEqualTo: expenseId).get();
    final payments = snapshot.docs
        .map((doc) =>
            ExpensePaymentModel.fromFirestore(doc.id, doc.data()).toEntity())
        .toList();
    payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return payments;
  }

  Stream<List<ExpensePayment>> watchExpensePaymentsForFactory(String factoryId) {
    return paymentsCollection
        .where('factoryId', isEqualTo: factoryId)
        .snapshots()
        .map((snapshot) {
          final payments = snapshot.docs
              .map((doc) =>
                  ExpensePaymentModel.fromFirestore(doc.id, doc.data())
                      .toEntity())
              .toList();
          payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
          return payments;
        });
  }

  Future<List<Expense>> getExpenses(String factoryId) async {
    final snapshot =
        await collection.where('factoryId', isEqualTo: factoryId).get();
    final expenses = snapshot.docs
        .map((doc) => ExpenseModel.fromFirestore(doc.id, doc.data()).toEntity())
        .toList();
    expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return expenses;
  }

  Future<List<ExpensePayment>> getExpensePaymentsForFactory(
      String factoryId) async {
    final snapshot = await paymentsCollection
        .where('factoryId', isEqualTo: factoryId)
        .get();
    final payments = snapshot.docs
        .map((doc) =>
            ExpensePaymentModel.fromFirestore(doc.id, doc.data()).toEntity())
        .toList();
    payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return payments;
  }

  /// Failures propagate on purpose. The previous timestamp-based fallback hid
  /// outages by minting `EXP-<year>-<millis>`, which collides with the real
  /// series and produces duplicate expense numbers.
  Future<String> _generateExpenseNumber(String factoryId) {
    return _sequenceNumberService.allocate(
      factoryId: factoryId,
      sequence: DocumentSequence.expense,
    );
  }
}
