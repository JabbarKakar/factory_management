import 'package:factory_management/data/repositories/expense_repository.dart';
import 'package:factory_management/data/repositories/raw_material_repository.dart';
import 'package:factory_management/data/repositories/supplier_repository.dart';
import 'package:factory_management/data/services/supplier_statement_service.dart';
import 'package:factory_management/domain/entities/expense.dart';
import 'package:factory_management/domain/entities/expense_payment.dart';
import 'package:factory_management/domain/entities/raw_material.dart';
import 'package:factory_management/domain/entities/stock_transaction.dart';
import 'package:factory_management/domain/entities/supplier.dart';
import 'package:factory_management/domain/enums/customer_enums.dart';
import 'package:factory_management/domain/enums/expense_enums.dart';
import 'package:factory_management/domain/enums/invoice_enums.dart';
import 'package:factory_management/domain/enums/raw_material_enums.dart';
import 'package:factory_management/domain/enums/supplier_enums.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSupplierRepository implements SupplierRepository {
  Supplier? supplier;

  @override
  Future<Supplier?> getSupplier(String id) async => supplier;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeExpenseRepository implements ExpenseRepository {
  List<Expense> expenses = [];
  List<ExpensePayment> payments = [];

  @override
  Stream<List<Expense>> watchExpenses(
    String factoryId, {
    DateTime? from,
    int? limit,
  }) =>
      Stream.value(expenses);

  @override
  Future<List<Expense>> getExpenses(
    String factoryId, {
    DateTime? from,
    int? limit,
  }) async =>
      expenses;

  @override
  Stream<List<ExpensePayment>> watchExpensePaymentsForFactory(String factoryId) =>
      Stream.value(payments);

  @override
  Future<List<ExpensePayment>> getExpensePaymentsForFactory(String factoryId) async =>
      payments;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRawMaterialRepository implements RawMaterialRepository {
  List<StockTransaction> transactions = [];

  @override
  Stream<List<StockTransaction>> watchTransactions(String factoryId) =>
      Stream.value(transactions);

  @override
  Future<List<StockTransaction>> getTransactions(String factoryId) async =>
      transactions;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSupplierRepository fakeSupplierRepo;
  late _FakeExpenseRepository fakeExpenseRepo;
  late _FakeRawMaterialRepository fakeRawMaterialRepo;
  late SupplierStatementService service;

  final testSupplier = Supplier(
    id: 'sup-1',
    supplierNumber: 'SUP-2026-0001',
    factoryId: 'factory-1',
    name: 'Al-Madina Marble Traders',
    supplierType: SupplierType.marbleBlockSlab,
    phone: '03001234567',
    paymentTerms: PaymentTerms.days30,
    openingBalance: 50000,
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    fakeSupplierRepo = _FakeSupplierRepository();
    fakeExpenseRepo = _FakeExpenseRepository();
    fakeRawMaterialRepo = _FakeRawMaterialRepository();

    service = SupplierStatementService(
      supplierRepository: fakeSupplierRepo,
      expenseRepository: fakeExpenseRepo,
      rawMaterialRepository: fakeRawMaterialRepo,
    );

    fakeSupplierRepo.supplier = testSupplier;
  });

  test('builds accurate supplier statement with itemized purchases and payments', () async {
    // 1. Expense prior to fromDate (Jan 10)
    final earlyExpense = Expense(
      id: 'exp-1',
      expenseNumber: 'EXP-2026-0001',
      factoryId: 'factory-1',
      supplierId: 'sup-1',
      expenseDate: DateTime(2026, 1, 10),
      category: ExpenseCategory.rawMaterialPurchase,
      description: 'Diamond Gangsaw Blades',
      amount: 20000,
      paymentMethod: PaymentMethod.bankTransfer,
      paidAmount: 20000,
      dueAmount: 0,
      paymentStatus: ExpensePaymentStatus.paid,
      createdAt: DateTime(2026, 1, 10),
    );

    // 2. Stock In within period (Feb 5) -> Debit = 150,000, Credit = 0
    final stockInTxn = StockTransaction(
      id: 'stk-1',
      transactionNumber: 'STK-IN-2026-0001',
      factoryId: 'factory-1',
      supplierId: 'sup-1',
      rawMaterialId: 'mat-1',
      materialType: RawMaterialType.diamondSegments,
      movementType: StockMovementType.stockIn,
      quantity: 10,
      unitCost: 15000,
      totalCost: 150000,
      transactionDate: DateTime(2026, 2, 5),
      createdAt: DateTime(2026, 2, 5),
    );

    // 3. Unpaid Purchase within period (Feb 12) -> Debit = 30,000, Credit = 0 initially
    final purchaseExpense = Expense(
      id: 'exp-2',
      expenseNumber: 'EXP-2026-0002',
      factoryId: 'factory-1',
      supplierId: 'sup-1',
      expenseDate: DateTime(2026, 2, 12),
      category: ExpenseCategory.rawMaterialPurchase,
      description: 'Tenax Epoxy Resin 50kg',
      amount: 30000,
      paymentMethod: PaymentMethod.cash,
      paidAmount: 10000,
      dueAmount: 20000,
      paymentStatus: ExpensePaymentStatus.partiallyPaid,
      createdAt: DateTime(2026, 2, 12),
    );

    // 4. Partial settlement payment for exp-2 on Feb 15 -> Credit = 10,000
    final expensePayment = ExpensePayment(
      id: 'pay-1',
      factoryId: 'factory-1',
      expenseId: 'exp-2',
      expenseNumber: 'EXP-2026-0002',
      supplierId: 'sup-1',
      amount: 10000,
      method: PaymentMethod.cash,
      paymentDate: DateTime(2026, 2, 15),
      createdAt: DateTime(2026, 2, 15),
    );

    // 5. Ledger balance payment within period (Feb 20) -> Debit = 0, Credit = 50,000
    final paymentExpense = Expense(
      id: 'exp-3',
      expenseNumber: 'EXP-2026-0003',
      factoryId: 'factory-1',
      supplierId: 'sup-1',
      expenseDate: DateTime(2026, 2, 20),
      category: ExpenseCategory.miscellaneous,
      description: 'Balance Payment to Supplier',
      amount: 50000,
      paymentMethod: PaymentMethod.bankTransfer,
      paidAmount: 50000,
      dueAmount: 0,
      paymentStatus: ExpensePaymentStatus.paid,
      createdAt: DateTime(2026, 2, 20),
    );

    fakeExpenseRepo.expenses = [earlyExpense, purchaseExpense, paymentExpense];
    fakeExpenseRepo.payments = [expensePayment];
    fakeRawMaterialRepo.transactions = [stockInTxn];

    final statement = await service.buildStatement(
      supplierId: 'sup-1',
      fromDate: DateTime(2026, 2, 1),
      toDate: DateTime(2026, 2, 28),
    );

    expect(statement, isNotNull);
    expect(statement!.supplier.name, 'Al-Madina Marble Traders');
    expect(statement.openingBalance, 50000);

    // Lines in Feb: stockInTxn, purchaseExpense, expensePayment, paymentExpense
    expect(statement.lines.length, 4);

    // Check Stock In Line
    final line1 = statement.lines[0];
    expect(line1.description, 'Diamond Segments Stock Receipt');
    expect(line1.quantity, 10);
    expect(line1.unitPrice, 15000);
    expect(line1.debit, 150000);
    expect(line1.credit, 0);

    // Check Purchase Expense Line (debit = full 30,000 bill)
    final line2 = statement.lines[1];
    expect(line2.description, 'Tenax Epoxy Resin 50kg');
    expect(line2.debit, 30000);
    expect(line2.credit, 0);

    // Check Partial Payment Line (credit = 10,000)
    final line3 = statement.lines[2];
    expect(line3.debit, 0);
    expect(line3.credit, 10000);

    // Check Balance Payment Line (credit = 50,000)
    final line4 = statement.lines[3];
    expect(line4.debit, 0);
    expect(line4.credit, 50000);

    // Total Purchases = 150,000 + 30,000 = 180,000
    expect(statement.totalPurchases, 180000);
    // Total Paid = 10,000 + 50,000 = 60,000
    expect(statement.totalPaid, 60000);
    // Closing Balance = Opening (50,000) + Debits (180,000) - Credits (60,000) = 170,000
    expect(statement.closingBalance, 170000);
    expect(statement.balanceStatus, CustomerBalanceStatus.outstanding);
  });
}
