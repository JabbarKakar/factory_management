import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/raw_material/raw_material_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/raw_material_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_search_bar.dart';
import '../../widgets/raw_materials/raw_material_filter_bar.dart';
import '../../widgets/raw_materials/raw_material_list_tile.dart';
import '../../widgets/raw_materials/raw_material_low_stock_banner.dart';
import '../../widgets/raw_materials/raw_material_stock_summary_card.dart';

class RawMaterialsScreen extends StatefulWidget {
  const RawMaterialsScreen({this.initialFilter, super.key});

  final RawMaterialListFilter? initialFilter;

  @override
  State<RawMaterialsScreen> createState() => _RawMaterialsScreenState();
}

class _RawMaterialsScreenState extends State<RawMaterialsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filter = widget.initialFilter;
    if (filter != null && filter != RawMaterialListFilter.all) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<RawMaterialListBloc>().add(
              RawMaterialListFilterChanged(filter),
            );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchClear() {
    _searchController.clear();
    context.read<RawMaterialListBloc>().add(
          const RawMaterialListSearchChanged(''),
        );
  }

  void _viewLowStock() {
    context.read<RawMaterialListBloc>().add(
          const RawMaterialListFilterChanged(RawMaterialListFilter.lowStock),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<RawMaterialListBloc, RawMaterialListState>(
          buildWhen: (prev, curr) =>
              prev.visibleMaterials.length != curr.visibleMaterials.length ||
              prev.filter != curr.filter,
          builder: (context, state) {
            final appBarForeground =
                Theme.of(context).appBarTheme.foregroundColor ??
                    Theme.of(context).colorScheme.onSurface;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.rawMaterialStock),
                Text(
                  '${state.visibleMaterials.length} materials'
                  '${state.filter != RawMaterialListFilter.all ? ' · ${state.filter.label}' : ''}',
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<RawMaterialListBloc, RawMaterialListState>(
            buildWhen: (prev, curr) =>
                prev.materials != curr.materials ||
                prev.lowStockCount != curr.lowStockCount ||
                prev.status != curr.status,
            builder: (context, state) {
              if (state.status != RawMaterialListStatus.loaded ||
                  state.materials.isEmpty) {
                return const SizedBox.shrink();
              }

              return RawMaterialStockSummaryCard(
                materials: state.materials,
                lowStockCount: state.lowStockCount,
              );
            },
          ),
          BlocBuilder<RawMaterialListBloc, RawMaterialListState>(
            buildWhen: (prev, curr) =>
                prev.lowStockCount != curr.lowStockCount ||
                prev.filter != curr.filter,
            builder: (context, state) {
              if (state.lowStockCount <= 0 ||
                  state.filter == RawMaterialListFilter.lowStock) {
                return const SizedBox.shrink();
              }

              return RawMaterialLowStockBanner(
                lowStockCount: state.lowStockCount,
                onViewLowStock: _viewLowStock,
              );
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: JobWorkSearchBar(
              controller: _searchController,
              hintText: AppStrings.searchRawMaterials,
              onChanged: (value) => context
                  .read<RawMaterialListBloc>()
                  .add(RawMaterialListSearchChanged(value)),
              onClear: _onSearchClear,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<RawMaterialListBloc, RawMaterialListState>(
              buildWhen: (prev, curr) => prev.filter != curr.filter,
              builder: (context, state) {
                return RawMaterialFilterBar(
                  selected: state.filter,
                  onChanged: (filter) => context
                      .read<RawMaterialListBloc>()
                      .add(RawMaterialListFilterChanged(filter)),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<RawMaterialListBloc, RawMaterialListState>(
              builder: (context, state) {
                if (state.status == RawMaterialListStatus.loading &&
                    state.materials.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == RawMaterialListStatus.failure) {
                  return EmptyStateView(
                    icon: Icons.error_outline,
                    title: AppStrings.rawMaterialsLoadError,
                    subtitle: state.errorMessage,
                    action: ElevatedButton(
                      onPressed: () {
                        final factoryId = readFactoryId(context);
                        if (factoryId != null) {
                          context.read<RawMaterialListBloc>().add(
                                RawMaterialListWatchStarted(factoryId),
                              );
                        }
                      },
                      child: const Text(AppStrings.retry),
                    ),
                  );
                }

                if (state.visibleMaterials.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.inventory_2_outlined,
                    title: AppStrings.noRawMaterialsFound,
                    subtitle: AppStrings.tryDifferentSearch,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final factoryId = readFactoryId(context);
                    if (factoryId == null) return;
                    context.read<RawMaterialListBloc>().add(
                          RawMaterialListWatchStarted(factoryId),
                        );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 24),
                    itemCount: state.visibleMaterials.length,
                    itemBuilder: (context, index) {
                      final material = state.visibleMaterials[index];
                      return RawMaterialListTile(
                        material: material,
                        onTap: () => context.push(
                          RoutePaths.rawMaterialDetail(
                            material.materialType.name,
                          ),
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
