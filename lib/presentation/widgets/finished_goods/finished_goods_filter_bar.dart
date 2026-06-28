import 'package:flutter/material.dart';

import '../../../domain/enums/inventory_enums.dart';

class FinishedGoodsFilterBar extends StatelessWidget {
  const FinishedGoodsFilterBar({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final FinishedGoodsListFilter selected;
  final ValueChanged<FinishedGoodsListFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: FinishedGoodsListFilter.values.map((filter) {
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

  IconData _iconFor(FinishedGoodsListFilter filter) {
    return switch (filter) {
      FinishedGoodsListFilter.all => Icons.inbox_rounded,
      FinishedGoodsListFilter.inStock => Icons.layers_outlined,
      FinishedGoodsListFilter.lowStock => Icons.warning_amber_rounded,
    };
  }
}
