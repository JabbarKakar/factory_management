import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../job_work/job_work_detail_section.dart';

class SupplierStatementDateRangeSection extends StatelessWidget {
  const SupplierStatementDateRangeSection({
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
        child: Row(
          children: [
            Expanded(
              child: _DateButton(
                label: AppStrings.fromDate,
                dateText: dateFormat.format(fromDate),
                onTap: enabled ? onPickFrom : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateButton(
                label: AppStrings.toDate,
                dateText: dateFormat.format(toDate),
                onTap: enabled ? onPickTo : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.dateText,
    required this.onTap,
  });

  final String label;
  final String dateText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: outline),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    dateText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
