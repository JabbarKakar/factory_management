import 'package:flutter/material.dart';

import '../../../blocs/labour/daily_attendance_bloc.dart';
import '../../../domain/enums/labour_enums.dart';
import 'attendance_status_selector.dart';

class AttendanceEntryTile extends StatelessWidget {
  const AttendanceEntryTile({
    required this.entry,
    required this.onStatusChanged,
    this.enabled = true,
    super.key,
  });

  final DailyAttendanceEntry entry;
  final ValueChanged<AttendanceStatus> onStatusChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    final accent = attendanceStatusAccent(entry.status);
    const cardShape = BorderRadius.only(
      topRight: Radius.circular(14),
      bottomRight: Radius.circular(14),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: cardShape,
            border: Border.all(color: outline),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.employee.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            Text(
                              entry.employee.employeeNumber,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.employee.workerCategory.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                            fontSize: 11,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AttendanceStatusSelector(
                          value: entry.status,
                          enabled: enabled,
                          onChanged: onStatusChanged,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
