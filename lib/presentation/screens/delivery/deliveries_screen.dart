import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/delivery/delivery_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/delivery_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/account_menu_button.dart';
import '../../widgets/delivery/delivery_list_tile.dart';
import '../../widgets/delivery/delivery_stage_filter_bar.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_search_bar.dart';
import '../../widgets/notification_bell.dart';

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({this.initialFilter, super.key});

  final DeliveryListFilter? initialFilter;

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final filter = widget.initialFilter;
    if (filter != null && filter != DeliveryListFilter.all) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<DeliveryListBloc>().add(DeliveryListFilterChanged(filter));
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.85) {
      context.read<DeliveryListBloc>().add(const DeliveryListFetchNext());
    }
  }

  void _onSearchClear() {
    _searchController.clear();
    context.read<DeliveryListBloc>().add(const DeliveryListSearchChanged(''));
  }

  bool _isFilteredOut(DeliveryListState state) {
    return state.searchQuery.isNotEmpty ||
        state.filter != DeliveryListFilter.active ||
        state.deliveries.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<DeliveryListBloc, DeliveryListState>(
          buildWhen: (prev, curr) =>
              prev.visibleDeliveries.length != curr.visibleDeliveries.length ||
              prev.filter != curr.filter,
          builder: (context, state) {
            final appBarForeground =
                Theme.of(context).appBarTheme.foregroundColor ??
                    Theme.of(context).colorScheme.onSurface;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.deliveries),
                Text(
                  '${state.visibleDeliveries.length} deliveries'
                  '${state.filter != DeliveryListFilter.active ? ' · ${state.filter.label}' : ''}',
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: JobWorkSearchBar(
              controller: _searchController,
              hintText: AppStrings.searchDeliveries,
              onChanged: (value) => context
                  .read<DeliveryListBloc>()
                  .add(DeliveryListSearchChanged(value)),
              onClear: _onSearchClear,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<DeliveryListBloc, DeliveryListState>(
              buildWhen: (prev, curr) => prev.filter != curr.filter,
              builder: (context, state) {
                return DeliveryStageFilterBar(
                  selected: state.filter,
                  onChanged: (filter) => context.read<DeliveryListBloc>().add(
                        DeliveryListFilterChanged(filter),
                      ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<DeliveryListBloc, DeliveryListState>(
              builder: (context, state) {
                if (state.status == DeliveryListStatus.loading &&
                    state.deliveries.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == DeliveryListStatus.failure) {
                  return EmptyStateView(
                    icon: Icons.error_outline,
                    title: AppStrings.deliveriesLoadError,
                    subtitle: state.errorMessage,
                    action: ElevatedButton(
                      onPressed: () {
                        final factoryId = readFactoryId(context);
                        if (factoryId != null) {
                          context.read<DeliveryListBloc>().add(
                                DeliveryListWatchStarted(factoryId),
                              );
                        }
                      },
                      child: const Text(AppStrings.retry),
                    ),
                  );
                }

                if (state.visibleDeliveries.isEmpty) {
                  final filteredOut = _isFilteredOut(state);
                  final canOpenSales = context.userCanView(AppModule.sales);
                  return EmptyStateView(
                    icon: Icons.local_shipping_outlined,
                    title: filteredOut
                        ? AppStrings.noDeliveriesFound
                        : AppStrings.noDeliveriesYet,
                    subtitle: filteredOut
                        ? AppStrings.tryDifferentSearch
                        : AppStrings.noDeliveriesHint,
                    action: !filteredOut && canOpenSales
                        ? FilledButton.icon(
                            onPressed: () => context.go(
                              RoutePaths.salesList(filter: 'pendingDelivery'),
                            ),
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: const Text(
                              AppStrings.scheduleDeliveryFromOrder,
                            ),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final factoryId = readFactoryId(context);
                    if (factoryId != null) {
                      context.read<DeliveryListBloc>().add(
                            DeliveryListWatchStarted(
                              factoryId,
                              driverEmployeeId: readDriverEmployeeId(context),
                            ),
                          );
                    }
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 4, bottom: 24),
                    itemCount: state.visibleDeliveries.length +
                        (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.visibleDeliveries.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          ),
                        );
                      }

                      final delivery = state.visibleDeliveries[index];
                      return DeliveryListTile(
                        delivery: delivery,
                        onTap: () => context.push(
                          RoutePaths.deliveryDetail(delivery.id),
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
