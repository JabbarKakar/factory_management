import 'package:equatable/equatable.dart';

import 'customer.dart';

class CustomerStatementLine extends Equatable {
  const CustomerStatementLine({
    required this.date,
    required this.description,
    required this.reference,
    required this.debit,
    required this.credit,
  });

  final DateTime date;
  final String description;
  final String reference;
  final double debit;
  final double credit;

  @override
  List<Object?> get props => [date, description, reference, debit, credit];
}

class CustomerStatement extends Equatable {
  const CustomerStatement({
    required this.customer,
    required this.fromDate,
    required this.toDate,
    required this.openingBalance,
    required this.lines,
    required this.closingBalance,
  });

  final Customer customer;
  final DateTime fromDate;
  final DateTime toDate;
  final double openingBalance;
  final List<CustomerStatementLine> lines;
  final double closingBalance;

  double get totalDebits =>
      lines.fold<double>(0, (sum, line) => sum + line.debit);

  double get totalCredits =>
      lines.fold<double>(0, (sum, line) => sum + line.credit);

  @override
  List<Object?> get props => [
        customer,
        fromDate,
        toDate,
        openingBalance,
        lines,
        closingBalance,
      ];
}
