import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_payment.dart';
import '../../domain/entities/stock_transaction.dart';
import '../../domain/entities/supplier_statement.dart';
import '../../domain/enums/raw_material_enums.dart';
import '../repositories/expense_repository.dart';
import '../repositories/raw_material_repository.dart';
import '../repositories/supplier_repository.dart';

class SupplierStatementService {
  SupplierStatementService({
    required SupplierRepository supplierRepository,
    required ExpenseRepository expenseRepository,
    required RawMaterialRepository rawMaterialRepository,
  })  : _supplierRepository = supplierRepository,
        _expenseRepository = expenseRepository,
        _rawMaterialRepository = rawMaterialRepository;

  final SupplierRepository _supplierRepository;
  final ExpenseRepository _expenseRepository;
  final RawMaterialRepository _rawMaterialRepository;

  Future<SupplierStatement?> buildStatement({
    required String supplierId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final supplier = await _supplierRepository.getSupplier(supplierId);
    if (supplier == null) return null;

    final from = _startOfDay(fromDate);
    final to = _endOfDay(toDate);
    if (to.isBefore(from)) return null;

    final factoryId = supplier.factoryId;
    final supplierNameLower = supplier.name.trim().toLowerCase();

    // 1. Fetch expenses for this supplier (by ID or matching Payee Name)
    final allExpenses =
        await _expenseRepository.getExpenses(factoryId);
    final supplierExpenses = allExpenses
        .where((e) =>
            e.supplierId == supplierId ||
            (e.payeeName != null &&
                e.payeeName!.trim().toLowerCase() == supplierNameLower))
        .toList();

    // 2. Fetch expense payments for this supplier / factory
    final allPayments =
        await _expenseRepository.getExpensePaymentsForFactory(factoryId);
    final supplierPayments = allPayments
        .where((p) =>
            p.supplierId == supplierId ||
            supplierExpenses.any((e) => e.id == p.expenseId) ||
            (p.payeeName != null &&
                p.payeeName!.trim().toLowerCase() == supplierNameLower))
        .toList();

    // 3. Fetch raw material stock-in transactions for this supplier
    final allTransactions =
        await _rawMaterialRepository.getTransactions(factoryId);
    final supplierStockIns = allTransactions
        .where((t) =>
            t.supplierId == supplierId &&
            t.movementType == StockMovementType.stockIn)
        .toList();

    // 4. Assemble all transactions
    final txns = <_SupplierTxn>[
      ...supplierStockIns.map(_txnFromStockIn),
      ..._txnsFromExpensesAndPayments(supplierExpenses, supplierPayments),
    ]..sort((a, b) => a.date.compareTo(b.date));

    // 5. Calculate Opening Balance before `fromDate`
    var openingBalance = supplier.openingBalance;
    for (final txn in txns) {
      if (txn.date.isBefore(from)) {
        openingBalance += txn.debit - txn.credit;
      }
    }

    // 6. Build Statement Lines within [fromDate, toDate]
    final lines = <SupplierStatementLine>[];
    for (final txn in txns) {
      if (txn.date.isBefore(from) || txn.date.isAfter(to)) continue;
      lines.add(
        SupplierStatementLine(
          date: txn.date,
          description: txn.description,
          reference: txn.reference,
          debit: txn.debit,
          credit: txn.credit,
          type: txn.type,
          category: txn.category,
          quantity: txn.quantity,
          unit: txn.unit,
          unitPrice: txn.unitPrice,
        ),
      );
    }

    // 7. Calculate Closing Balance
    final closingBalance = openingBalance +
        lines.fold<double>(0, (sum, line) => sum + line.debit - line.credit);

    return SupplierStatement(
      supplier: supplier,
      fromDate: from,
      toDate: to,
      openingBalance: openingBalance,
      lines: lines,
      closingBalance: closingBalance,
    );
  }

  List<_SupplierTxn> _txnsFromExpensesAndPayments(
    List<Expense> expenses,
    List<ExpensePayment> payments,
  ) {
    final result = <_SupplierTxn>[];

    for (final expense in expenses) {
      final refs = <String>[
        expense.expenseNumber,
        if (expense.billNumber != null && expense.billNumber!.trim().isNotEmpty)
          'Bill: ${expense.billNumber!.trim()}',
      ];

      final isPurePayment =
          expense.description.toLowerCase().contains('payment to') ||
              expense.description.toLowerCase().contains('balance payment') ||
              expense.description.toLowerCase().contains('ledger payment');

      if (isPurePayment) {
        // Pure ledger settlement expense
        result.add(
          _SupplierTxn(
            date: expense.expenseDate,
            description: expense.description,
            reference: refs.join(' · '),
            debit: 0,
            credit: expense.amount,
            type: SupplierTransactionType.payment,
            category: expense.category.label,
          ),
        );
      } else {
        // Purchase Liability (Debit = Full Purchase Bill)
        result.add(
          _SupplierTxn(
            date: expense.expenseDate,
            description: expense.description.isNotEmpty
                ? expense.description
                : '${expense.category.label} Purchase',
            reference: refs.join(' · '),
            debit: expense.amount,
            credit: 0,
            type: SupplierTransactionType.expense,
            category: expense.category.label,
          ),
        );

        // Check if there are separate ExpensePayment documents recorded for this expense
        final expensePayments =
            payments.where((p) => p.expenseId == expense.id).toList();

        if (expensePayments.isNotEmpty) {
          for (final payment in expensePayments) {
            result.add(
              _SupplierTxn(
                date: payment.paymentDate,
                description: 'Payment for ${expense.expenseNumber} (${payment.method.label})',
                reference: payment.reference != null && payment.reference!.isNotEmpty
                    ? '${expense.expenseNumber} · ${payment.reference}'
                    : expense.expenseNumber,
                debit: 0,
                credit: payment.amount,
                type: SupplierTransactionType.payment,
                category: 'Payment',
              ),
            );
          }

          // If paidAmount on expense is higher than documented separate payments
          final docTotal =
              expensePayments.fold<double>(0, (sum, p) => sum + p.amount);
          if (expense.paidAmount > docTotal + 0.005) {
            final diff = expense.paidAmount - docTotal;
            result.add(
              _SupplierTxn(
                date: expense.expenseDate,
                description: 'Payment for ${expense.expenseNumber} (${expense.paymentMethod.label})',
                reference: refs.join(' · '),
                debit: 0,
                credit: diff,
                type: SupplierTransactionType.payment,
                category: 'Payment',
              ),
            );
          }
        } else if (expense.paidAmount > 0.005) {
          // Legacy or instant payment recorded on expense doc
          result.add(
            _SupplierTxn(
              date: expense.expenseDate,
              description: 'Payment for ${expense.expenseNumber} (${expense.paymentMethod.label})',
              reference: refs.join(' · '),
              debit: 0,
              credit: expense.paidAmount,
              type: SupplierTransactionType.payment,
              category: 'Payment',
            ),
          );
        }
      }
    }

    // Add any standalone payments not attached to the loaded expense IDs
    for (final payment in payments) {
      if (!expenses.any((e) => e.id == payment.expenseId)) {
        result.add(
          _SupplierTxn(
            date: payment.paymentDate,
            description: payment.notes != null && payment.notes!.isNotEmpty
                ? payment.notes!
                : 'Payment (${payment.method.label})',
            reference: payment.reference ?? payment.expenseNumber,
            debit: 0,
            credit: payment.amount,
            type: SupplierTransactionType.payment,
            category: 'Payment',
          ),
        );
      }
    }

    return result;
  }

  _SupplierTxn _txnFromStockIn(StockTransaction transaction) {
    final qty = transaction.quantity;
    final unitCost = transaction.unitCost ?? 0.0;
    final totalCost = transaction.totalCost ?? (qty * unitCost);
    final ref = transaction.referenceNumber != null &&
            transaction.referenceNumber!.trim().isNotEmpty
        ? '${transaction.transactionNumber} (${transaction.referenceNumber!.trim()})'
        : transaction.transactionNumber;

    return _SupplierTxn(
      date: transaction.transactionDate,
      description: '${transaction.materialType.label} Stock Receipt',
      reference: ref,
      debit: totalCost,
      credit: 0,
      type: SupplierTransactionType.stockIn,
      category: 'Raw Material',
      quantity: qty,
      unit: transaction.unit.label,
      unitPrice: unitCost,
    );
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
}

class _SupplierTxn {
  const _SupplierTxn({
    required this.date,
    required this.description,
    required this.reference,
    required this.debit,
    required this.credit,
    required this.type,
    this.category,
    this.quantity,
    this.unit,
    this.unitPrice,
  });

  final DateTime date;
  final String description;
  final String reference;
  final double debit;
  final double credit;
  final SupplierTransactionType type;
  final String? category;
  final double? quantity;
  final String? unit;
  final double? unitPrice;
}
