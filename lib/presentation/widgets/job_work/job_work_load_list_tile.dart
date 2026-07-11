import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/job_work_load.dart';
import 'job_work_status_badge.dart';

/// Compact row for a Load under a Job Work container dashboard.
class JobWorkLoadListTile extends StatelessWidget {
  const JobWorkLoadListTile({
    required this.load,
    this.onTap,
    super.key,
  });

  final JobWorkLoad load;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final dateLabel = DateFormat.yMMMd().format(load.receivedDate);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      load.loadNumber.isEmpty
                          ? '${AppStrings.load} #${load.loadSequence}'
                          : load.loadNumber,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        dateLabel,
                        '${load.blockCount} ${AppStrings.blocks}',
                        if (load.marbleVariety.isNotEmpty) load.marbleVariety,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                    if (load.isVirtual || load.migratedFromJobWork) ...[
                      const SizedBox(height: 4),
                      Text(
                        load.isVirtual
                            ? AppStrings.virtualLoadHint
                            : AppStrings.migratedLoadHint,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              JobWorkStatusBadge(status: load.status, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}
