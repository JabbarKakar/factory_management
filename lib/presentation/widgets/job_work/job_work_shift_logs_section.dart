import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/job_work_output.dart';
import 'job_work_detail_row.dart';
import 'job_work_detail_section.dart';
import 'stock_output_recording_panel.dart';

class JobWorkShiftLogsSection extends StatelessWidget {
  const JobWorkShiftLogsSection({
    required this.shiftLogs,
    super.key,
  });

  final List<JobWorkShiftLog> shiftLogs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return JobWorkDetailSection(
      title: AppStrings.shiftLogs,
      icon: Icons.schedule_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < shiftLogs.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.18),
              ),
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                title: Text(
                  _shiftTitle(shiftLogs[i]),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                subtitle: Text(
                  _shiftSubtitle(shiftLogs[i]),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                children: [
                  if (shiftLogs[i].hasStockOutputs)
                    StockOutputReadOnlyPanel(
                      smallOutputs: shiftLogs[i].smallStockOutputs,
                      largeOutputs: shiftLogs[i].largeStockOutputs,
                    )
                  else
                    JobWorkDetailRows(
                      rows: [
                        JobWorkDetailRow(
                          label: AppStrings.gradeA,
                          value: _sqFt(shiftLogs[i].gradeASqFt),
                        ),
                        JobWorkDetailRow(
                          label: AppStrings.gradeB,
                          value: _sqFt(shiftLogs[i].gradeBSqFt),
                        ),
                        JobWorkDetailRow(
                          label: AppStrings.gradeC,
                          value: _sqFt(shiftLogs[i].gradeCSqFt),
                        ),
                        JobWorkDetailRow(
                          label: AppStrings.reject,
                          value: _sqFt(shiftLogs[i].rejectSqFt),
                        ),
                        JobWorkDetailRow(
                          label: AppStrings.totalUsableOutput,
                          value: _sqFt(shiftLogs[i].totalUsableSqFt),
                          bold: true,
                          highlight: true,
                        ),
                      ],
                    ),
                  if (shiftLogs[i].notes != null &&
                      shiftLogs[i].notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    JobWorkDetailRows(
                      rows: [
                        JobWorkDetailRow(
                          label: AppStrings.shiftNotes,
                          value: shiftLogs[i].notes!,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _shiftTitle(JobWorkShiftLog shift) {
    return [
      DateFormat.yMMMd().format(shift.shiftDate),
      if (shift.shiftName != null && shift.shiftName!.isNotEmpty)
        shift.shiftName!,
    ].join(' · ');
  }

  String _shiftSubtitle(JobWorkShiftLog shift) {
    if (shift.hasStockOutputs) {
      return '${shift.totalPieces} pcs · '
          '${shift.totalUsableSqFt.toStringAsFixed(2)} sq. ft · '
          'Rs ${_formatAmount(shift.grandCuttingTotal)}';
    }
    return '${shift.totalUsableSqFt.toStringAsFixed(0)} sq. ft usable';
  }

  String _formatAmount(double value) {
    final rounded = value.round();
    if ((value - rounded).abs() < 0.01) {
      return rounded.toString();
    }
    return value.toStringAsFixed(2);
  }

  String _sqFt(double value) => '${value.toStringAsFixed(2)} sq. ft';
}
