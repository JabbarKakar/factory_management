import 'package:flutter/material.dart';

import '../../../domain/enums/delivery_enums.dart';

class DeliveryStageFilterBar extends StatelessWidget {
  const DeliveryStageFilterBar({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final DeliveryListFilter selected;
  final ValueChanged<DeliveryListFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DeliveryListFilter.values.map((filter) {
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

  IconData _iconFor(DeliveryListFilter filter) {
    return switch (filter) {
      DeliveryListFilter.all => Icons.inbox_rounded,
      DeliveryListFilter.active => Icons.pending_outlined,
      DeliveryListFilter.scheduled => Icons.event_outlined,
      DeliveryListFilter.inTransit => Icons.local_shipping_outlined,
      DeliveryListFilter.delivered => Icons.check_circle_outline_rounded,
      DeliveryListFilter.failed => Icons.error_outline_rounded,
    };
  }
}
