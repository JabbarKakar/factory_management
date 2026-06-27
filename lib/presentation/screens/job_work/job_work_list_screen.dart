import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/job_work/job_work_list_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_list_tile.dart';
import '../../widgets/account_menu_button.dart';
import '../../widgets/notification_bell.dart';

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
      appBar: AppBar(
        title: const Text(AppStrings.jobWork),
        actions: const [
          NotificationBell(),
          AccountMenuButton(),
        ],
      ),
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
              buildWhen: (prev, curr) => prev.stageFilter != curr.stageFilter,
              builder: (context, state) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: JobWorkListStageFilter.values.map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter.label),
                          selected: state.stageFilter == filter,
                          onSelected: (_) {
                            context.read<JobWorkListBloc>().add(
                                  JobWorkListStageFilterChanged(filter),
                                );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          BlocBuilder<JobWorkListBloc, JobWorkListState>(
            buildWhen: (prev, curr) => prev.awaitingQcCount != curr.awaitingQcCount,
            builder: (context, state) {
              if (state.awaitingQcCount == 0) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Card(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  child: ListTile(
                    leading: const Icon(
                      Icons.fact_check_outlined,
                      color: AppColors.warning,
                    ),
                    title: Text(
                      '${state.awaitingQcCount} ${AppStrings.jobWorkAwaitingQc}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.read<JobWorkListBloc>().add(
                            const JobWorkListStageFilterChanged(
                              JobWorkListStageFilter.atQc,
                            ),
                          );
                    },
                  ),
                ),
              );
            },
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
                    title: state.searchQuery.isNotEmpty ||
                            state.stageFilter != JobWorkListStageFilter.all
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
                        awaitingQcInspection: state.isAwaitingQcInspection(order),
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
