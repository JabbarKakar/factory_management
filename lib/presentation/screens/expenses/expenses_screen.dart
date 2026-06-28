import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/expense/expense_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/expense_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/expenses/expense_category_filter_bar.dart';
import '../../widgets/expenses/expense_list_tile.dart';
import '../../widgets/expenses/expense_period_filter_bar.dart';
import '../../widgets/expenses/expense_summary_card.dart';
import '../../widgets/job_work/job_work_search_bar.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchClear() {
    _searchController.clear();
    context.read<ExpenseListBloc>().add(const ExpenseListSearchChanged(''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ExpenseListBloc, ExpenseListState>(
          buildWhen: (prev, curr) =>
              prev.visibleExpenses.length != curr.visibleExpenses.length ||
              prev.periodFilter != curr.periodFilter ||
              prev.categoryFilter != curr.categoryFilter,
          builder: (context, state) {
            final appBarForeground =
                Theme.of(context).appBarTheme.foregroundColor ??
                    Theme.of(context).colorScheme.onSurface;
            final filterParts = <String>[
              if (state.periodFilter != ExpenseListPeriodFilter.thisMonth)
                state.periodFilter.label,
              if (state.categoryFilter != null) state.categoryFilter!.label,
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.expenses),
                Text(
                  '${state.visibleExpenses.length} expenses'
                  '${filterParts.isNotEmpty ? ' · ${filterParts.join(' · ')}' : ''}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: appBarForeground.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: context.userCanCreate(AppModule.expenses)
          ? FloatingActionButton.extended(
              heroTag: 'fab-expenses',
              onPressed: () => context.push(RoutePaths.expensesAdd),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addExpense),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<ExpenseListBloc, ExpenseListState>(
            buildWhen: (prev, curr) =>
                prev.monthTotal != curr.monthTotal ||
                prev.filteredTotal != curr.filteredTotal ||
                prev.periodFilter != curr.periodFilter,
            builder: (context, state) {
              return ExpenseSummaryCard(
                periodFilter: state.periodFilter,
                monthTotal: state.monthTotal,
                filteredTotal: state.filteredTotal,
              );
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: JobWorkSearchBar(
              controller: _searchController,
              hintText: AppStrings.searchExpenses,
              onChanged: (value) => context
                  .read<ExpenseListBloc>()
                  .add(ExpenseListSearchChanged(value)),
              onClear: _onSearchClear,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<ExpenseListBloc, ExpenseListState>(
              buildWhen: (prev, curr) =>
                  prev.periodFilter != curr.periodFilter ||
                  prev.categoryFilter != curr.categoryFilter,
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExpensePeriodFilterBar(
                      selected: state.periodFilter,
                      onChanged: (period) => context.read<ExpenseListBloc>().add(
                            ExpenseListPeriodFilterChanged(period),
                          ),
                    ),
                    const SizedBox(height: 8),
                    ExpenseCategoryFilterBar(
                      selected: state.categoryFilter,
                      onChanged: (category) => context
                          .read<ExpenseListBloc>()
                          .add(ExpenseListCategoryFilterChanged(category)),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<ExpenseListBloc, ExpenseListState>(
              builder: (context, state) {
                if (state.status == ExpenseListStatus.loading &&
                    state.expenses.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == ExpenseListStatus.failure) {
                  return EmptyStateView(
                    icon: Icons.error_outline,
                    title: AppStrings.expensesLoadError,
                    subtitle: state.errorMessage,
                    action: ElevatedButton(
                      onPressed: () {
                        final factoryId = readFactoryId(context);
                        if (factoryId != null) {
                          context.read<ExpenseListBloc>().add(
                                ExpenseListWatchStarted(factoryId),
                              );
                        }
                      },
                      child: const Text(AppStrings.retry),
                    ),
                  );
                }

                if (state.visibleExpenses.isEmpty) {
                  final filteredOut = state.searchQuery.isNotEmpty ||
                      state.categoryFilter != null ||
                      state.periodFilter != ExpenseListPeriodFilter.thisMonth ||
                      state.expenses.isNotEmpty;

                  return EmptyStateView(
                    icon: Icons.receipt_long_outlined,
                    title: filteredOut
                        ? AppStrings.noExpensesFound
                        : AppStrings.noExpensesYet,
                    subtitle: filteredOut
                        ? AppStrings.tryDifferentSearch
                        : AppStrings.addFirstExpense,
                    action: !filteredOut &&
                            context.userCanCreate(AppModule.expenses)
                        ? ElevatedButton.icon(
                            onPressed: () =>
                                context.push(RoutePaths.expensesAdd),
                            icon: const Icon(Icons.add),
                            label: const Text(AppStrings.addExpense),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final factoryId = readFactoryId(context);
                    if (factoryId == null) return;
                    context.read<ExpenseListBloc>().add(
                          ExpenseListWatchStarted(factoryId),
                        );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 88),
                    itemCount: state.visibleExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = state.visibleExpenses[index];
                      return ExpenseListTile(
                        expense: expense,
                        onTap: () => context.push(
                          RoutePaths.expenseEdit(expense.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
