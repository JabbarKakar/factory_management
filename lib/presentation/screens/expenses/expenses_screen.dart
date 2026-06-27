import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/expense/expense_list_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/expense_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/expenses/expense_list_tile.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.expenses),
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
        children: [
          BlocBuilder<ExpenseListBloc, ExpenseListState>(
            buildWhen: (prev, curr) =>
                prev.monthTotal != curr.monthTotal ||
                prev.filteredTotal != curr.filteredTotal ||
                prev.periodFilter != curr.periodFilter,
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Card(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.35),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.periodFilter ==
                                        ExpenseListPeriodFilter.thisMonth
                                    ? AppStrings.expensesThisMonth
                                    : AppStrings.filteredTotal,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.currencyPkr(
                                  state.periodFilter ==
                                          ExpenseListPeriodFilter.thisMonth
                                      ? state.monthTotal
                                      : state.filteredTotal,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppStrings.monthToDate,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            Text(
                              Formatters.currencyPkr(state.monthTotal),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchExpenses,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<ExpenseListBloc>()
                              .add(const ExpenseListSearchChanged(''));
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context.read<ExpenseListBloc>().add(ExpenseListSearchChanged(value));
                setState(() {});
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BlocBuilder<ExpenseListBloc, ExpenseListState>(
              buildWhen: (prev, curr) =>
                  prev.periodFilter != curr.periodFilter ||
                  prev.categoryFilter != curr.categoryFilter,
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: ExpenseListPeriodFilter.values.map((period) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(period.label),
                            selected: state.periodFilter == period,
                            onSelected: (_) {
                              context.read<ExpenseListBloc>().add(
                                    ExpenseListPeriodFilterChanged(period),
                                  );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: const Text(AppStrings.allCategories),
                              selected: state.categoryFilter == null,
                              onSelected: (_) {
                                context.read<ExpenseListBloc>().add(
                                      const ExpenseListCategoryFilterChanged(
                                        null,
                                      ),
                                    );
                              },
                            ),
                          ),
                          ...ExpenseCategory.values.map((category) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category.label),
                                selected: state.categoryFilter == category,
                                onSelected: (_) {
                                  context.read<ExpenseListBloc>().add(
                                        ExpenseListCategoryFilterChanged(
                                          category,
                                        ),
                                      );
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
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
                  return EmptyStateView(
                    icon: Icons.receipt_long_outlined,
                    title: state.searchQuery.isNotEmpty ||
                            state.categoryFilter != null
                        ? AppStrings.noExpensesFound
                        : AppStrings.noExpensesYet,
                    subtitle: state.searchQuery.isNotEmpty
                        ? AppStrings.tryDifferentSearch
                        : AppStrings.addFirstExpense,
                    action: state.searchQuery.isEmpty
                        ? ElevatedButton.icon(
                            onPressed: () => context.push(RoutePaths.expensesAdd),
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
