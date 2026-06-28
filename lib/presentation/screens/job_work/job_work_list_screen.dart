import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/job_work/job_work_list_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/account_menu_button.dart';
import '../../widgets/dashboard/dashboard_surface.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_list_tile.dart';
import '../../widgets/job_work/job_work_search_bar.dart';
import '../../widgets/job_work/job_work_stage_filter_bar.dart';
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

  void _onSearchClear() {
    _searchController.clear();
    context.read<JobWorkListBloc>().add(const JobWorkListSearchChanged(''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<JobWorkListBloc, JobWorkListState>(
          buildWhen: (prev, curr) =>
              prev.visibleOrders.length != curr.visibleOrders.length ||
              prev.stageFilter != curr.stageFilter,
          builder: (context, state) {
            final appBarForeground =
                Theme.of(context).appBarTheme.foregroundColor ??
                    Theme.of(context).colorScheme.onSurface;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.jobWork),
                Text(
                  '${state.visibleOrders.length} orders'
                  '${state.stageFilter != JobWorkListStageFilter.all ? ' · ${state.stageFilter.label}' : ''}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: appBarForeground.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            );
          },
        ),
        actions: const [
          NotificationBell(),
          AccountMenuButton(),
        ],
      ),
      floatingActionButton: context.userCanCreate(AppModule.jobWork)
          ? FloatingActionButton.extended(
              heroTag: 'fab-job-work',
              onPressed: () => context.push(RoutePaths.jobWorkAdd),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.newJobWorkOrder),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: JobWorkSearchBar(
              controller: _searchController,
              onChanged: (value) => context
                  .read<JobWorkListBloc>()
                  .add(JobWorkListSearchChanged(value)),
              onClear: _onSearchClear,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<JobWorkListBloc, JobWorkListState>(
              buildWhen: (prev, curr) => prev.stageFilter != curr.stageFilter,
              builder: (context, state) {
                return JobWorkStageFilterBar(
                  selected: state.stageFilter,
                  onChanged: (filter) => context.read<JobWorkListBloc>().add(
                        JobWorkListStageFilterChanged(filter),
                      ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          BlocBuilder<JobWorkListBloc, JobWorkListState>(
            buildWhen: (prev, curr) =>
                prev.awaitingQcCount != curr.awaitingQcCount,
            builder: (context, state) {
              if (state.awaitingQcCount == 0) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: DashboardSurfaceCard(
                  compact: true,
                  borderRadius: 12,
                  padding: EdgeInsets.zero,
                  onTap: () {
                    context.read<JobWorkListBloc>().add(
                          const JobWorkListStageFilterChanged(
                            JobWorkListStageFilter.atQc,
                          ),
                        );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.fact_check_outlined,
                            color: AppColors.warning,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${state.awaitingQcCount} ${AppStrings.jobWorkAwaitingQc}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.7),
                        ),
                      ],
                    ),
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
                    action: state.searchQuery.isEmpty &&
                            context.userCanCreate(AppModule.jobWork)
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
                        awaitingQcInspection:
                            state.isAwaitingQcInspection(order),
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
