import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/sales/sales_order_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/sales_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/account_menu_button.dart';
import '../../widgets/app_extended_fab.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_search_bar.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/sales/sales_order_list_tile.dart';
import '../../widgets/sales/sales_order_stage_filter_bar.dart';

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

  void _onSearchClear() {
    _searchController.clear();
    context.read<SalesOrderListBloc>().add(const SalesOrderListSearchChanged(''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<SalesOrderListBloc, SalesOrderListState>(
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
                const Text(AppStrings.sales),
                Text(
                  '${state.visibleOrders.length} orders'
                  '${state.stageFilter != SalesListFilter.all ? ' · ${state.stageFilter.label}' : ''}',
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
      floatingActionButton: context.userCanCreate(AppModule.sales)
          ? AppExtendedFab(
              heroTag: 'fab-sales',
              onPressed: () => context.push(RoutePaths.salesAdd),
              icon: Icons.shopping_cart_outlined,
              label: AppStrings.newSalesOrder,
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: JobWorkSearchBar(
              controller: _searchController,
              hintText: AppStrings.searchSalesOrders,
              onChanged: (value) => context
                  .read<SalesOrderListBloc>()
                  .add(SalesOrderListSearchChanged(value)),
              onClear: _onSearchClear,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<SalesOrderListBloc, SalesOrderListState>(
              buildWhen: (prev, curr) => prev.stageFilter != curr.stageFilter,
              builder: (context, state) {
                return SalesOrderStageFilterBar(
                  selected: state.stageFilter,
                  onChanged: (filter) => context.read<SalesOrderListBloc>().add(
                        SalesOrderListStageFilterChanged(filter),
                      ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
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
                            state.stageFilter != SalesListFilter.all
                        ? AppStrings.noSalesOrdersFound
                        : AppStrings.noSalesOrdersYet,
                    subtitle: state.searchQuery.isNotEmpty ||
                            state.stageFilter != SalesListFilter.all
                        ? AppStrings.tryDifferentSearch
                        : AppStrings.addFirstSalesOrder,
                    action: state.searchQuery.isEmpty &&
                            state.stageFilter == SalesListFilter.all &&
                            context.userCanCreate(AppModule.sales)
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
