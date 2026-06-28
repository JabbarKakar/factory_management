import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/equipment/equipment_detail_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/equipment/equipment_detail_hero.dart';
import '../../widgets/equipment/equipment_maintenance_action_bar.dart';
import '../../widgets/equipment/equipment_maintenance_history_section.dart';
import '../../widgets/job_work/job_work_detail_row.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class EquipmentDetailScreen extends StatelessWidget {
  const EquipmentDetailScreen({required this.equipmentId, super.key});

  final String equipmentId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EquipmentDetailBloc, EquipmentDetailState>(
      builder: (context, state) {
        if (state.status == EquipmentDetailStatus.loading ||
            state.status == EquipmentDetailStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.equipmentDetails)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final equipment = state.equipment;
        if (equipment == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.equipmentDetails)),
            body: Center(
              child: Text(state.errorMessage ?? AppStrings.equipmentNotFound),
            ),
          );
        }

        final today = DateTime.now();
        final overdue = equipment.isMaintenanceOverdue(today: today);
        final dueSoon =
            !overdue && equipment.isMaintenanceDueSoon(today: today);
        final bookValue = equipment.bookValue();
        final logs = state.maintenanceLogs;
        final totalMaintenanceCost =
            logs.fold<double>(0, (sum, log) => sum + log.cost);
        final totalDowntimeHours = logs.fold<double>(
          0,
          (sum, log) => sum + (log.downtimeHours ?? 0),
        );

        final hasSpecs =
            (equipment.brand?.isNotEmpty ?? false) ||
            (equipment.model?.isNotEmpty ?? false) ||
            (equipment.serialNumber?.isNotEmpty ?? false) ||
            (equipment.location?.isNotEmpty ?? false);
        final hasPurchaseInfo = equipment.purchaseDate != null ||
            equipment.purchaseCost != null ||
            (equipment.supplierName?.isNotEmpty ?? false) ||
            bookValue != null;
        final hasMaintenanceSchedule =
            equipment.lastMaintenanceDate != null ||
            equipment.nextMaintenanceDueDate != null ||
            equipment.maintenanceIntervalDays != null;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.equipmentDetails),
                Text(
                  equipment.name,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: (Theme.of(context).appBarTheme.foregroundColor ??
                                Theme.of(context).colorScheme.onSurface)
                            .withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
            actions: [
              if (context.userCanEdit(AppModule.equipment))
                IconButton(
                  onPressed: () async {
                    final updated = await context.push<bool>(
                      RoutePaths.equipmentEdit(equipment.id),
                    );
                    if (updated == true && context.mounted) {
                      context.read<EquipmentDetailBloc>().add(
                            EquipmentDetailWatchStarted(equipmentId),
                          );
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: AppStrings.editEquipment,
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              EquipmentDetailHero(
                equipment: equipment,
                overdue: overdue,
                dueSoon: dueSoon,
                bookValue: bookValue,
              ),
              if (context.userCanCreate(AppModule.equipment))
                EquipmentMaintenanceActionBar(
                  onPressed: () => context.push(
                    RoutePaths.equipmentRecordMaintenance(equipment.id),
                  ),
                ),
              if (hasSpecs)
                JobWorkDetailSection(
                  title: AppStrings.equipmentSpecs,
                  icon: Icons.tune_outlined,
                  child: JobWorkDetailRows(
                    rows: [
                      if (equipment.brand != null &&
                          equipment.brand!.isNotEmpty)
                        JobWorkDetailRow(
                          label: AppStrings.brand,
                          value: equipment.brand!,
                        ),
                      if (equipment.model != null &&
                          equipment.model!.isNotEmpty)
                        JobWorkDetailRow(
                          label: AppStrings.model,
                          value: equipment.model!,
                        ),
                      if (equipment.serialNumber != null &&
                          equipment.serialNumber!.isNotEmpty)
                        JobWorkDetailRow(
                          label: AppStrings.serialNumber,
                          value: equipment.serialNumber!,
                        ),
                      if (equipment.location != null &&
                          equipment.location!.isNotEmpty)
                        JobWorkDetailRow(
                          label: AppStrings.equipmentLocation,
                          value: equipment.location!,
                        ),
                    ],
                  ),
                ),
              if (hasPurchaseInfo)
                JobWorkDetailSection(
                  title: AppStrings.purchaseInfo,
                  icon: Icons.receipt_long_outlined,
                  child: JobWorkDetailRows(
                    rows: [
                      if (equipment.purchaseDate != null)
                        JobWorkDetailRow(
                          label: AppStrings.purchaseDate,
                          value: DateFormat.yMMMd()
                              .format(equipment.purchaseDate!),
                        ),
                      if (equipment.purchaseCost != null)
                        JobWorkDetailRow(
                          label: AppStrings.purchaseCost,
                          value:
                              Formatters.currencyPkr(equipment.purchaseCost!),
                        ),
                      if (equipment.supplierName != null &&
                          equipment.supplierName!.isNotEmpty)
                        JobWorkDetailRow(
                          label: AppStrings.supplierVendor,
                          value: equipment.supplierName!,
                        ),
                    ],
                  ),
                ),
              if (hasMaintenanceSchedule)
                JobWorkDetailSection(
                  title: AppStrings.maintenanceSchedule,
                  icon: Icons.event_repeat_outlined,
                  child: JobWorkDetailRows(
                    rows: [
                      if (equipment.lastMaintenanceDate != null)
                        JobWorkDetailRow(
                          label: AppStrings.lastMaintenanceDate,
                          value: DateFormat.yMMMd()
                              .format(equipment.lastMaintenanceDate!),
                        ),
                      if (equipment.nextMaintenanceDueDate != null)
                        JobWorkDetailRow(
                          label: AppStrings.nextMaintenanceDue,
                          value: DateFormat.yMMMd()
                              .format(equipment.nextMaintenanceDueDate!),
                          highlight: overdue || dueSoon,
                          bold: overdue || dueSoon,
                        ),
                      if (equipment.maintenanceIntervalDays != null)
                        JobWorkDetailRow(
                          label: AppStrings.maintenanceIntervalDays,
                          value: '${equipment.maintenanceIntervalDays} days',
                        ),
                    ],
                  ),
                ),
              EquipmentMaintenanceHistorySection(
                logs: logs,
                totalMaintenanceCost: totalMaintenanceCost,
                totalDowntimeHours: totalDowntimeHours,
              ),
              if (equipment.notes != null && equipment.notes!.isNotEmpty)
                JobWorkDetailSection(
                  title: AppStrings.notes,
                  icon: Icons.notes_outlined,
                  child: JobWorkDetailRows(
                    rows: [
                      JobWorkDetailRow(
                        label: AppStrings.notes,
                        value: equipment.notes!,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
