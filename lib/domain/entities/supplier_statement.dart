import 'package:equatable/equatable.dart';

import '../enums/customer_enums.dart';
import 'supplier.dart';

class SupplierStatement extends Equatable {
  const SupplierStatement({
    required this.supplier,
    required this.fromDate,
    required this.toDate,
    required this.openingBalance,
    required this.lines,
    required this.closingBalance,
  });

  final Supplier supplier;
  final DateTime fromDate;
  final DateTime toDate;
  final double openingBalance;
  final List<SupplierStatementLine> lines;
  final double closingBalance;

  double get totalDebits =>
      lines.fold<double>(0, (sum, line) => sum + line.debit);

  double get totalCredits =>
      lines.fold<double>(0, (sum, line) => sum + line.credit);

  double get totalPurchases => totalDebits;

  double get totalPaid => totalCredits;

  double get remainingBalanceDue => closingBalance;

  CustomerBalanceStatus get balanceStatus {
    if (closingBalance < 0) return CustomerBalanceStatus.inCredit;
    if (closingBalance == 0) return CustomerBalanceStatus.paidUp;
    return CustomerBalanceStatus.outstanding;
  }

  @override
  List<Object?> get props => [
        supplier,
        fromDate,
        toDate,
        openingBalance,
        lines,
        closingBalance,
      ];
}

enum SupplierTransactionType {
  purchase,
  stockIn,
  payment,
  expense,
}

class SupplierStatementLine extends Equatable {
  const SupplierStatementLine({
    required this.date,
    required this.description,
    required this.reference,
    required this.debit,
    required this.credit,
    this.type = SupplierTransactionType.purchase,
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

  bool get isPurchase => debit > 0;
  bool get isPayment => credit > 0;

  @override
  List<Object?> get props => [
        date,
        description,
        reference,
        debit,
        credit,
        type,
        category,
        quantity,
        unit,
        unitPrice,
      ];
}
