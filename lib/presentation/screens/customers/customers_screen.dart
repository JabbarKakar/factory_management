import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/customer/customer_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/account_menu_button.dart';
import '../../widgets/customers/customer_list_tile.dart';
import '../../widgets/customers/customer_service_type_filter_bar.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_search_bar.dart';
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

  void _onSearchClear() {
    _searchController.clear();
    context.read<CustomerListBloc>().add(const CustomerListSearchChanged(''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<CustomerListBloc, CustomerListState>(
          buildWhen: (prev, curr) =>
              prev.visibleCustomers.length != curr.visibleCustomers.length ||
              prev.serviceTypeFilter != curr.serviceTypeFilter,
          builder: (context, state) {
            final appBarForeground =
                Theme.of(context).appBarTheme.foregroundColor ??
                    Theme.of(context).colorScheme.onSurface;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.customers),
                Text(
                  '${state.visibleCustomers.length} customers'
                  '${state.serviceTypeFilter != null ? ' · ${state.serviceTypeFilter!.label}' : ''}',
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
      floatingActionButton: context.userCanCreate(AppModule.customers)
          ? FloatingActionButton.extended(
              heroTag: 'fab-customers',
              onPressed: () => context.push(RoutePaths.customersAdd),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text(AppStrings.addCustomer),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: JobWorkSearchBar(
              controller: _searchController,
              hintText: AppStrings.searchCustomers,
              onChanged: (value) => context
                  .read<CustomerListBloc>()
                  .add(CustomerListSearchChanged(value)),
              onClear: _onSearchClear,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<CustomerListBloc, CustomerListState>(
              buildWhen: (prev, curr) =>
                  prev.serviceTypeFilter != curr.serviceTypeFilter,
              builder: (context, state) {
                return CustomerServiceTypeFilterBar(
                  selected: state.serviceTypeFilter,
                  onChanged: (filter) => context.read<CustomerListBloc>().add(
                        CustomerListFilterChanged(filter),
                      ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
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
                            state.serviceTypeFilter == null &&
                            context.userCanCreate(AppModule.customers)
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
                    padding: const EdgeInsets.only(top: 4, bottom: 88),
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
