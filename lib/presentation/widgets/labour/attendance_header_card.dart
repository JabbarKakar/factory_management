import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/labour_enums.dart';
import '../../widgets/forms/app_form_fields.dart';
import 'attendance_summary_strip.dart';

class AttendanceHeaderCard extends StatelessWidget {
  const AttendanceHeaderCard({
    required this.selectedDate,
    required this.defaultShift,
    required this.presentCount,
    required this.absentCount,
    required this.unmarkedCount,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onPickDate,
    required this.onShiftChanged,
    required this.onMarkAllPresent,
    required this.canMarkAllPresent,
    this.isSaving = false,
    super.key,
  });

  final DateTime selectedDate;
  final AttendanceShift defaultShift;
  final int presentCount;
  final int absentCount;
  final int unmarkedCount;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onPickDate;
  final ValueChanged<AttendanceShift> onShiftChanged;
  final VoidCallback onMarkAllPresent;
  final bool canMarkAllPresent;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    const accent = AppColors.primary;
    const cardShape = BorderRadius.only(
      topRight: Radius.circular(14),
      bottomRight: Radius.circular(14),
    );
    final dateLabel = DateFormat.yMMMEd().format(selectedDate);
    final canGoNext = !selectedDate
        .add(const Duration(days: 1))
        .isAfter(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: cardShape,
          border: Border.all(color: outline),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ColoredBox(color: accent, child: SizedBox(width: 3)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: isSaving ? null : onPreviousDay,
                            icon: const Icon(Icons.chevron_left_rounded),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: isSaving ? null : onPickDate,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      AppStrings.attendanceDate,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateLabel,
                                      textAlign: TextAlign.center,
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed:
                                isSaving || !canGoNext ? null : onNextDay,
                            icon: const Icon(Icons.chevron_right_rounded),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AttendanceShift>(
                        key: ValueKey(defaultShift),
                        initialValue: defaultShift,
                        isExpanded: true,
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.defaultShift,
                        ),
                        style: AppFormFields.valueStyle(context),
                        items: AttendanceShift.values
                            .map(
                              (shift) => DropdownMenuItem(
                                value: shift,
                                child: Text(shift.label),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (shift) {
                                if (shift != null) onShiftChanged(shift);
                              },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppStrings.attendanceSummary,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AttendanceSummaryStrip(
                        presentCount: presentCount,
                        absentCount: absentCount,
                        unmarkedCount: unmarkedCount,
                      ),
                      if (canMarkAllPresent) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isSaving ? null : onMarkAllPresent,
                            icon: const Icon(Icons.done_all_outlined, size: 16),
                            label: Text(
                              AppStrings.markAllPresent,
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
