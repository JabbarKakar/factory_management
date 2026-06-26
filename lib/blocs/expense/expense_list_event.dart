part of 'expense_list_bloc.dart';

sealed class ExpenseListEvent extends Equatable {
  const ExpenseListEvent();

  @override
  List<Object?> get props => [];
}

final class ExpenseListWatchStarted extends ExpenseListEvent {
  const ExpenseListWatchStarted(this.factoryId);

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

final class ExpenseListSearchChanged extends ExpenseListEvent {
  const ExpenseListSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class ExpenseListCategoryFilterChanged extends ExpenseListEvent {
  const ExpenseListCategoryFilterChanged(this.category);

  final ExpenseCategory? category;

  @override
  List<Object?> get props => [category];
}

final class ExpenseListPeriodFilterChanged extends ExpenseListEvent {
  const ExpenseListPeriodFilterChanged(this.periodFilter);

  final ExpenseListPeriodFilter periodFilter;

  @override
  List<Object?> get props => [periodFilter];
}

final class _ExpenseListUpdated extends ExpenseListEvent {
  const _ExpenseListUpdated(this.expenses);

  final List<Expense> expenses;

  @override
  List<Object?> get props => [expenses];
}

final class _ExpenseListStreamFailed extends ExpenseListEvent {
  const _ExpenseListStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
