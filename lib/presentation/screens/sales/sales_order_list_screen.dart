import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/sales/sales_order_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/sales_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/sales/sales_order_list_tile.dart';

class SalesOrderListScreen extends StatefulWidget {
  const SalesOrderListScreen({super.key});

  @override
  State<SalesOrderListScreen> createState() => _SalesOrderListScreenState();
}

class _SalesOrderListScreenState extends State<SalesOrderListScreen> {
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
        title: const Text(AppStrings.sales),
        actions: const [
          NotificationBell(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-sales',
        onPressed: () => context.push(RoutePaths.salesAdd),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newSalesOrder),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchSalesOrders,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<SalesOrderListBloc>()
                              .add(const SalesOrderListSearchChanged(''));
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context
                    .read<SalesOrderListBloc>()
                    .add(SalesOrderListSearchChanged(value));
                setState(() {});
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BlocBuilder<SalesOrderListBloc, SalesOrderListState>(
              buildWhen: (prev, curr) =>
                  prev.showActiveOnly != curr.showActiveOnly ||
                  prev.stageFilter != curr.stageFilter,
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilterChip(
                      label: const Text(AppStrings.activeOrdersOnly),
                      selected: state.showActiveOnly,
                      onSelected: (selected) {
                        context.read<SalesOrderListBloc>().add(
                              SalesOrderListStatusFilterChanged(selected),
                            );
                      },
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: SalesListFilter.values.map((filter) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter.label),
                              selected: state.stageFilter == filter,
                              onSelected: (_) {
                                context.read<SalesOrderListBloc>().add(
                                      SalesOrderListStageFilterChanged(filter),
                                    );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<SalesOrderListBloc, SalesOrderListState>(
              builder: (context, state) {
                if (state.status == SalesOrderListStatus.loading &&
                    state.orders.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == SalesOrderListStatus.failure) {
                  return EmptyStateView(
                    icon: Icons.error_outline,
                    title: AppStrings.salesLoadError,
                    subtitle: state.errorMessage,
                    action: ElevatedButton(
                      onPressed: () {
                        final factoryId = readFactoryId(context);
                        if (factoryId != null) {
                          context.read<SalesOrderListBloc>().add(
                                SalesOrderListWatchStarted(factoryId),
                              );
                        }
                      },
                      child: const Text(AppStrings.retry),
                    ),
                  );
                }

                if (state.visibleOrders.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.shopping_bag_outlined,
                    title: state.searchQuery.isNotEmpty ||
                            state.stageFilter != SalesListFilter.all ||
                            !state.showActiveOnly
                        ? AppStrings.noSalesOrdersFound
                        : AppStrings.noSalesOrdersYet,
                    subtitle: state.searchQuery.isNotEmpty
                        ? AppStrings.tryDifferentSearch
                        : AppStrings.addFirstSalesOrder,
                    action: state.searchQuery.isEmpty
                        ? ElevatedButton.icon(
                            onPressed: () => context.push(RoutePaths.salesAdd),
                            icon: const Icon(Icons.add),
                            label: const Text(AppStrings.newSalesOrder),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final factoryId = readFactoryId(context);
                    if (factoryId == null) return;
                    context.read<SalesOrderListBloc>().add(
                          SalesOrderListWatchStarted(factoryId),
                        );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 88),
                    itemCount: state.visibleOrders.length,
                    itemBuilder: (context, index) {
                      final order = state.visibleOrders[index];
                      return SalesOrderListTile(
                        order: order,
                        onTap: () => context.push(
                          RoutePaths.salesDetail(order.id),
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
