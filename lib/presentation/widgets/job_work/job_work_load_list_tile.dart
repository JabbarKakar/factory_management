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
    this.onCollectMaterial,
    this.isBusy = false,
    super.key,
  });

  final JobWorkLoad load;
  final VoidCallback? onTap;
  final VoidCallback? onRecordOutput;
  final ValueChanged<JobWorkStatus>? onAdvanceStatus;
  final ValueChanged<JobWorkStatus>? onAdvanceCompletion;
  final VoidCallback? onRecordQc;
  final VoidCallback? onCollectMaterial;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final dateLabel = DateFormat.yMMMd().format(load.receivedDate);
    final nextStatus = load.status.nextOperationalStatus;
    final nextCompletion = load.status.nextCompletionStatus;
    final hasOutput = load.output?.isRecorded == true;
    final canAdvance = onAdvanceStatus != null &&
        (load.status.canAdvanceOperationally ||
            load.status == JobWorkStatus.received) &&
        nextStatus != null &&
        // Send to QC only after output is recorded.
        (nextStatus != JobWorkStatus.qc || hasOutput);
    final canClose = onAdvanceCompletion != null &&
        nextCompletion == JobWorkStatus.closed;
    // Match Load detail: Start Cutting before first Record Output.
    final canRecord = onRecordOutput != null &&
        load.status.canRecordOutput &&
        (hasOutput || load.status != JobWorkStatus.agreed);
    final canQc = onRecordQc != null && hasOutput;
    final canCollect = onCollectMaterial != null;
    final hasActions =
        canAdvance || canClose || canRecord || canQc || canCollect;


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
                    if (canAdvance)
                      FilledButton(
                        onPressed: isBusy
                            ? null
                            : () => onAdvanceStatus!(nextStatus),
                        child: Text(load.status.advanceActionLabel),
                      ),
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
                    if (canQc)
                      OutlinedButton.icon(
                        onPressed: isBusy ? null : onRecordQc,
                        icon: const Icon(Icons.verified_outlined, size: 16),
                        label: const Text(AppStrings.recordQcInspection),
                      ),
                    if (canCollect)
                      OutlinedButton.icon(
                        onPressed: isBusy ? null : onCollectMaterial,
                        icon: const Icon(Icons.handshake_outlined, size: 16),
                        label: const Text(AppStrings.collectMaterial),
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
