import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/finished_goods/finished_goods_list_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/enums/inventory_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/finished_goods/finished_good_list_tile.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.finishedGoodsInventory),
      ),
      body: Column(
        children: [
          BlocBuilder<FinishedGoodsListBloc, FinishedGoodsListState>(
            buildWhen: (prev, curr) =>
                prev.totalStockValue != curr.totalStockValue ||
                prev.lowStockCount != curr.lowStockCount,
            builder: (context, state) {
              if (state.items.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.account_balance_wallet_outlined),
                        title: const Text(AppStrings.totalInventoryValue),
                        trailing: Text(
                          Formatters.currencyPkr(state.totalStockValue),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                        ),
                      ),
                    ),
                    if (state.lowStockCount > 0) ...[
                      const SizedBox(height: 8),
                      Card(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        child: ListTile(
                          leading: Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                          ),
                          title: const Text(AppStrings.lowStockFinishedGoods),
                          subtitle: Text('${state.lowStockCount} SKU(s)'),
                          trailing: TextButton(
                            onPressed: () =>
                                context.read<FinishedGoodsListBloc>().add(
                                      const FinishedGoodsListFilterChanged(
                                        FinishedGoodsListFilter.lowStock,
                                      ),
                                    ),
                            child: const Text(AppStrings.lowStock),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchFinishedGoods,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<FinishedGoodsListBloc>().add(
                                const FinishedGoodsListSearchChanged(''),
                              );
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context
                    .read<FinishedGoodsListBloc>()
                    .add(FinishedGoodsListSearchChanged(value));
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 8),
          const _FinishedGoodsFilterBar(),
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
                  return EmptyStateView(
                    icon: Icons.layers_outlined,
                    title: state.items.isEmpty
                        ? AppStrings.noFinishedGoodsYet
                        : AppStrings.noFinishedGoodsFound,
                    subtitle: state.items.isEmpty
                        ? AppStrings.noFinishedGoodsHint
                        : null,
                    action: state.items.isEmpty
                        ? FilledButton.icon(
                            onPressed: () =>
                                context.push(RoutePaths.productionAdd),
                            icon: const Icon(Icons.precision_manufacturing_outlined),
                            label: const Text(AppStrings.recordProduction),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final factoryId = readFactoryId(context);
                    if (factoryId != null) {
                      context.read<FinishedGoodsListBloc>().add(
                            FinishedGoodsListWatchStarted(factoryId),
                          );
                    }
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: state.visibleItems.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
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

class _FinishedGoodsFilterBar extends StatelessWidget {
  const _FinishedGoodsFilterBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinishedGoodsListBloc, FinishedGoodsListState>(
      buildWhen: (prev, curr) => prev.filter != curr.filter,
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: FinishedGoodsListFilter.values.map((filter) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter.label),
                  selected: state.filter == filter,
                  onSelected: (_) {
                    context.read<FinishedGoodsListBloc>().add(
                          FinishedGoodsListFilterChanged(filter),
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
