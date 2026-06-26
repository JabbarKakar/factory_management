import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/customer/customer_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/customer_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../widgets/customers/customer_list_tile.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/notification_bell.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
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
        title: const Text(AppStrings.customers),
        actions: const [
          NotificationBell(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-customers',
        onPressed: () => context.push(RoutePaths.customersAdd),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text(AppStrings.addCustomer),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchCustomers,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<CustomerListBloc>()
                              .add(const CustomerListSearchChanged(''));
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context
                    .read<CustomerListBloc>()
                    .add(CustomerListSearchChanged(value));
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 8),
          _ServiceTypeFilterBar(),
          Expanded(
            child: BlocBuilder<CustomerListBloc, CustomerListState>(
              builder: (context, state) {
                if (state.status == CustomerListStatus.loading &&
                    state.customers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == CustomerListStatus.failure) {
                  return EmptyStateView(
                    icon: Icons.error_outline,
                    title: AppStrings.customersLoadError,
                    subtitle: state.errorMessage,
                    action: ElevatedButton(
                      onPressed: () {
                        final factoryId = readFactoryId(context);
                        if (factoryId != null) {
                          context.read<CustomerListBloc>().add(
                                CustomerListWatchStarted(factoryId),
                              );
                        }
                      },
                      child: const Text(AppStrings.retry),
                    ),
                  );
                }

                if (state.visibleCustomers.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.people_outline,
                    title: state.searchQuery.isNotEmpty ||
                            state.serviceTypeFilter != null
                        ? AppStrings.noCustomersFound
                        : AppStrings.noCustomersYet,
                    subtitle: state.searchQuery.isNotEmpty ||
                            state.serviceTypeFilter != null
                        ? AppStrings.tryDifferentSearch
                        : AppStrings.addFirstCustomer,
                    action: state.searchQuery.isEmpty &&
                            state.serviceTypeFilter == null
                        ? ElevatedButton.icon(
                            onPressed: () =>
                                context.push(RoutePaths.customersAdd),
                            icon: const Icon(Icons.person_add_alt_1_outlined),
                            label: const Text(AppStrings.addCustomer),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final factoryId = readFactoryId(context);
                    if (factoryId == null) return;
                    context.read<CustomerListBloc>().add(
                          CustomerListWatchStarted(factoryId),
                        );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 88),
                    itemCount: state.visibleCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = state.visibleCustomers[index];
                      return CustomerListTile(
                        customer: customer,
                        onTap: () => context.push(
                          RoutePaths.customerDetail(customer.id),
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

class _ServiceTypeFilterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final filter = context.watch<CustomerListBloc>().state.serviceTypeFilter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text(AppStrings.all),
            selected: filter == null,
            onSelected: (_) => context.read<CustomerListBloc>().add(
                  const CustomerListFilterChanged(null),
                ),
          ),
          const SizedBox(width: 8),
          ...CustomerServiceType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(type.label),
                selected: filter == type,
                onSelected: (_) => context.read<CustomerListBloc>().add(
                      CustomerListFilterChanged(type),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
