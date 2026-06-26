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
  const ExpenseFormSubmitted(this.expense);

  final Expense expense;

  @override
  List<Object?> get props => [expense];
}

final class ExpenseFormDeleteRequested extends ExpenseFormEvent {
  const ExpenseFormDeleteRequested(this.expenseId);

  final String expenseId;

  @override
  List<Object?> get props => [expenseId];
}
