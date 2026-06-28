import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/supplier/supplier_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/supplier.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/supplier_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/app_extended_fab.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_search_bar.dart';
import '../../widgets/suppliers/supplier_filter_bar.dart';
import '../../widgets/suppliers/supplier_list_tile.dart';
import '../../widgets/suppliers/supplier_summary_card.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchClear() {
    _searchController.clear();
    context.read<SupplierListBloc>().add(const SupplierListSearchChanged(''));
  }

  int _countForType(List<Supplier> suppliers, SupplierType type) {
    return suppliers.where((s) => s.supplierType == type).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<SupplierListBloc, SupplierListState>(
          buildWhen: (prev, curr) =>
              prev.visibleSuppliers.length != curr.visibleSuppliers.length ||
              prev.supplierTypeFilter != curr.supplierTypeFilter,
          builder: (context, state) {
            final appBarForeground =
                Theme.of(context).appBarTheme.foregroundColor ??
                    Theme.of(context).colorScheme.onSurface;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.suppliers),
                Text(
                  '${state.visibleSuppliers.length} suppliers'
                  '${state.supplierTypeFilter != null ? ' · ${state.supplierTypeFilter!.label}' : ''}',
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
      floatingActionButton: context.userCanCreate(AppModule.suppliers)
          ? AppExtendedFab(
              heroTag: 'fab-suppliers',
              onPressed: () => context.push(RoutePaths.suppliersAdd),
              icon: Icons.add_business_outlined,
              label: AppStrings.addSupplier,
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<SupplierListBloc, SupplierListState>(
            buildWhen: (prev, curr) =>
                prev.suppliers != curr.suppliers ||
                prev.supplierTypeFilter != curr.supplierTypeFilter ||
                prev.status != curr.status,
            builder: (context, state) {
              if (state.status != SupplierListStatus.loaded ||
                  state.suppliers.isEmpty) {
                return const SizedBox.shrink();
              }

              final marbleCount = _countForType(
                state.suppliers,
                SupplierType.marbleBlockSlab,
              );
              final filteredCount = state.supplierTypeFilter != null
                  ? _countForType(state.suppliers, state.supplierTypeFilter!)
                  : null;

              return SupplierSummaryCard(
                totalCount: state.suppliers.length,
                marbleVendorCount: marbleCount,
                typeFilter: state.supplierTypeFilter,
                filteredCount: filteredCount,
              );
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: JobWorkSearchBar(
              controller: _searchController,
              hintText: AppStrings.searchSuppliers,
              onChanged: (value) => context
                  .read<SupplierListBloc>()
                  .add(SupplierListSearchChanged(value)),
              onClear: _onSearchClear,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<SupplierListBloc, SupplierListState>(
              buildWhen: (prev, curr) =>
                  prev.supplierTypeFilter != curr.supplierTypeFilter,
              builder: (context, state) {
                return SupplierFilterBar(
                  selected: state.supplierTypeFilter,
                  onChanged: (type) => context.read<SupplierListBloc>().add(
                        SupplierListFilterChanged(type),
                      ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<SupplierListBloc, SupplierListState>(
              builder: (context, state) {
                if (state.status == SupplierListStatus.loading &&
                    state.suppliers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == SupplierListStatus.failure) {
                  return EmptyStateView(
                    icon: Icons.error_outline,
                    title: AppStrings.suppliersLoadError,
                    subtitle: state.errorMessage,
                    action: ElevatedButton(
                      onPressed: () {
                        final factoryId = readFactoryId(context);
                        if (factoryId != null) {
                          context.read<SupplierListBloc>().add(
                                SupplierListWatchStarted(factoryId),
                              );
                        }
                      },
                      child: const Text(AppStrings.retry),
                    ),
                  );
                }

                if (state.visibleSuppliers.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.local_shipping_outlined,
                    title: state.searchQuery.isNotEmpty ||
                            state.supplierTypeFilter != null
                        ? AppStrings.noSuppliersFound
                        : AppStrings.noSuppliersYet,
                    subtitle: state.searchQuery.isNotEmpty ||
                            state.supplierTypeFilter != null
                        ? AppStrings.tryDifferentSearch
                        : AppStrings.addFirstSupplier,
                    action: state.searchQuery.isEmpty &&
                            state.supplierTypeFilter == null
                        ? ElevatedButton.icon(
                            onPressed: () =>
                                context.push(RoutePaths.suppliersAdd),
                            icon: const Icon(Icons.add),
                            label: const Text(AppStrings.addSupplier),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final factoryId = readFactoryId(context);
                    if (factoryId == null) return;
                    context.read<SupplierListBloc>().add(
                          SupplierListWatchStarted(factoryId),
                        );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 84),
                    itemCount: state.visibleSuppliers.length,
                    itemBuilder: (context, index) {
                      final supplier = state.visibleSuppliers[index];
                      return SupplierListTile(
                        supplier: supplier,
                        onTap: () => context.push(
                          RoutePaths.supplierDetail(supplier.id),
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
