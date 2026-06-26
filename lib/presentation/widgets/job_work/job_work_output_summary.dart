import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/job_work_order.dart';
import '../../../domain/entities/job_work_output.dart';
import '../settings_section.dart';

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
      return Card(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.outputNotRecordedYet,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final wastePct = output.wastePercent(order.totalTons);
    final yieldPct = output.yieldPercent(order.expectedOutputSqFt);

    return SettingsSection(
      title: AppStrings.outputRecording,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Row(AppStrings.gradeA, _sqFt(output.gradeASqFt)),
            const SizedBox(height: 8),
            _Row(AppStrings.gradeB, _sqFt(output.gradeBSqFt)),
            const SizedBox(height: 8),
            _Row(AppStrings.gradeC, _sqFt(output.gradeCSqFt)),
            const SizedBox(height: 8),
            _Row(AppStrings.reject, _sqFt(output.rejectSqFt)),
            const Divider(height: 24),
            _Row(
              AppStrings.totalUsableOutput,
              _sqFt(output.totalUsableSqFt),
              bold: true,
            ),
            if (output.wasteAmount > 0) ...[
              const SizedBox(height: 8),
              _Row(
                AppStrings.wasteGenerated,
                '${output.wasteAmount.toStringAsFixed(2)} ${output.wasteUnit.label}',
              ),
              const SizedBox(height: 8),
              _Row(
                AppStrings.wasteDisposition,
                output.wasteDisposition.label,
              ),
            ],
            if (wastePct > 0) ...[
              const SizedBox(height: 8),
              _Row(AppStrings.wastePercent, '${wastePct.toStringAsFixed(1)}%'),
            ],
            if (yieldPct > 0) ...[
              const SizedBox(height: 8),
              _Row(AppStrings.yieldPercent, '${yieldPct.toStringAsFixed(1)}%'),
            ],
            if (output.slurryDust != null && output.slurryDust!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _Row(AppStrings.slurryDust, output.slurryDust!),
            ],
            if (output.recordedAt != null) ...[
              const SizedBox(height: 8),
              _Row(
                'Recorded',
                DateFormat.yMMMd().add_jm().format(output.recordedAt!),
              ),
            ],
            if (order.shiftLogs.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                AppStrings.shiftLogs,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...order.shiftLogs.map(
                (shift) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _Row(
                    [
                      DateFormat.yMMMd().format(shift.shiftDate),
                      if (shift.shiftName != null) shift.shiftName!,
                    ].join(' · '),
                    '${shift.totalUsableSqFt.toStringAsFixed(0)} sq. ft usable',
                  ),
                ),
              ),
            ],
            _ExecutionSummary(execution: order.execution),
          ],
        ),
      ),
    );
  }

  String _sqFt(double value) => '${value.toStringAsFixed(0)} sq. ft';
}

class _ExecutionSummary extends StatelessWidget {
  const _ExecutionSummary({this.execution});

  final JobWorkExecution? execution;

  @override
  Widget build(BuildContext context) {
    if (execution == null || !execution!.hasData) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 24),
        Text(
          AppStrings.cuttingExecution,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        if (execution!.cuttingStartDate != null)
          _Row(
            AppStrings.cuttingStartDate,
            DateFormat.yMMMd().format(execution!.cuttingStartDate!),
          ),
        if (execution!.cuttingCompletionDate != null) ...[
          const SizedBox(height: 8),
          _Row(
            AppStrings.cuttingCompletionDate,
            DateFormat.yMMMd().format(execution!.cuttingCompletionDate!),
          ),
        ],
        if (execution!.supervisorName != null &&
            execution!.supervisorName!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          _Row(AppStrings.supervisorName, execution!.supervisorName!),
        ],
        if (execution!.progressNotes != null &&
            execution!.progressNotes!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          _Row(AppStrings.progressNotes, execution!.progressNotes!),
        ],
      ],
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
