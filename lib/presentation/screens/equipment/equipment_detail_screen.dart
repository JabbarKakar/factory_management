import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/equipment/equipment_detail_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/app_extended_fab.dart';
import '../../widgets/equipment/equipment_status_badge.dart';
import '../../widgets/equipment/maintenance_log_tile.dart';
import '../../widgets/settings_section.dart';

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
            title: const Text(AppStrings.equipmentDetails),
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
          floatingActionButton: context.userCanCreate(AppModule.equipment)
              ? AppExtendedFab(
                  heroTag: 'fab-record-maintenance-$equipmentId',
                  onPressed: () => context.push(
                    RoutePaths.equipmentRecordMaintenance(equipment.id),
                  ),
                  icon: Icons.build_circle_outlined,
                  label: AppStrings.recordMaintenance,
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              equipment.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          EquipmentStatusBadge(status: equipment.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        equipment.equipmentNumber,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(equipment.displaySubtitle),
                      if (overdue || dueSoon) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (overdue ? AppColors.error : AppColors.warning)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            overdue
                                ? AppStrings.maintenanceOverdueMessage
                                : AppStrings.maintenanceDueSoonMessage,
                            style: TextStyle(
                              color: overdue ? AppColors.error : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (hasSpecs)
                SettingsSection(
                  title: AppStrings.equipmentSpecs,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (equipment.brand != null &&
                            equipment.brand!.isNotEmpty)
                          _Row(AppStrings.brand, equipment.brand!),
                        if (equipment.model != null &&
                            equipment.model!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _Row(AppStrings.model, equipment.model!),
                        ],
                        if (equipment.serialNumber != null &&
                            equipment.serialNumber!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _Row(
                            AppStrings.serialNumber,
                            equipment.serialNumber!,
                          ),
                        ],
                        if (equipment.location != null &&
                            equipment.location!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _Row(
                            AppStrings.equipmentLocation,
                            equipment.location!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              if (hasPurchaseInfo)
                SettingsSection(
                  title: AppStrings.purchaseInfo,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (equipment.purchaseDate != null) ...[
                          _Row(
                            AppStrings.purchaseDate,
                            DateFormat.yMMMd().format(equipment.purchaseDate!),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (equipment.purchaseCost != null) ...[
                          _Row(
                            AppStrings.purchaseCost,
                            Formatters.currencyPkr(equipment.purchaseCost!),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (equipment.supplierName != null &&
                            equipment.supplierName!.isNotEmpty) ...[
                          _Row(
                            AppStrings.supplierVendor,
                            equipment.supplierName!,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (bookValue != null)
                          _Row(
                            AppStrings.bookValue,
                            Formatters.currencyPkr(bookValue),
                            bold: true,
                          ),
                      ],
                    ),
                  ),
                ),
              if (hasMaintenanceSchedule)
                SettingsSection(
                  title: AppStrings.maintenanceSchedule,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (equipment.lastMaintenanceDate != null) ...[
                          _Row(
                            AppStrings.lastMaintenanceDate,
                            DateFormat.yMMMd()
                                .format(equipment.lastMaintenanceDate!),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (equipment.nextMaintenanceDueDate != null)
                          _Row(
                            AppStrings.nextMaintenanceDue,
                            DateFormat.yMMMd()
                                .format(equipment.nextMaintenanceDueDate!),
                            bold: overdue || dueSoon,
                          ),
                        if (equipment.maintenanceIntervalDays != null) ...[
                          const SizedBox(height: 8),
                          _Row(
                            AppStrings.maintenanceIntervalDays,
                            '${equipment.maintenanceIntervalDays} days',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              SettingsSection(
                title: AppStrings.maintenanceHistory,
                child: logs.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          AppStrings.noMaintenanceLogs,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _Row(
                              AppStrings.totalMaintenanceCost,
                              Formatters.currencyPkr(totalMaintenanceCost),
                              bold: true,
                            ),
                            if (totalDowntimeHours > 0) ...[
                              const SizedBox(height: 8),
                              _Row(
                                AppStrings.totalDowntimeHours,
                                '${totalDowntimeHours.toStringAsFixed(1)} h',
                              ),
                            ],
                            const Divider(height: 24),
                            for (final log in logs) ...[
                              MaintenanceLogTile(log: log),
                              if (log != logs.last) const Divider(),
                            ],
                          ],
                        ),
                      ),
              ),
              if (equipment.notes != null && equipment.notes!.isNotEmpty)
                SettingsSection(
                  title: AppStrings.notes,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(equipment.notes!),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: TextStyle(color: muted)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
