import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../job_work/job_work_detail_section.dart';

class CustomerStatementDateRangeSection extends StatelessWidget {
  const CustomerStatementDateRangeSection({
    required this.fromDate,
    required this.toDate,
    required this.onPickFrom,
    required this.onPickTo,
    this.enabled = true,
    super.key,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return JobWorkDetailSection(
      title: AppStrings.statementDateRange,
      icon: Icons.date_range_outlined,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          children: [
            _DatePickerRow(
              label: AppStrings.fromDate,
              value: dateFormat.format(fromDate),
              onTap: enabled ? onPickFrom : null,
            ),
            const SizedBox(height: 8),
            _DatePickerRow(
              label: AppStrings.toDate,
              value: dateFormat.format(toDate),
              onTap: enabled ? onPickTo : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final enabled = onTap != null;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.35 : 0.55,
      ),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: enabled ? null : muted,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: enabled ? theme.colorScheme.primary : muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
