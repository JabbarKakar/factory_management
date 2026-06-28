import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/finished_goods/finished_goods_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/inventory_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/finished_goods/finished_good_list_tile.dart';
import '../../widgets/finished_goods/finished_goods_filter_bar.dart';
import '../../widgets/finished_goods/finished_goods_low_stock_banner.dart';
import '../../widgets/finished_goods/finished_goods_stock_summary_card.dart';
import '../../widgets/job_work/job_work_search_bar.dart';

class FinishedGoodsScreen extends StatefulWidget {
  const FinishedGoodsScreen({this.initialFilter, super.key});

  final FinishedGoodsListFilter? initialFilter;

  @override
  State<FinishedGoodsScreen> createState() => _FinishedGoodsScreenState();
}

class _FinishedGoodsScreenState extends State<FinishedGoodsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filter = widget.initialFilter;
    if (filter != null && filter != FinishedGoodsListFilter.all) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<FinishedGoodsListBloc>().add(
              FinishedGoodsListFilterChanged(filter),
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
    context.read<FinishedGoodsListBloc>().add(
          const FinishedGoodsListSearchChanged(''),
        );
  }

  void _viewLowStock() {
    context.read<FinishedGoodsListBloc>().add(
          const FinishedGoodsListFilterChanged(
            FinishedGoodsListFilter.lowStock,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<FinishedGoodsListBloc, FinishedGoodsListState>(
          buildWhen: (prev, curr) =>
              prev.visibleItems.length != curr.visibleItems.length ||
              prev.filter != curr.filter,
          builder: (context, state) {
            final appBarForeground =
                Theme.of(context).appBarTheme.foregroundColor ??
                    Theme.of(context).colorScheme.onSurface;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.finishedGoodsInventory),
                Text(
                  '${state.visibleItems.length} items'
                  '${state.filter != FinishedGoodsListFilter.all ? ' · ${state.filter.label}' : ''}',
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<FinishedGoodsListBloc, FinishedGoodsListState>(
            buildWhen: (prev, curr) =>
                prev.items != curr.items ||
                prev.totalStockValue != curr.totalStockValue ||
                prev.lowStockCount != curr.lowStockCount ||
                prev.status != curr.status,
            builder: (context, state) {
              if (state.status != FinishedGoodsListStatus.loaded ||
                  state.items.isEmpty) {
                return const SizedBox.shrink();
              }

              return FinishedGoodsStockSummaryCard(
                items: state.items,
                totalStockValue: state.totalStockValue,
                lowStockCount: state.lowStockCount,
              );
            },
          ),
          BlocBuilder<FinishedGoodsListBloc, FinishedGoodsListState>(
            buildWhen: (prev, curr) =>
                prev.lowStockCount != curr.lowStockCount ||
                prev.filter != curr.filter,
            builder: (context, state) {
              if (state.lowStockCount <= 0 ||
                  state.filter == FinishedGoodsListFilter.lowStock) {
                return const SizedBox.shrink();
              }

              return FinishedGoodsLowStockBanner(
                lowStockCount: state.lowStockCount,
                onViewLowStock: _viewLowStock,
              );
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: JobWorkSearchBar(
              controller: _searchController,
              hintText: AppStrings.searchFinishedGoods,
              onChanged: (value) => context
                  .read<FinishedGoodsListBloc>()
                  .add(FinishedGoodsListSearchChanged(value)),
              onClear: _onSearchClear,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<FinishedGoodsListBloc, FinishedGoodsListState>(
              buildWhen: (prev, curr) => prev.filter != curr.filter,
              builder: (context, state) {
                return FinishedGoodsFilterBar(
                  selected: state.filter,
                  onChanged: (filter) => context
                      .read<FinishedGoodsListBloc>()
                      .add(FinishedGoodsListFilterChanged(filter)),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<FinishedGoodsListBloc, FinishedGoodsListState>(
              builder: (context, state) {
                if (state.status == FinishedGoodsListStatus.loading &&
                    state.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == FinishedGoodsListStatus.failure) {
                  return EmptyStateView(
                    icon: Icons.error_outline,
                    title: AppStrings.finishedGoodsLoadError,
                    subtitle: state.errorMessage,
                    action: ElevatedButton(
                      onPressed: () {
                        final factoryId = readFactoryId(context);
                        if (factoryId != null) {
                          context.read<FinishedGoodsListBloc>().add(
                                FinishedGoodsListWatchStarted(factoryId),
                              );
                        }
                      },
                      child: const Text(AppStrings.retry),
                    ),
                  );
                }

                if (state.visibleItems.isEmpty) {
                  final filteredOut = state.items.isNotEmpty;

                  return EmptyStateView(
                    icon: Icons.layers_outlined,
                    title: filteredOut
                        ? AppStrings.noFinishedGoodsFound
                        : AppStrings.noFinishedGoodsYet,
                    subtitle: filteredOut
                        ? AppStrings.tryDifferentSearch
                        : AppStrings.noFinishedGoodsHint,
                    action: !filteredOut
                        ? FilledButton.icon(
                            onPressed: () =>
                                context.push(RoutePaths.productionAdd),
                            icon: const Icon(
                              Icons.precision_manufacturing_outlined,
                            ),
                            label: const Text(AppStrings.recordProduction),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final factoryId = readFactoryId(context);
                    if (factoryId == null) return;
                    context.read<FinishedGoodsListBloc>().add(
                          FinishedGoodsListWatchStarted(factoryId),
                        );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 24),
                    itemCount: state.visibleItems.length,
                    itemBuilder: (context, index) {
                      final item = state.visibleItems[index];
                      return FinishedGoodListTile(
                        item: item,
                        onTap: () => context.push(
                          RoutePaths.finishedGoodDetail(item.id),
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
