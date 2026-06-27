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
import '../../widgets/empty_state_view.dart';
import '../../widgets/labour/employee_list_tile.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.factoryWorkers),
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
          ? FloatingActionButton.extended(
              heroTag: 'fab-employees',
              onPressed: () => context.push(RoutePaths.employeesAdd),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text(AppStrings.addEmployee),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchEmployees,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<EmployeeListBloc>()
                              .add(const EmployeeListSearchChanged(''));
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context
                    .read<EmployeeListBloc>()
                    .add(EmployeeListSearchChanged(value));
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 8),
          const _EmployeeFilterBar(),
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
                  return EmptyStateView(
                    icon: Icons.groups_outlined,
                    title: state.employees.isEmpty
                        ? AppStrings.noEmployeesYet
                        : AppStrings.noEmployeesFound,
                    subtitle: state.employees.isEmpty
                        ? AppStrings.noEmployeesHint
                        : null,
                    action: state.employees.isEmpty
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
                    if (factoryId != null) {
                      context.read<EmployeeListBloc>().add(
                            EmployeeListWatchStarted(factoryId),
                          );
                    }
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
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

class _EmployeeFilterBar extends StatelessWidget {
  const _EmployeeFilterBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeeListBloc, EmployeeListState>(
      buildWhen: (prev, curr) => prev.filter != curr.filter,
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: EmployeeListFilter.values.map((filter) {
              final selected = state.filter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter.label),
                  selected: selected,
                  onSelected: (_) {
                    context.read<EmployeeListBloc>().add(
                          EmployeeListFilterChanged(filter),
                        );
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
