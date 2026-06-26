import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/expense_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/enums/expense_enums.dart';

part 'expense_list_event.dart';
part 'expense_list_state.dart';

class ExpenseListBloc extends Bloc<ExpenseListEvent, ExpenseListState> {
  ExpenseListBloc({required ExpenseRepository repository})
      : _repository = repository,
        super(const ExpenseListState()) {
    on<ExpenseListWatchStarted>(_onWatchStarted);
    on<ExpenseListSearchChanged>(_onSearchChanged);
    on<ExpenseListCategoryFilterChanged>(_onCategoryFilterChanged);
    on<ExpenseListPeriodFilterChanged>(_onPeriodFilterChanged);
    on<_ExpenseListUpdated>(_onListUpdated);
    on<_ExpenseListStreamFailed>(_onStreamFailed);
  }

  final ExpenseRepository _repository;
  StreamSubscription<List<Expense>>? _subscription;

  Future<void> _onWatchStarted(
    ExpenseListWatchStarted event,
    Emitter<ExpenseListState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseListStatus.loading));
    await _subscription?.cancel();
    _subscription = _repository.watchExpenses(event.factoryId).listen(
          (expenses) => add(_ExpenseListUpdated(expenses)),
          onError: (_) => add(
            const _ExpenseListStreamFailed(
              'Could not load expenses. Please try again.',
            ),
          ),
        );
  }

  void _onSearchChanged(
    ExpenseListSearchChanged event,
    Emitter<ExpenseListState> emit,
  ) {
    emit(_applyFilters(state, searchQuery: event.query));
  }

  void _onCategoryFilterChanged(
    ExpenseListCategoryFilterChanged event,
    Emitter<ExpenseListState> emit,
  ) {
    emit(
      _applyFilters(
        state,
        categoryFilter: event.category,
        clearCategoryFilter: event.category == null,
      ),
    );
  }

  void _onPeriodFilterChanged(
    ExpenseListPeriodFilterChanged event,
    Emitter<ExpenseListState> emit,
  ) {
    emit(_applyFilters(state, periodFilter: event.periodFilter));
  }

  void _onListUpdated(
    _ExpenseListUpdated event,
    Emitter<ExpenseListState> emit,
  ) {
    emit(
      _applyFilters(
        state.copyWith(
          status: ExpenseListStatus.loaded,
          expenses: event.expenses,
          errorMessage: null,
        ),
      ),
    );
  }

  void _onStreamFailed(
    _ExpenseListStreamFailed event,
    Emitter<ExpenseListState> emit,
  ) {
    emit(
      state.copyWith(
        status: ExpenseListStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  ExpenseListState _applyFilters(
    ExpenseListState current, {
    String? searchQuery,
    ExpenseCategory? categoryFilter,
    bool clearCategoryFilter = false,
    ExpenseListPeriodFilter? periodFilter,
  }) {
    final query = searchQuery ?? current.searchQuery;
    final category = clearCategoryFilter
        ? null
        : (categoryFilter ?? current.categoryFilter);
    final period = periodFilter ?? current.periodFilter;
    final normalizedQuery = query.trim().toLowerCase();
    final now = DateTime.now();

    final visible = current.expenses.where((expense) {
      if (category != null && expense.category != category) return false;
      if (period == ExpenseListPeriodFilter.thisMonth) {
        final date = expense.expenseDate;
        if (date.year != now.year || date.month != now.month) return false;
      }
      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        expense.expenseNumber,
        expense.description,
        expense.category.label,
        expense.payeeName,
        expense.billNumber,
        expense.paymentMethod.label,
      ].whereType<String>().join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList();

    final monthTotal = current.expenses
        .where((expense) {
          final date = expense.expenseDate;
          return date.year == now.year && date.month == now.month;
        })
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    final filteredTotal =
        visible.fold<double>(0, (sum, expense) => sum + expense.amount);

    return current.copyWith(
      searchQuery: query,
      categoryFilter: category,
      clearCategoryFilter: clearCategoryFilter,
      periodFilter: period,
      visibleExpenses: visible,
      monthTotal: monthTotal,
      filteredTotal: filteredTotal,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
