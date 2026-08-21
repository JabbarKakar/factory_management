import 'package:factory_management/blocs/expense/expense_form_bloc.dart';
import 'package:factory_management/data/repositories/expense_repository.dart';
import 'package:factory_management/domain/entities/expense.dart';
import 'package:factory_management/domain/entities/expense_payment.dart';
import 'package:factory_management/domain/enums/expense_enums.dart';
import 'package:factory_management/domain/enums/invoice_enums.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeExpenseRepository implements ExpenseRepository {
  Expense? expense;
  List<ExpensePayment> recordedPayments = [];

  @override
  Future<Expense?> getExpense(String id) async => expense;

  @override
  Future<Expense> createExpense(
    Expense expense, {
    bool isPaidNow = false,
    double? initialPaidAmount,
    PaymentMethod? paymentMethod,
    DateTime? paymentDate,
    String? paymentReference,
    String? paymentNotes,
  }) async {
    final paid = isPaidNow ? (initialPaidAmount ?? expense.amount) : 0.0;
    final due = expense.amount - paid;
    final created = expense.copyWith(
      id: 'created-exp-1',
      expenseNumber: 'EXP-2026-0001',
      paidAmount: paid,
      dueAmount: due,
      paymentStatus: ExpensePaymentStatus.fromAmounts(
        totalAmount: expense.amount,
        paidAmount: paid,
      ),
    );
    this.expense = created;
    return created;
  }

  @override
  Future<ExpensePayment> recordExpensePayment({
    required String expenseId,
    required double amount,
    required PaymentMethod method,
    required DateTime paymentDate,
    String? reference,
    String? notes,
  }) async {
    if (expense == null) throw StateError('Expense not found');
    final newPaid = expense!.paidAmount + amount;
    final newDue = expense!.amount - newPaid;
    expense = expense!.copyWith(
      paidAmount: newPaid,
      dueAmount: newDue,
      paymentStatus: ExpensePaymentStatus.fromAmounts(
        totalAmount: expense!.amount,
        paidAmount: newPaid,
      ),
    );
    final payment = ExpensePayment(
      id: 'pay-1',
      factoryId: expense!.factoryId,
      expenseId: expenseId,
      expenseNumber: expense!.expenseNumber,
      amount: amount,
      method: method,
      paymentDate: paymentDate,
      reference: reference,
      notes: notes,
      createdAt: DateTime.now(),
    );
    recordedPayments.add(payment);
    return payment;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeExpenseRepository repository;
  late ExpenseFormBloc bloc;

  setUp(() {
    repository = _FakeExpenseRepository();
    bloc = ExpenseFormBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  test('creates unpaid purchase when isPaidNow is false', () async {
    final inputExpense = Expense(
      id: '',
      expenseNumber: '',
      factoryId: 'factory-1',
      expenseDate: DateTime(2026, 2, 1),
      category: ExpenseCategory.rawMaterialPurchase,
      description: 'Diamond blades',
      amount: 50000,
      paymentMethod: PaymentMethod.cash,
      createdAt: DateTime(2026, 2, 1),
    );

    bloc.add(ExpenseFormSubmitted(inputExpense, isPaidNow: false));

    await expectLater(
      bloc.stream,
      emitsInOrder([
        const ExpenseFormState(status: ExpenseFormStatus.saving),
        predicate<ExpenseFormState>((state) {
          return state.status == ExpenseFormStatus.saved &&
              state.expense?.paidAmount == 0.0 &&
              state.expense?.effectiveDueAmount == 50000.0 &&
              state.expense?.paymentStatus == ExpensePaymentStatus.unpaid;
        }),
      ]),
    );
  });

  test('creates paid purchase when isPaidNow is true', () async {
    final inputExpense = Expense(
      id: '',
      expenseNumber: '',
      factoryId: 'factory-1',
      expenseDate: DateTime(2026, 2, 1),
      category: ExpenseCategory.rawMaterialPurchase,
      description: 'Diamond blades',
      amount: 50000,
      paymentMethod: PaymentMethod.bankTransfer,
      createdAt: DateTime(2026, 2, 1),
    );

    bloc.add(
      ExpenseFormSubmitted(
        inputExpense,
        isPaidNow: true,
        initialPaidAmount: 50000,
        paymentMethod: PaymentMethod.bankTransfer,
      ),
    );

    await expectLater(
      bloc.stream,
      emitsInOrder([
        const ExpenseFormState(status: ExpenseFormStatus.saving),
        predicate<ExpenseFormState>((state) {
          return state.status == ExpenseFormStatus.saved &&
              state.expense?.paidAmount == 50000.0 &&
              state.expense?.effectiveDueAmount == 0.0 &&
              state.expense?.paymentStatus == ExpensePaymentStatus.paid;
        }),
      ]),
    );
  });

  test('records subsequent settlement payment on existing unpaid purchase', () async {
    final existingUnpaid = Expense(
      id: 'exp-1',
      expenseNumber: 'EXP-2026-0001',
      factoryId: 'factory-1',
      expenseDate: DateTime(2026, 2, 1),
      category: ExpenseCategory.rawMaterialPurchase,
      description: 'Diamond blades',
      amount: 50000,
      paymentMethod: PaymentMethod.cash,
      paidAmount: 0.0,
      dueAmount: 50000,
      paymentStatus: ExpensePaymentStatus.unpaid,
      createdAt: DateTime(2026, 2, 1),
    );
    repository.expense = existingUnpaid;

    bloc.add(
      ExpensePaymentSubmitted(
        expenseId: 'exp-1',
        amount: 20000,
        method: PaymentMethod.cash,
        paymentDate: DateTime(2026, 2, 10),
      ),
    );

    await expectLater(
      bloc.stream,
      emitsInOrder([
        const ExpenseFormState(status: ExpenseFormStatus.saving),
        predicate<ExpenseFormState>((state) {
          return state.status == ExpenseFormStatus.paymentSaved &&
              state.expense?.paidAmount == 20000.0 &&
              state.expense?.effectiveDueAmount == 30000.0 &&
              state.expense?.paymentStatus == ExpensePaymentStatus.partiallyPaid;
        }),
      ]),
    );
  });
}
