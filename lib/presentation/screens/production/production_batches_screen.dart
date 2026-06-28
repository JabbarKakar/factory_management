import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/production/production_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/production_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_search_bar.dart';
import '../../widgets/production/production_batch_filter_bar.dart';
import '../../widgets/production/production_batch_list_tile.dart';
import '../../widgets/production/production_summary_card.dart';

class ProductionBatchesScreen extends StatefulWidget {
  const ProductionBatchesScreen({this.initialFilter, super.key});

  final ProductionListFilter? initialFilter;

  @override
  State<ProductionBatchesScreen> createState() =>
      _ProductionBatchesScreenState();
}

class _ProductionBatchesScreenState extends State<ProductionBatchesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filter = widget.initialFilter;
    if (filter != null && filter != ProductionListFilter.all) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ProductionListBloc>().add(
              ProductionListFilterChanged(filter),
            );
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
    context.read<ProductionListBloc>().add(
          const ProductionListSearchChanged(''),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ProductionListBloc, ProductionListState>(
          buildWhen: (prev, curr) =>
              prev.visibleBatches.length != curr.visibleBatches.length ||
              prev.filter != curr.filter,
          builder: (context, state) {
            final appBarForeground =
                Theme.of(context).appBarTheme.foregroundColor ??
                    Theme.of(context).colorScheme.onSurface;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.productionBatches),
                Text(
                  '${state.visibleBatches.length} batches'
                  '${state.filter != ProductionListFilter.all ? ' · ${state.filter.label}' : ''}',
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
      floatingActionButton: context.userCanCreate(AppModule.production)
          ? FloatingActionButton.extended(
              heroTag: 'fab-production-batch',
              onPressed: () => context.push(RoutePaths.productionAdd),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.recordProduction),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<ProductionListBloc, ProductionListState>(
            buildWhen: (prev, curr) =>
                prev.batches != curr.batches ||
                prev.monthTotalSqFt != curr.monthTotalSqFt ||
                prev.filter != curr.filter ||
                prev.status != curr.status,
            builder: (context, state) {
              if (state.status != ProductionListStatus.loaded ||
                  state.batches.isEmpty) {
                return const SizedBox.shrink();
              }

              return ProductionSummaryCard(
                batches: state.batches,
                filter: state.filter,
                monthTotalSqFt: state.monthTotalSqFt,
              );
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: JobWorkSearchBar(
              controller: _searchController,
              hintText: AppStrings.searchProductionBatches,
              onChanged: (value) => context
                  .read<ProductionListBloc>()
                  .add(ProductionListSearchChanged(value)),
              onClear: _onSearchClear,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<ProductionListBloc, ProductionListState>(
              buildWhen: (prev, curr) => prev.filter != curr.filter,
              builder: (context, state) {
                return ProductionBatchFilterBar(
                  selected: state.filter,
                  onChanged: (filter) => context
                      .read<ProductionListBloc>()
                      .add(ProductionListFilterChanged(filter)),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<ProductionListBloc, ProductionListState>(
              builder: (context, state) {
                if (state.status == ProductionListStatus.loading &&
                    state.batches.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == ProductionListStatus.failure) {
                  return EmptyStateView(
                    icon: Icons.error_outline,
                    title: AppStrings.productionLoadError,
                    subtitle: state.errorMessage,
                    action: ElevatedButton(
                      onPressed: () {
                        final factoryId = readFactoryId(context);
                        if (factoryId != null) {
                          context.read<ProductionListBloc>().add(
                                ProductionListWatchStarted(factoryId),
                              );
                        }
                      },
                      child: const Text(AppStrings.retry),
                    ),
                  );
                }

                if (state.visibleBatches.isEmpty) {
                  final filteredOut = state.batches.isNotEmpty;

                  return EmptyStateView(
                    icon: Icons.precision_manufacturing_outlined,
                    title: filteredOut
                        ? AppStrings.noProductionBatchesFound
                        : AppStrings.noProductionBatchesYet,
                    subtitle: filteredOut
                        ? AppStrings.tryDifferentSearch
                        : AppStrings.noProductionBatchesHint,
                    action: !filteredOut &&
                            context.userCanCreate(AppModule.production)
                        ? FilledButton.icon(
                            onPressed: () =>
                                context.push(RoutePaths.productionAdd),
                            icon: const Icon(Icons.add),
                            label: const Text(AppStrings.recordProduction),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final factoryId = readFactoryId(context);
                    if (factoryId == null) return;
                    context.read<ProductionListBloc>().add(
                          ProductionListWatchStarted(factoryId),
                        );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 88),
                    itemCount: state.visibleBatches.length,
                    itemBuilder: (context, index) {
                      final batch = state.visibleBatches[index];
                      return ProductionBatchListTile(
                        batch: batch,
                        onTap: () => context.push(
                          RoutePaths.productionDetail(batch.id),
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
