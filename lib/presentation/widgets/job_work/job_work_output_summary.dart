import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/job_work_order.dart';
import '../../../domain/entities/job_work_output.dart';
import 'job_work_detail_row.dart';
import 'job_work_detail_section.dart';
import 'job_work_shift_logs_section.dart';
import 'stock_output_recording_panel.dart';

class JobWorkOutputSummary extends StatelessWidget {
  const JobWorkOutputSummary({
    required this.order,
    super.key,
  });

  final JobWorkOrder order;

  @override
  Widget build(BuildContext context) {
    final output = order.output;
    if (output == null || !output.isRecorded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.25),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.25),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppStrings.outputNotRecordedYet,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          height: 1.35,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final wastePct = output.wastePercent(order.totalTons);
    final metaRows = <JobWorkDetailRow>[
      if (output.wasteAmount > 0) ...[
        JobWorkDetailRow(
          label: AppStrings.wasteGenerated,
          value:
              '${output.wasteAmount.toStringAsFixed(2)} ${output.wasteUnit.label}',
        ),
        JobWorkDetailRow(
          label: AppStrings.wasteDisposition,
          value: output.wasteDisposition.label,
        ),
      ],
      if (wastePct > 0)
        JobWorkDetailRow(
          label: AppStrings.wastePercent,
          value: '${wastePct.toStringAsFixed(1)}%',
        ),
      if (output.slurryDust != null && output.slurryDust!.isNotEmpty)
        JobWorkDetailRow(
          label: AppStrings.slurryDust,
          value: output.slurryDust!,
        ),
      if (output.recordedAt != null)
        JobWorkDetailRow(
          label: 'Recorded',
          value: DateFormat.yMMMd().add_jm().format(output.recordedAt!),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        JobWorkDetailSection(
          title: AppStrings.outputRecording,
          icon: Icons.analytics_outlined,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (output.hasStockOutputs)
                  StockOutputReadOnlyPanel(
                    smallOutputs: output.smallStockOutputs,
                    largeOutputs: output.largeStockOutputs,
                  )
                else
                  JobWorkDetailRows(
                    rows: [
                      JobWorkDetailRow(
                        label: AppStrings.gradeA,
                        value: _sqFt(output.gradeASqFt),
                      ),
                      JobWorkDetailRow(
                        label: AppStrings.gradeB,
                        value: _sqFt(output.gradeBSqFt),
                      ),
                      JobWorkDetailRow(
                        label: AppStrings.gradeC,
                        value: _sqFt(output.gradeCSqFt),
                      ),
                      JobWorkDetailRow(
                        label: AppStrings.reject,
                        value: _sqFt(output.rejectSqFt),
                      ),
                      JobWorkDetailRow(
                        label: AppStrings.totalUsableOutput,
                        value: _sqFt(output.totalUsableSqFt),
                        bold: true,
                        highlight: true,
                      ),
                    ],
                  ),
                if (metaRows.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Divider(
                      height: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.22),
                    ),
                  ),
                  const SizedBox(height: 4),
                  JobWorkDetailRows(rows: metaRows),
                ],
                _ExecutionSummary(execution: order.execution),
              ],
            ),
          ),
        ),
        if (order.shiftLogs.isNotEmpty)
          JobWorkShiftLogsSection(shiftLogs: order.shiftLogs),
      ],
    );
  }

  String _sqFt(double value) => '${value.toStringAsFixed(2)} sq. ft';
}

class _ExecutionSummary extends StatelessWidget {
  const _ExecutionSummary({this.execution});

  final JobWorkExecution? execution;

  @override
  Widget build(BuildContext context) {
    if (execution == null || !execution!.hasData) return const SizedBox.shrink();

    final rows = <JobWorkDetailRow>[
      if (execution!.cuttingStartDate != null)
        JobWorkDetailRow(
          label: AppStrings.cuttingStartDate,
          value: DateFormat.yMMMd().format(execution!.cuttingStartDate!),
        ),
      if (execution!.cuttingCompletionDate != null)
        JobWorkDetailRow(
          label: AppStrings.cuttingCompletionDate,
          value: DateFormat.yMMMd().format(execution!.cuttingCompletionDate!),
        ),
      if (execution!.supervisorName != null &&
          execution!.supervisorName!.trim().isNotEmpty)
        JobWorkDetailRow(
          label: AppStrings.supervisorName,
          value: execution!.supervisorName!,
        ),
      if (execution!.progressNotes != null &&
          execution!.progressNotes!.trim().isNotEmpty)
        JobWorkDetailRow(
          label: AppStrings.progressNotes,
          value: execution!.progressNotes!,
        ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.22),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
          child: Text(
            AppStrings.cuttingExecution,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
          ),
        ),
        JobWorkDetailRows(rows: rows),
      ],
    );
  }
}
