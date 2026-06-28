import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/quality/qc_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/quality_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/app_extended_fab.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_search_bar.dart';
import '../../widgets/quality/qc_filter_bar.dart';
import '../../widgets/quality/qc_list_tile.dart';
import '../../widgets/quality/qc_summary_card.dart';

class QualityChecksScreen extends StatefulWidget {
  const QualityChecksScreen({this.initialFilter, super.key});

  final QcListFilter? initialFilter;

  @override
  State<QualityChecksScreen> createState() => _QualityChecksScreenState();
}

class _QualityChecksScreenState extends State<QualityChecksScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filter = widget.initialFilter;
    if (filter != null && filter != QcListFilter.all) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<QcListBloc>().add(QcListFilterChanged(filter));
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchClear() {
    _searchController.clear();
    context.read<QcListBloc>().add(const QcListSearchChanged(''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<QcListBloc, QcListState>(
          buildWhen: (prev, curr) =>
              prev.visibleChecks.length != curr.visibleChecks.length ||
              prev.filter != curr.filter,
          builder: (context, state) {
            final appBarForeground =
                Theme.of(context).appBarTheme.foregroundColor ??
                    Theme.of(context).colorScheme.onSurface;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.qualityControl),
                Text(
                  '${state.visibleChecks.length} inspections'
                  '${state.filter != QcListFilter.all ? ' · ${state.filter.label}' : ''}',
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
      floatingActionButton: context.userCanCreate(AppModule.qualityControl)
          ? AppExtendedFab(
              heroTag: 'fab-quality-checks',
              onPressed: () => context.push(RoutePaths.qualityChecksAdd),
              icon: Icons.fact_check_outlined,
              label: AppStrings.recordQcInspection,
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<QcListBloc, QcListState>(
            buildWhen: (prev, curr) =>
                prev.monthlyInspectionCount != curr.monthlyInspectionCount ||
                prev.monthlyPassRate != curr.monthlyPassRate ||
                prev.status != curr.status,
            builder: (context, state) {
              if (state.status != QcListStatus.loaded ||
                  state.monthlyInspectionCount == 0) {
                return const SizedBox.shrink();
              }

              return QcSummaryCard(
                monthlyInspectionCount: state.monthlyInspectionCount,
                monthlyPassRate: state.monthlyPassRate,
              );
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: JobWorkSearchBar(
              controller: _searchController,
              hintText: AppStrings.searchQualityChecks,
              onChanged: (value) =>
                  context.read<QcListBloc>().add(QcListSearchChanged(value)),
              onClear: _onSearchClear,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<QcListBloc, QcListState>(
              buildWhen: (prev, curr) => prev.filter != curr.filter,
              builder: (context, state) {
                return QcFilterBar(
                  selected: state.filter,
                  onChanged: (filter) =>
                      context.read<QcListBloc>().add(QcListFilterChanged(filter)),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<QcListBloc, QcListState>(
              builder: (context, state) {
                if (state.status == QcListStatus.loading &&
                    state.checks.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == QcListStatus.failure) {
                  return EmptyStateView(
                    icon: Icons.error_outline,
                    title: AppStrings.qcLoadError,
                    subtitle: state.errorMessage,
                    action: ElevatedButton(
                      onPressed: () {
                        final factoryId = readFactoryId(context);
                        if (factoryId != null) {
                          context
                              .read<QcListBloc>()
                              .add(QcListWatchStarted(factoryId));
                        }
                      },
                      child: const Text(AppStrings.retry),
                    ),
                  );
                }

                if (state.visibleChecks.isEmpty) {
                  final filteredOut = state.checks.isNotEmpty ||
                      state.searchQuery.isNotEmpty ||
                      state.filter != QcListFilter.all;

                  return EmptyStateView(
                    icon: Icons.fact_check_outlined,
                    title: filteredOut
                        ? AppStrings.noQualityChecksFound
                        : AppStrings.noQualityChecksYet,
                    subtitle: filteredOut
                        ? AppStrings.tryDifferentSearch
                        : AppStrings.noQualityChecksHint,
                    action: !filteredOut &&
                            context.userCanCreate(AppModule.qualityControl)
                        ? FilledButton.icon(
                            onPressed: () =>
                                context.push(RoutePaths.qualityChecksAdd),
                            icon: const Icon(Icons.fact_check_outlined),
                            label: const Text(AppStrings.recordQcInspection),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final factoryId = readFactoryId(context);
                    if (factoryId == null) return;
                    context
                        .read<QcListBloc>()
                        .add(QcListWatchStarted(factoryId));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 88),
                    itemCount: state.visibleChecks.length,
                    itemBuilder: (context, index) {
                      final check = state.visibleChecks[index];
                      return QcListTile(
                        check: check,
                        onTap: () => context.push(
                          RoutePaths.qualityCheckDetail(check.id),
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
