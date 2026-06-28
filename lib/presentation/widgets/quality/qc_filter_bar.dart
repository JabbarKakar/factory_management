import 'package:flutter/material.dart';

import '../../../domain/enums/quality_enums.dart';

class QcFilterBar extends StatelessWidget {
  const QcFilterBar({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final QcListFilter selected;
  final ValueChanged<QcListFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: QcListFilter.values.map((filter) {
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

  IconData _iconFor(QcListFilter filter) {
    return switch (filter) {
      QcListFilter.all => Icons.inbox_rounded,
      QcListFilter.production => Icons.precision_manufacturing_outlined,
      QcListFilter.jobWork => Icons.content_cut_outlined,
      QcListFilter.pass => Icons.check_circle_outline,
      QcListFilter.rework => Icons.build_circle_outlined,
      QcListFilter.reject => Icons.cancel_outlined,
    };
  }
}
