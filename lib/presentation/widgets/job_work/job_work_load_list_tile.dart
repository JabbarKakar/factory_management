import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/job_work_load.dart';
import '../../../domain/enums/job_work_enums.dart';
import 'job_work_status_badge.dart';

/// Compact row for a Load under a Job Work container dashboard.
class JobWorkLoadListTile extends StatelessWidget {
  const JobWorkLoadListTile({
    required this.load,
    this.onTap,
    this.onRecordOutput,
    this.onAdvanceStatus,
    this.onAdvanceCompletion,
    this.onRecordQc,
    this.isBusy = false,
    super.key,
  });

  final JobWorkLoad load;
  final VoidCallback? onTap;
  final VoidCallback? onRecordOutput;
  final ValueChanged<JobWorkStatus>? onAdvanceStatus;
  final ValueChanged<JobWorkStatus>? onAdvanceCompletion;
  final VoidCallback? onRecordQc;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final dateLabel = DateFormat.yMMMd().format(load.receivedDate);
    final nextStatus = load.status.nextOperationalStatus;
    final nextCompletion = load.status.nextCompletionStatus;
    final canAdvance = onAdvanceStatus != null &&
        load.status.canAdvanceOperationally &&
        nextStatus != null;
    final canClose = onAdvanceCompletion != null &&
        nextCompletion == JobWorkStatus.closed;
    final canRecord = onRecordOutput != null && load.status.canRecordOutput;
    final hasOutput = load.output?.isRecorded == true;
    final canQc = onRecordQc != null && hasOutput;
    final hasActions = canAdvance || canClose || canRecord || canQc;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
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
                            if (load.marbleVariety.isNotEmpty)
                              load.marbleVariety,
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
              if (hasActions) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canRecord)
                      OutlinedButton.icon(
                        onPressed: isBusy ? null : onRecordOutput,
                        icon: Icon(
                          hasOutput ? Icons.edit_note : Icons.fact_check_outlined,
                          size: 16,
                        ),
                        label: Text(
                          hasOutput
                              ? AppStrings.editOutput
                              : AppStrings.recordOutput,
                        ),
                      ),
                    if (canAdvance)
                      OutlinedButton(
                        onPressed: isBusy
                            ? null
                            : () => onAdvanceStatus!(nextStatus),
                        child: Text(load.status.advanceActionLabel),
                      ),
                    if (canQc)
                      OutlinedButton.icon(
                        onPressed: isBusy ? null : onRecordQc,
                        icon: const Icon(Icons.verified_outlined, size: 16),
                        label: const Text(AppStrings.recordQcInspection),
                      ),
                    if (canClose)
                      OutlinedButton(
                        onPressed: isBusy
                            ? null
                            : () => onAdvanceCompletion!(nextCompletion!),
                        child: const Text(AppStrings.closeLoad),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
