import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../../domain/enums/labour_enums.dart';
import '../job_work/job_work_detail_section.dart';

class EmployeeAttendanceHistorySection extends StatelessWidget {
  const EmployeeAttendanceHistorySection({
    required this.records,
    super.key,
  });

  final List<AttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    return JobWorkDetailSection(
      title: AppStrings.attendanceHistory,
      icon: Icons.event_available_outlined,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: records.isEmpty
            ? Text(
                AppStrings.noAttendanceHistory,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      height: 1.35,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            : Column(
                children: [
                  for (var i = 0; i < records.length; i++) ...[
                    _AttendanceHistoryRow(record: records[i]),
                    if (i < records.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
      ),
    );
  }
}

class _AttendanceHistoryRow extends StatelessWidget {
  const _AttendanceHistoryRow({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final color = _colorFor(record.status);
    final dateLabel = DateFormat.yMMMd().format(record.attendanceDate);
    final subtitleParts = <String>[
      record.status.label,
      if (record.shift != null) record.shift!.label,
      if (record.notes != null && record.notes!.isNotEmpty) record.notes!,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconFor(record.status), size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleParts.join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: muted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(AttendanceStatus status) {
    return switch (status) {
      AttendanceStatus.present => AppColors.success,
      AttendanceStatus.absent => AppColors.error,
      AttendanceStatus.halfDay => AppColors.warning,
      AttendanceStatus.leave => AppColors.primary,
      AttendanceStatus.holiday => AppColors.textSecondary,
    };
  }

  IconData _iconFor(AttendanceStatus status) {
    return switch (status) {
      AttendanceStatus.present => Icons.check_circle_outline,
      AttendanceStatus.absent => Icons.cancel_outlined,
      AttendanceStatus.halfDay => Icons.timelapse_outlined,
      AttendanceStatus.leave => Icons.beach_access_outlined,
      AttendanceStatus.holiday => Icons.celebration_outlined,
    };
  }
}
