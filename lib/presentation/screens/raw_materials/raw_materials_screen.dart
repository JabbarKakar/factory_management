import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/raw_material/raw_material_list_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/raw_material_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/raw_materials/raw_material_list_tile.dart';

class RawMaterialsScreen extends StatefulWidget {
  const RawMaterialsScreen({super.key});

  @override
  State<RawMaterialsScreen> createState() => _RawMaterialsScreenState();
}

class _RawMaterialsScreenState extends State<RawMaterialsScreen> {
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
        title: const Text(AppStrings.rawMaterialStock),
      ),
      body: Column(
        children: [
          BlocBuilder<RawMaterialListBloc, RawMaterialListState>(
            buildWhen: (prev, curr) => prev.lowStockCount != curr.lowStockCount,
            builder: (context, state) {
              if (state.lowStockCount <= 0) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Card(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  child: ListTile(
                    leading: Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning),
                    title: Text(AppStrings.lowStockMaterials),
                    subtitle: Text('${state.lowStockCount} material(s)'),
                    trailing: TextButton(
                      onPressed: () => context.read<RawMaterialListBloc>().add(
                            const RawMaterialListFilterChanged(
                              RawMaterialListFilter.lowStock,
                            ),
                          ),
                      child: const Text(AppStrings.lowStock),
                    ),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchRawMaterials,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<RawMaterialListBloc>().add(
                                const RawMaterialListSearchChanged(''),
                              );
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context
                    .read<RawMaterialListBloc>()
                    .add(RawMaterialListSearchChanged(value));
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 8),
          const _RawMaterialFilterBar(),
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
                    title: AppStrings.noStockMovementsFound,
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
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
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

class _RawMaterialFilterBar extends StatelessWidget {
  const _RawMaterialFilterBar();

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<RawMaterialListBloc>().state.filter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: RawMaterialListFilter.values.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(item.label),
              selected: filter == item,
              onSelected: (_) => context.read<RawMaterialListBloc>().add(
                    RawMaterialListFilterChanged(item),
                  ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
