import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/customer/customer_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/job_work_repository.dart';
import '../../../data/repositories/sales_invoice_repository.dart';
import '../../../data/repositories/sales_order_repository.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/account_menu_button.dart';
import '../../widgets/customers/customer_list_tile.dart';
import '../../widgets/customers/customer_service_type_filter_bar.dart';
import '../../widgets/app_extended_fab.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_search_bar.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/tile_options_menu.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();
  String? _busyCustomerId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchClear() {
    _searchController.clear();
    context.read<CustomerListBloc>().add(const CustomerListSearchChanged(''));
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  Future<void> _confirmDelete(Customer customer) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deleteCustomerTitle,
      message: AppStrings.deleteCustomerMessage,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busyCustomerId = customer.id);

    try {
      // Same cascade as CustomerFormBloc: remove dependent records first.
      await getIt<SalesInvoiceRepository>()
          .deleteInvoicesForCustomer(customer.id);
      await getIt<SalesOrderRepository>().deleteOrdersForCustomer(customer.id);
      await getIt<JobWorkRepository>().deleteOrdersForCustomer(customer.id);
      await getIt<CustomerRepository>().deleteCustomer(customer.id);
      if (!mounted) return;
      _showSnack(AppStrings.customerDeleted);
    } catch (_) {
      if (!mounted) return;
      _showSnack(AppStrings.customerDeleteError, isError: true);
    } finally {
      if (mounted) {
        setState(() => _busyCustomerId = null);
      }
    }
  }

  List<TileMenuAction> _menuActionsFor(
    Customer customer, {
    required bool canEdit,
    required bool canDelete,
  }) {
    final actions = <TileMenuAction>[];

    if (canEdit) {
      actions.add(
        TileMenuAction(
          label: AppStrings.editCustomer,
          icon: Icons.edit_outlined,
          onSelected: () =>
              context.push(RoutePaths.customerEdit(customer.id)),
        ),
      );
    }

    actions.add(
      TileMenuAction(
        label: AppStrings.customerStatement,
        icon: Icons.receipt_long_outlined,
        onSelected: () =>
            context.push(RoutePaths.customerStatement(customer.id)),
      ),
    );

    if (canDelete) {
      actions.add(
        TileMenuAction(
          label: AppStrings.delete,
          icon: Icons.delete_outline_rounded,
          destructive: true,
          onSelected: () => _confirmDelete(customer),
        ),
      );
    }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = context.userCanEdit(AppModule.customers);
    final canDelete = context.userCanDelete(AppModule.customers);

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
          ? AppExtendedFab(
              heroTag: 'fab-customers',
              onPressed: () => context.push(RoutePaths.customersAdd),
              icon: Icons.person_add_alt_1_outlined,
              label: AppStrings.addCustomer,
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
                        isBusy: _busyCustomerId == customer.id,
                        menuActions: _menuActionsFor(
                          customer,
                          canEdit: canEdit,
                          canDelete: canDelete,
                        ),
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
