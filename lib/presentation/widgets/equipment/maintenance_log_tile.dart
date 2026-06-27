import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/maintenance_log.dart';

class MaintenanceLogTile extends StatelessWidget {
  const MaintenanceLogTile({required this.log, super.key});

  final MaintenanceLog log;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        '${log.maintenanceType.label} · ${DateFormat.yMMMd().format(log.maintenanceDate)}',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(log.description),
          const SizedBox(height: 4),
          Text(
            '${log.performedBy.label}'
            '${log.performedByName != null && log.performedByName!.isNotEmpty ? ' · ${log.performedByName}' : ''}'
            '${log.downtimeHours != null && log.downtimeHours! > 0 ? ' · ${log.downtimeHours}h downtime' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (log.nextDueDate != null)
            Text(
              'Next due ${DateFormat.yMMMd().format(log.nextDueDate!)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
        ],
      ),
      trailing: Text(
        Formatters.currencyPkr(log.cost),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
