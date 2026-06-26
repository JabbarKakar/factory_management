import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/expense.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  ExpenseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get collection =>
      _firestore.collection('expenses');

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

  Future<Expense> createExpense(Expense expense) async {
    final id = expense.id.isEmpty ? _uuid.v4() : expense.id;
    final expenseNumber = expense.expenseNumber.isEmpty
        ? await _generateExpenseNumber(expense.factoryId)
        : expense.expenseNumber;

    final model = ExpenseModel.fromEntity(
      expense.copyWith(id: id, expenseNumber: expenseNumber),
    );

    await collection.doc(id).set(model.toFirestore(isCreate: true));
    final created = await getExpense(id);
    return created ?? model.toEntity();
  }

  Future<void> updateExpense(Expense expense) async {
    final model = ExpenseModel.fromEntity(expense);
    await collection.doc(expense.id).update(model.toFirestore());
  }

  Future<void> deleteExpense(String id) async {
    await collection.doc(id).delete();
  }

  Future<String> _generateExpenseNumber(String factoryId) async {
    final year = DateTime.now().year;
    final snapshot =
        await collection.where('factoryId', isEqualTo: factoryId).get();
    final count = snapshot.docs.length + 1;
    return 'EXP-$year-${count.toString().padLeft(4, '0')}';
  }
}
