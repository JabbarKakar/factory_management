import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/delivery/delivery_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/delivery_enums.dart';
import '../../../domain/extensions/app_user_permissions.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../widgets/account_menu_button.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/delivery/delivery_list_tile.dart';
import '../../widgets/notification_bell.dart';

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({this.initialFilter, super.key});

  final DeliveryListFilter? initialFilter;

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final canScheduleDelivery =
        user?.canCreate(AppModule.delivery) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.deliveries),
        actions: const [
          NotificationBell(),
          AccountMenuButton(),
        ],
      ),
      floatingActionButton: canScheduleDelivery
          ? FloatingActionButton.extended(
              heroTag: 'fab-deliveries',
              onPressed: () => context.push(RoutePaths.deliveriesAdd),
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text(AppStrings.scheduleDelivery),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchDeliveries,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<DeliveryListBloc>()
                              .add(const DeliveryListSearchChanged(''));
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context
                    .read<DeliveryListBloc>()
                    .add(DeliveryListSearchChanged(value));
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 8),
          const _DeliveryFilterBar(),
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
                  return EmptyStateView(
                    icon: Icons.local_shipping_outlined,
                    title: state.deliveries.isEmpty
                        ? AppStrings.noDeliveriesYet
                        : AppStrings.noDeliveriesFound,
                    subtitle: state.deliveries.isEmpty
                        ? AppStrings.noDeliveriesHint
                        : null,
                    action: state.deliveries.isEmpty && canScheduleDelivery
                        ? FilledButton.icon(
                            onPressed: () =>
                                context.push(RoutePaths.deliveriesAdd),
                            icon: const Icon(Icons.local_shipping_outlined),
                            label: const Text(AppStrings.scheduleDelivery),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final factoryId = readFactoryId(context);
                    if (factoryId != null) {
                      context.read<DeliveryListBloc>().add(
                            DeliveryListWatchStarted(factoryId),
                          );
                    }
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: state.visibleDeliveries.length,
                    itemBuilder: (context, index) {
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

class _DeliveryFilterBar extends StatelessWidget {
  const _DeliveryFilterBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeliveryListBloc, DeliveryListState>(
      buildWhen: (prev, curr) => prev.filter != curr.filter,
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: DeliveryListFilter.values.map((filter) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter.label),
                  selected: state.filter == filter,
                  onSelected: (_) {
                    context.read<DeliveryListBloc>().add(
                          DeliveryListFilterChanged(filter),
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
