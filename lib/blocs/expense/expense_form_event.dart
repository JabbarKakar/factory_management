part of 'expense_form_bloc.dart';

sealed class ExpenseFormEvent extends Equatable {
  const ExpenseFormEvent();

  @override
  List<Object?> get props => [];
}

final class ExpenseFormInitialized extends ExpenseFormEvent {
  const ExpenseFormInitialized({required this.factoryId});

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

final class ExpenseFormLoadRequested extends ExpenseFormEvent {
  const ExpenseFormLoadRequested(this.expenseId);

  final String expenseId;

  @override
  List<Object?> get props => [expenseId];
}

final class ExpenseFormSubmitted extends ExpenseFormEvent {
  const ExpenseFormSubmitted(
    this.expense, {
    this.isPaidNow = false,
    this.initialPaidAmount,
    this.paymentMethod,
    this.paymentDate,
    this.paymentReference,
    this.paymentNotes,
  });

  final Expense expense;
  final bool isPaidNow;
  final double? initialPaidAmount;
  final PaymentMethod? paymentMethod;
  final DateTime? paymentDate;
  final String? paymentReference;
  final String? paymentNotes;

  @override
  List<Object?> get props => [
        expense,
        isPaidNow,
        initialPaidAmount,
        paymentMethod,
        paymentDate,
        paymentReference,
        paymentNotes,
      ];
}

final class ExpensePaymentSubmitted extends ExpenseFormEvent {
  const ExpensePaymentSubmitted({
    required this.expenseId,
    required this.amount,
    required this.method,
    required this.paymentDate,
    this.reference,
    this.notes,
  });

  final String expenseId;
  final double amount;
  final PaymentMethod method;
  final DateTime paymentDate;
  final String? reference;
  final String? notes;

  @override
  List<Object?> get props => [
        expenseId,
        amount,
        method,
        paymentDate,
        reference,
        notes,
      ];
}

final class ExpenseFormDeleteRequested extends ExpenseFormEvent {
  const ExpenseFormDeleteRequested(this.expenseId);

  final String expenseId;

  @override
  List<Object?> get props => [expenseId];
}
