import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/job_work_block_progress.dart';
import '../../../domain/entities/job_work_output.dart';
import 'job_work_detail_row.dart';
import 'job_work_detail_section.dart';

class JobWorkBlockProgressSection extends StatelessWidget {
  const JobWorkBlockProgressSection({
    required this.blockCount,
    required this.shiftLogs,
    super.key,
  });

  final int blockCount;
  final List<JobWorkShiftLog> shiftLogs;

  @override
  Widget build(BuildContext context) {
    final totalBlocks = blockCount;
    final blocksCut = JobWorkBlockProgress.totalBlocksCut(shiftLogs);
    final remaining = JobWorkBlockProgress.remainingBlocks(
      totalBlocks: blockCount,
      shifts: shiftLogs,
    );
    final percent = JobWorkBlockProgress.completionPercent(
      totalBlocks: blockCount,
      blocksCut: blocksCut,
    );

    return JobWorkDetailSection(
      title: AppStrings.blockCuttingProgress,
      icon: Icons.view_module_outlined,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            JobWorkDetailRows(
              rows: [
                JobWorkDetailRow(
                  label: AppStrings.totalBlocks,
                  value: '$totalBlocks',
                ),
                JobWorkDetailRow(
                  label: AppStrings.blocksCut,
                  value: '$blocksCut',
                  bold: true,
                ),
                JobWorkDetailRow(
                  label: AppStrings.remainingBlocks,
                  value: '$remaining',
                  highlight: remaining > 0,
                ),
              ],
            ),
            if (totalBlocks > 0) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        minHeight: 8,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$blocksCut / $totalBlocks ${AppStrings.blocksCutLabel} · '
                      '${percent.toStringAsFixed(0)}% ${AppStrings.completed}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
