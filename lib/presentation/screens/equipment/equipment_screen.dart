import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/equipment/equipment_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/equipment.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/equipment_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/app_extended_fab.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_search_bar.dart';
import '../../widgets/equipment/equipment_filter_bar.dart';
import '../../widgets/equipment/equipment_list_tile.dart';
import '../../widgets/equipment/equipment_maintenance_banner.dart';
import '../../widgets/equipment/equipment_summary_card.dart';

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

  void _onSearchClear() {
    _searchController.clear();
    context.read<EquipmentListBloc>().add(const EquipmentListSearchChanged(''));
  }

  int _runningCount(List<Equipment> equipment) {
    return equipment
        .where((item) => item.status == EquipmentStatus.running)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<EquipmentListBloc, EquipmentListState>(
          buildWhen: (prev, curr) =>
              prev.visibleEquipment.length != curr.visibleEquipment.length ||
              prev.filter != curr.filter,
          builder: (context, state) {
            final appBarForeground =
                Theme.of(context).appBarTheme.foregroundColor ??
                    Theme.of(context).colorScheme.onSurface;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.factoryEquipment),
                Text(
                  '${state.visibleEquipment.length} machines'
                  '${state.filter != EquipmentListFilter.all ? ' · ${state.filter.label}' : ''}',
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
      floatingActionButton: context.userCanCreate(AppModule.equipment)
          ? AppExtendedFab(
              heroTag: 'fab-equipment',
              onPressed: () => context.push(RoutePaths.equipmentAdd),
              icon: Icons.precision_manufacturing_outlined,
              label: AppStrings.addEquipment,
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<EquipmentListBloc, EquipmentListState>(
            buildWhen: (prev, curr) =>
                prev.equipment != curr.equipment ||
                prev.maintenanceOverdueCount != curr.maintenanceOverdueCount ||
                prev.maintenanceDueSoonCount != curr.maintenanceDueSoonCount ||
                prev.status != curr.status,
            builder: (context, state) {
              if (state.status != EquipmentListStatus.loaded ||
                  state.equipment.isEmpty) {
                return const SizedBox.shrink();
              }

              return EquipmentSummaryCard(
                totalCount: state.equipment.length,
                runningCount: _runningCount(state.equipment),
                maintenanceDueCount: state.maintenanceOverdueCount +
                    state.maintenanceDueSoonCount,
              );
            },
          ),
          BlocBuilder<EquipmentListBloc, EquipmentListState>(
            buildWhen: (prev, curr) =>
                prev.maintenanceOverdueCount != curr.maintenanceOverdueCount ||
                prev.maintenanceDueSoonCount != curr.maintenanceDueSoonCount,
            builder: (context, state) {
              return EquipmentMaintenanceBanner(
                overdueCount: state.maintenanceOverdueCount,
                dueSoonCount: state.maintenanceDueSoonCount,
                onTap: () {
                  context.read<EquipmentListBloc>().add(
                        const EquipmentListFilterChanged(
                          EquipmentListFilter.maintenanceDue,
                        ),
                      );
                },
              );
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: JobWorkSearchBar(
              controller: _searchController,
              hintText: AppStrings.searchEquipment,
              onChanged: (value) => context
                  .read<EquipmentListBloc>()
                  .add(EquipmentListSearchChanged(value)),
              onClear: _onSearchClear,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<EquipmentListBloc, EquipmentListState>(
              buildWhen: (prev, curr) => prev.filter != curr.filter,
              builder: (context, state) {
                return EquipmentFilterBar(
                  selected: state.filter,
                  onChanged: (filter) => context.read<EquipmentListBloc>().add(
                        EquipmentListFilterChanged(filter),
                      ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
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
                  final hasFilters = state.searchQuery.isNotEmpty ||
                      state.filter != EquipmentListFilter.all;

                  return EmptyStateView(
                    icon: Icons.precision_manufacturing_outlined,
                    title: state.equipment.isEmpty
                        ? AppStrings.noEquipmentYet
                        : AppStrings.noEquipmentFound,
                    subtitle: state.equipment.isEmpty
                        ? AppStrings.noEquipmentHint
                        : AppStrings.tryDifferentSearch,
                    action: !hasFilters && state.equipment.isEmpty
                        ? FilledButton.icon(
                            onPressed: () =>
                                context.push(RoutePaths.equipmentAdd),
                            icon: const Icon(Icons.precision_manufacturing_outlined),
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
                    padding: const EdgeInsets.only(top: 4, bottom: 84),
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
