import 'package:flutter/material.dart';

import '../../../domain/enums/expense_enums.dart';

class ExpensePeriodFilterBar extends StatelessWidget {
  const ExpensePeriodFilterBar({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final ExpenseListPeriodFilter selected;
  final ValueChanged<ExpenseListPeriodFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return Row(
      children: ExpenseListPeriodFilter.values.map((period) {
        final isSelected = selected == period;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: FilterChip(
            label: Text(
              period.label,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            avatar: Icon(
              period == ExpenseListPeriodFilter.thisMonth
                  ? Icons.calendar_month_outlined
                  : Icons.all_inclusive_rounded,
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
            onSelected: (_) => onChanged(period),
          ),
        );
      }).toList(),
    );
  }
}
