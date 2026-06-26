part of 'expense_list_bloc.dart';

enum ExpenseListStatus { initial, loading, loaded, failure }

class ExpenseListState extends Equatable {
  const ExpenseListState({
    this.status = ExpenseListStatus.initial,
    this.expenses = const [],
    this.visibleExpenses = const [],
    this.searchQuery = '',
    this.categoryFilter,
    this.periodFilter = ExpenseListPeriodFilter.thisMonth,
    this.monthTotal = 0,
    this.filteredTotal = 0,
    this.errorMessage,
  });

  final ExpenseListStatus status;
  final List<Expense> expenses;
  final List<Expense> visibleExpenses;
  final String searchQuery;
  final ExpenseCategory? categoryFilter;
  final ExpenseListPeriodFilter periodFilter;
  final double monthTotal;
  final double filteredTotal;
  final String? errorMessage;

  ExpenseListState copyWith({
    ExpenseListStatus? status,
    List<Expense>? expenses,
    List<Expense>? visibleExpenses,
    String? searchQuery,
    ExpenseCategory? categoryFilter,
    bool clearCategoryFilter = false,
    ExpenseListPeriodFilter? periodFilter,
    double? monthTotal,
    double? filteredTotal,
    String? errorMessage,
  }) {
    return ExpenseListState(
      status: status ?? this.status,
      expenses: expenses ?? this.expenses,
      visibleExpenses: visibleExpenses ?? this.visibleExpenses,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter:
          clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
      periodFilter: periodFilter ?? this.periodFilter,
      monthTotal: monthTotal ?? this.monthTotal,
      filteredTotal: filteredTotal ?? this.filteredTotal,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        expenses,
        visibleExpenses,
        searchQuery,
        categoryFilter,
        periodFilter,
        monthTotal,
        filteredTotal,
        errorMessage,
      ];
}
