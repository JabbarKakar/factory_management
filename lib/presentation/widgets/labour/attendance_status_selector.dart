import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/labour_enums.dart';

Color attendanceStatusAccent(AttendanceStatus? status) {
  if (status == null) return AppColors.primary.withValues(alpha: 0.45);

  return switch (status) {
    AttendanceStatus.present => AppColors.success,
    AttendanceStatus.absent => AppColors.error,
    AttendanceStatus.halfDay => AppColors.warning,
    AttendanceStatus.leave => AppColors.primary,
    AttendanceStatus.holiday => AppColors.textSecondary,
  };
}

Color attendanceStatusColor(AttendanceStatus status) =>
    attendanceStatusAccent(status);

class AttendanceStatusSelector extends StatelessWidget {
  const AttendanceStatusSelector({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final AttendanceStatus? value;
  final ValueChanged<AttendanceStatus>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.4);
    final muted = theme.colorScheme.onSurfaceVariant;

    return DropdownButtonFormField<AttendanceStatus>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        labelText: null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true,
        fillColor: isDark
            ? theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.35)
            : theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.55),
          ),
        ),
      ),
      hint: Text(
        '—',
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: muted,
        ),
      ),
      style: theme.textTheme.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      items: AttendanceStatus.values
          .map(
            (status) => DropdownMenuItem(
              value: status,
              child: Text(
                status.label,
                style: TextStyle(
                  color: attendanceStatusColor(status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: enabled
          ? (status) {
              if (status != null) onChanged?.call(status);
            }
          : null,
    );
  }
}
