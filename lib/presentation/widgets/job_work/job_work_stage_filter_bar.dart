import 'package:flutter/material.dart';

import '../../../domain/enums/job_work_enums.dart';

class JobWorkStageFilterBar extends StatelessWidget {
  const JobWorkStageFilterBar({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final JobWorkListStageFilter selected;
  final ValueChanged<JobWorkListStageFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: JobWorkListStageFilter.values.map((filter) {
          final isSelected = selected == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(
                filter.label,
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              avatar: Icon(
                _iconFor(filter),
                size: isCompact ? 14 : 15,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              selected: isSelected,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 4 : 6,
                vertical: 0,
              ),
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.45)
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              onSelected: (_) => onChanged(filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconFor(JobWorkListStageFilter filter) {
    return switch (filter) {
      JobWorkListStageFilter.all => Icons.inbox_rounded,
      JobWorkListStageFilter.inProgress => Icons.pending_outlined,
      JobWorkListStageFilter.atQc => Icons.fact_check_outlined,
      JobWorkListStageFilter.ready => Icons.check_circle_outline_rounded,
      JobWorkListStageFilter.invoiced => Icons.receipt_long_outlined,
      JobWorkListStageFilter.paid => Icons.payments_outlined,
      JobWorkListStageFilter.pendingPickup => Icons.local_shipping_outlined,
      JobWorkListStageFilter.completed => Icons.done_all_rounded,
      JobWorkListStageFilter.cancelled => Icons.cancel_outlined,
    };
  }
}
