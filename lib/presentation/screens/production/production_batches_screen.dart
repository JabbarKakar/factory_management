import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/production/production_list_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/enums/production_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/production/production_batch_list_tile.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.productionBatches),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-production-batch',
        onPressed: () => context.push(RoutePaths.productionAdd),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.recordProduction),
      ),
      body: Column(
        children: [
          BlocBuilder<ProductionListBloc, ProductionListState>(
            buildWhen: (prev, curr) =>
                prev.monthTotalSqFt != curr.monthTotalSqFt ||
                prev.batches.length != curr.batches.length,
            builder: (context, state) {
              if (state.batches.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: const Text(AppStrings.productionThisMonth),
                    trailing: Text(
                      Formatters.stockQuantity(state.monthTotalSqFt, 'sq. ft'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
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
                hintText: AppStrings.searchProductionBatches,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ProductionListBloc>().add(
                                const ProductionListSearchChanged(''),
                              );
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context
                    .read<ProductionListBloc>()
                    .add(ProductionListSearchChanged(value));
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 8),
          const _ProductionFilterBar(),
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
                  return EmptyStateView(
                    icon: Icons.precision_manufacturing_outlined,
                    title: state.batches.isEmpty
                        ? AppStrings.noProductionBatchesYet
                        : AppStrings.noProductionBatchesFound,
                    subtitle: state.batches.isEmpty
                        ? AppStrings.noProductionBatchesHint
                        : null,
                    action: state.batches.isEmpty
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
                    if (factoryId != null) {
                      context.read<ProductionListBloc>().add(
                            ProductionListWatchStarted(factoryId),
                          );
                    }
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: state.visibleBatches.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
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

class _ProductionFilterBar extends StatelessWidget {
  const _ProductionFilterBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductionListBloc, ProductionListState>(
      buildWhen: (prev, curr) => prev.filter != curr.filter,
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ProductionListFilter.values.map((filter) {
              final selected = state.filter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter.label),
                  selected: selected,
                  onSelected: (_) {
                    context.read<ProductionListBloc>().add(
                          ProductionListFilterChanged(filter),
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
