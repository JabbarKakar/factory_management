import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/job_work_order.dart';
import '../../../domain/entities/job_work_output.dart';
import '../../../domain/entities/stock_output.dart';
import 'job_work_detail_row.dart';
import 'job_work_detail_section.dart';

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
    final rows = <JobWorkDetailRow>[
      if (output.hasStockOutputs) ...[
        ..._stockRows(output.smallStockOutputs, AppStrings.smallSizes),
        ..._stockRows(output.largeStockOutputs, AppStrings.largeSizes),
        JobWorkDetailRow(
          label: AppStrings.totalPieces,
          value: output.totalPieces.toString(),
        ),
      ] else ...[
        JobWorkDetailRow(label: AppStrings.gradeA, value: _sqFt(output.gradeASqFt)),
        JobWorkDetailRow(label: AppStrings.gradeB, value: _sqFt(output.gradeBSqFt)),
        JobWorkDetailRow(label: AppStrings.gradeC, value: _sqFt(output.gradeCSqFt)),
        JobWorkDetailRow(label: AppStrings.reject, value: _sqFt(output.rejectSqFt)),
      ],
      JobWorkDetailRow(
        label: AppStrings.totalUsableOutput,
        value: _sqFt(output.totalUsableSqFt),
        bold: true,
        highlight: true,
      ),
      if (output.hasStockOutputs)
        JobWorkDetailRow(
          label: AppStrings.grandCuttingTotal,
          value: Formatters.currencyPkr(output.grandCuttingTotal),
          bold: true,
          highlight: true,
        ),
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
      if (order.hasFinalCuttingCharges)
        JobWorkDetailRow(
          label: AppStrings.finalCuttingCharges,
          value: Formatters.currencyPkr(order.finalCuttingCharges),
          bold: true,
          highlight: true,
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

    return JobWorkDetailSection(
      title: AppStrings.outputRecording,
      icon: Icons.analytics_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JobWorkDetailRows(rows: rows),
          if (order.shiftLogs.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Divider(
                height: 1,
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.22),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(
                AppStrings.shiftLogs,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
              ),
            ),
            JobWorkDetailRows(
              rows: order.shiftLogs
                  .map(
                    (shift) => JobWorkDetailRow(
                      label: [
                        DateFormat.yMMMd().format(shift.shiftDate),
                        if (shift.shiftName != null) shift.shiftName!,
                      ].join(' · '),
                      value: shift.hasStockOutputs
                          ? '${shift.totalPieces} pcs · '
                              '${shift.totalUsableSqFt.toStringAsFixed(2)} sq. ft'
                          : '${shift.totalUsableSqFt.toStringAsFixed(0)} sq. ft usable',
                    ),
                  )
                  .toList(),
            ),
          ],
          _ExecutionSummary(execution: order.execution),
        ],
      ),
    );
  }

  List<JobWorkDetailRow> _stockRows(
    List<StockOutput> outputs,
    String sectionLabel,
  ) {
    final active =
        outputs.where((output) => output.hasProduction).toList(growable: false);
    if (active.isEmpty) return const [];

    return [
      JobWorkDetailRow(label: sectionLabel, value: '', bold: true),
      ...active.map(
        (stock) => JobWorkDetailRow(
          label: stock.size,
          value:
              '${stock.pieces} pcs · ${stock.squareFeet.toStringAsFixed(2)} sq. ft · '
              '${Formatters.currencyPkr(stock.amount)}',
        ),
      ),
    ];
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.22),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(
            AppStrings.cuttingExecution,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
          ),
        ),
        JobWorkDetailRows(rows: rows),
        const SizedBox(height: 4),
      ],
    );
  }
}
