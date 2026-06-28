import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/maintenance_log.dart';
import '../job_work/job_work_detail_section.dart';

class EquipmentMaintenanceHistorySection extends StatelessWidget {
  const EquipmentMaintenanceHistorySection({
    required this.logs,
    required this.totalMaintenanceCost,
    required this.totalDowntimeHours,
    super.key,
  });

  final List<MaintenanceLog> logs;
  final double totalMaintenanceCost;
  final double totalDowntimeHours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return JobWorkDetailSection(
      title: AppStrings.maintenanceHistory,
      icon: Icons.history_rounded,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: logs.isEmpty
            ? Text(
                AppStrings.noMaintenanceLogs,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.35,
                  color: muted,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.totalMaintenanceCost,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              Formatters.currencyPkr(totalMaintenanceCost),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.primary,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (totalDowntimeHours > 0)
                        Text(
                          '${totalDowntimeHours.toStringAsFixed(1)} h downtime',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < logs.length; i++) ...[
                    _MaintenanceLogRow(log: logs[i]),
                    if (i < logs.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
      ),
    );
  }
}

class _MaintenanceLogRow extends StatelessWidget {
  const _MaintenanceLogRow({required this.log});

  final MaintenanceLog log;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final dateLabel = DateFormat.yMMMd().format(log.maintenanceDate);

    final subtitleParts = <String>[
      log.performedBy.label,
      if (log.performedByName != null && log.performedByName!.isNotEmpty)
        log.performedByName!,
      if (log.downtimeHours != null && log.downtimeHours! > 0)
        '${log.downtimeHours}h downtime',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.build_circle_outlined,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.maintenanceType.label} · $dateLabel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  log.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        height: 1.25,
                        color: muted,
                      ),
                ),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitleParts.join(' · '),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: muted,
                          fontSize: 10,
                          height: 1.2,
                        ),
                  ),
                ],
                if (log.nextDueDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Next due ${DateFormat.yMMMd().format(log.nextDueDate!)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: muted,
                          fontSize: 10,
                          height: 1.2,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Formatters.currencyPkr(log.cost),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }
}
