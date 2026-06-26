import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/job_work/job_work_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_list_tile.dart';

class JobWorkListScreen extends StatefulWidget {
  const JobWorkListScreen({super.key});

  @override
  State<JobWorkListScreen> createState() => _JobWorkListScreenState();
}

class _JobWorkListScreenState extends State<JobWorkListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.jobWork)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-job-work',
        onPressed: () => context.push(RoutePaths.jobWorkAdd),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newJobWorkOrder),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchJobWork,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<JobWorkListBloc>()
                              .add(const JobWorkListSearchChanged(''));
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context
                    .read<JobWorkListBloc>()
                    .add(JobWorkListSearchChanged(value));
                setState(() {});
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BlocBuilder<JobWorkListBloc, JobWorkListState>(
              buildWhen: (prev, curr) =>
                  prev.showActiveOnly != curr.showActiveOnly,
              builder: (context, state) {
                return FilterChip(
                  label: const Text(AppStrings.activeOrdersOnly),
                  selected: state.showActiveOnly,
                  onSelected: (selected) {
                    context.read<JobWorkListBloc>().add(
                          JobWorkListStatusFilterChanged(selected),
                        );
                  },
                );
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<JobWorkListBloc, JobWorkListState>(
              builder: (context, state) {
                if (state.status == JobWorkListStatus.loading &&
                    state.orders.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == JobWorkListStatus.failure) {
                  return EmptyStateView(
                    icon: Icons.error_outline,
                    title: AppStrings.jobWorkLoadError,
                    subtitle: state.errorMessage,
                    action: ElevatedButton(
                      onPressed: () {
                        final factoryId = readFactoryId(context);
                        if (factoryId != null) {
                          context.read<JobWorkListBloc>().add(
                                JobWorkListWatchStarted(factoryId),
                              );
                        }
                      },
                      child: const Text(AppStrings.retry),
                    ),
                  );
                }

                if (state.visibleOrders.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.content_cut,
                    title: state.searchQuery.isNotEmpty || state.showActiveOnly
                        ? AppStrings.noJobWorkFound
                        : AppStrings.noJobWorkYet,
                    subtitle: state.searchQuery.isNotEmpty
                        ? AppStrings.tryDifferentSearch
                        : AppStrings.addFirstJobWork,
                    action: state.searchQuery.isEmpty
                        ? ElevatedButton.icon(
                            onPressed: () =>
                                context.push(RoutePaths.jobWorkAdd),
                            icon: const Icon(Icons.add),
                            label: const Text(AppStrings.newJobWorkOrder),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final factoryId = readFactoryId(context);
                    if (factoryId == null) return;
                    context.read<JobWorkListBloc>().add(
                          JobWorkListWatchStarted(factoryId),
                        );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 88),
                    itemCount: state.visibleOrders.length,
                    itemBuilder: (context, index) {
                      final order = state.visibleOrders[index];
                      return JobWorkListTile(
                        order: order,
                        onTap: () => context.push(
                          RoutePaths.jobWorkDetail(order.id),
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
