import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/equipment/equipment_list_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/equipment_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/equipment/equipment_list_tile.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({this.initialFilter, super.key});

  final EquipmentListFilter? initialFilter;

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filter = widget.initialFilter;
    if (filter != null && filter != EquipmentListFilter.all) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<EquipmentListBloc>().add(EquipmentListFilterChanged(filter));
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
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.factoryEquipment)),
      floatingActionButton: context.userCanCreate(AppModule.equipment)
          ? FloatingActionButton.extended(
              heroTag: 'fab-equipment',
              onPressed: () => context.push(RoutePaths.equipmentAdd),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text(AppStrings.addEquipment),
            )
          : null,
      body: Column(
        children: [
          BlocBuilder<EquipmentListBloc, EquipmentListState>(
            buildWhen: (prev, curr) =>
                prev.maintenanceOverdueCount != curr.maintenanceOverdueCount ||
                prev.maintenanceDueSoonCount != curr.maintenanceDueSoonCount,
            builder: (context, state) {
              if (state.maintenanceOverdueCount == 0 &&
                  state.maintenanceDueSoonCount == 0) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Card(
                  color: state.maintenanceOverdueCount > 0
                      ? AppColors.error.withValues(alpha: 0.08)
                      : AppColors.warning.withValues(alpha: 0.08),
                  child: ListTile(
                    leading: Icon(
                      state.maintenanceOverdueCount > 0
                          ? Icons.warning_amber_rounded
                          : Icons.build_circle_outlined,
                      color: state.maintenanceOverdueCount > 0
                          ? AppColors.error
                          : AppColors.warning,
                    ),
                    title: Text(
                      state.maintenanceOverdueCount > 0
                          ? '${state.maintenanceOverdueCount} ${AppStrings.maintenanceOverdue}'
                          : '${state.maintenanceDueSoonCount} ${AppStrings.maintenanceDueSoon}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.read<EquipmentListBloc>().add(
                            const EquipmentListFilterChanged(
                              EquipmentListFilter.maintenanceDue,
                            ),
                          );
                    },
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
                hintText: AppStrings.searchEquipment,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<EquipmentListBloc>()
                              .add(const EquipmentListSearchChanged(''));
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context
                    .read<EquipmentListBloc>()
                    .add(EquipmentListSearchChanged(value));
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 8),
          const _EquipmentFilterBar(),
          Expanded(
            child: BlocBuilder<EquipmentListBloc, EquipmentListState>(
              builder: (context, state) {
                if (state.status == EquipmentListStatus.loading &&
                    state.equipment.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == EquipmentListStatus.failure) {
                  return EmptyStateView(
                    icon: Icons.error_outline,
                    title: AppStrings.equipmentLoadError,
                    subtitle: state.errorMessage,
                    action: ElevatedButton(
                      onPressed: () {
                        final factoryId = readFactoryId(context);
                        if (factoryId != null) {
                          context.read<EquipmentListBloc>().add(
                                EquipmentListWatchStarted(factoryId),
                              );
                        }
                      },
                      child: const Text(AppStrings.retry),
                    ),
                  );
                }

                if (state.visibleEquipment.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.precision_manufacturing_outlined,
                    title: state.equipment.isEmpty
                        ? AppStrings.noEquipmentYet
                        : AppStrings.noEquipmentFound,
                    subtitle: state.equipment.isEmpty
                        ? AppStrings.noEquipmentHint
                        : null,
                    action: state.equipment.isEmpty
                        ? FilledButton.icon(
                            onPressed: () =>
                                context.push(RoutePaths.equipmentAdd),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text(AppStrings.addEquipment),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final factoryId = readFactoryId(context);
                    if (factoryId != null) {
                      context.read<EquipmentListBloc>().add(
                            EquipmentListWatchStarted(factoryId),
                          );
                    }
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: state.visibleEquipment.length,
                    itemBuilder: (context, index) {
                      final item = state.visibleEquipment[index];
                      return EquipmentListTile(
                        equipment: item,
                        onTap: () =>
                            context.push(RoutePaths.equipmentDetail(item.id)),
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

class _EquipmentFilterBar extends StatelessWidget {
  const _EquipmentFilterBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EquipmentListBloc, EquipmentListState>(
      buildWhen: (prev, curr) => prev.filter != curr.filter,
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: EquipmentListFilter.values.map((filter) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter.label),
                  selected: state.filter == filter,
                  onSelected: (_) {
                    context.read<EquipmentListBloc>().add(
                          EquipmentListFilterChanged(filter),
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
