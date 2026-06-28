import 'package:flutter/material.dart';

import '../../../domain/enums/sales_enums.dart';

class SalesOrderStageFilterBar extends StatelessWidget {
  const SalesOrderStageFilterBar({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final SalesListFilter selected;
  final ValueChanged<SalesListFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: SalesListFilter.values.map((filter) {
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

  IconData _iconFor(SalesListFilter filter) {
    return switch (filter) {
      SalesListFilter.all => Icons.inbox_rounded,
      SalesListFilter.inProgress => Icons.pending_outlined,
      SalesListFilter.received => Icons.move_to_inbox_outlined,
      SalesListFilter.ready => Icons.check_circle_outline_rounded,
      SalesListFilter.invoiced => Icons.receipt_long_outlined,
      SalesListFilter.paid => Icons.payments_outlined,
      SalesListFilter.closed => Icons.done_all_rounded,
      SalesListFilter.cancelled => Icons.cancel_outlined,
    };
  }
}
