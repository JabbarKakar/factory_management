import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/supplier/supplier_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/supplier_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/suppliers/supplier_list_tile.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.suppliers),
      ),
      floatingActionButton: context.userCanCreate(AppModule.suppliers)
          ? FloatingActionButton.extended(
              heroTag: 'fab-suppliers',
              onPressed: () => context.push(RoutePaths.suppliersAdd),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addSupplier),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchSuppliers,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<SupplierListBloc>()
                              .add(const SupplierListSearchChanged(''));
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context
                    .read<SupplierListBloc>()
                    .add(SupplierListSearchChanged(value));
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 8),
          const _SupplierTypeFilterBar(),
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
                    padding: const EdgeInsets.only(top: 8, bottom: 88),
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

class _SupplierTypeFilterBar extends StatelessWidget {
  const _SupplierTypeFilterBar();

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<SupplierListBloc>().state.supplierTypeFilter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text(AppStrings.all),
            selected: filter == null,
            onSelected: (_) => context.read<SupplierListBloc>().add(
                  const SupplierListFilterChanged(null),
                ),
          ),
          const SizedBox(width: 8),
          ...SupplierType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(type.label),
                selected: filter == type,
                onSelected: (_) => context.read<SupplierListBloc>().add(
                      SupplierListFilterChanged(type),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
