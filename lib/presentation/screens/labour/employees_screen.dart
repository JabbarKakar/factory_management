import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/labour/employee_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/labour_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/app_extended_fab.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_search_bar.dart';
import '../../widgets/labour/employee_filter_bar.dart';
import '../../widgets/labour/employee_list_tile.dart';
import '../../widgets/labour/employee_summary_card.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchClear() {
    _searchController.clear();
    context.read<EmployeeListBloc>().add(const EmployeeListSearchChanged(''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<EmployeeListBloc, EmployeeListState>(
          buildWhen: (prev, curr) =>
              prev.visibleEmployees.length != curr.visibleEmployees.length ||
              prev.filter != curr.filter,
          builder: (context, state) {
            final appBarForeground =
                Theme.of(context).appBarTheme.foregroundColor ??
                    Theme.of(context).colorScheme.onSurface;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.factoryWorkers),
                Text(
                  '${state.visibleEmployees.length} workers'
                  '${state.filter != EmployeeListFilter.active ? ' · ${state.filter.label}' : ''}',
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
        actions: [
          if (context.userCanView(AppModule.labour))
            IconButton(
              onPressed: () => context.push(RoutePaths.attendance),
              icon: const Icon(Icons.fact_check_outlined),
              tooltip: AppStrings.dailyAttendance,
            ),
        ],
      ),
      floatingActionButton: context.userCanCreate(AppModule.labour)
          ? AppExtendedFab(
              heroTag: 'fab-employees',
              onPressed: () => context.push(RoutePaths.employeesAdd),
              icon: Icons.person_add_alt_1_outlined,
              label: AppStrings.addEmployee,
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<EmployeeListBloc, EmployeeListState>(
            buildWhen: (prev, curr) =>
                prev.employees != curr.employees ||
                prev.status != curr.status,
            builder: (context, state) {
              if (state.status != EmployeeListStatus.loaded ||
                  state.employees.isEmpty) {
                return const SizedBox.shrink();
              }

              return EmployeeSummaryCard(
                totalCount: state.employees.length,
                activeCount: state.activeCount,
              );
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: JobWorkSearchBar(
              controller: _searchController,
              hintText: AppStrings.searchEmployees,
              onChanged: (value) => context
                  .read<EmployeeListBloc>()
                  .add(EmployeeListSearchChanged(value)),
              onClear: _onSearchClear,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<EmployeeListBloc, EmployeeListState>(
              buildWhen: (prev, curr) => prev.filter != curr.filter,
              builder: (context, state) {
                return EmployeeFilterBar(
                  selected: state.filter,
                  onChanged: (filter) => context
                      .read<EmployeeListBloc>()
                      .add(EmployeeListFilterChanged(filter)),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<EmployeeListBloc, EmployeeListState>(
              builder: (context, state) {
                if (state.status == EmployeeListStatus.loading &&
                    state.employees.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == EmployeeListStatus.failure) {
                  return EmptyStateView(
                    icon: Icons.error_outline,
                    title: AppStrings.employeesLoadError,
                    subtitle: state.errorMessage,
                    action: ElevatedButton(
                      onPressed: () {
                        final factoryId = readFactoryId(context);
                        if (factoryId != null) {
                          context.read<EmployeeListBloc>().add(
                                EmployeeListWatchStarted(factoryId),
                              );
                        }
                      },
                      child: const Text(AppStrings.retry),
                    ),
                  );
                }

                if (state.visibleEmployees.isEmpty) {
                  final filteredOut = state.employees.isNotEmpty ||
                      state.searchQuery.isNotEmpty ||
                      state.filter != EmployeeListFilter.active;

                  return EmptyStateView(
                    icon: Icons.groups_outlined,
                    title: filteredOut
                        ? AppStrings.noEmployeesFound
                        : AppStrings.noEmployeesYet,
                    subtitle: filteredOut
                        ? AppStrings.tryDifferentSearch
                        : AppStrings.noEmployeesHint,
                    action: !filteredOut &&
                            context.userCanCreate(AppModule.labour)
                        ? FilledButton.icon(
                            onPressed: () =>
                                context.push(RoutePaths.employeesAdd),
                            icon: const Icon(Icons.person_add_alt_1_outlined),
                            label: const Text(AppStrings.addEmployee),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final factoryId = readFactoryId(context);
                    if (factoryId == null) return;
                    context.read<EmployeeListBloc>().add(
                          EmployeeListWatchStarted(factoryId),
                        );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 88),
                    itemCount: state.visibleEmployees.length,
                    itemBuilder: (context, index) {
                      final employee = state.visibleEmployees[index];
                      return EmployeeListTile(
                        employee: employee,
                        onTap: () => context.push(
                          RoutePaths.employeeDetail(employee.id),
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
