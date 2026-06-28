import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/customer_enums.dart';

class CustomerServiceTypeFilterBar extends StatelessWidget {
  const CustomerServiceTypeFilterBar({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final CustomerServiceType? selected;
  final ValueChanged<CustomerServiceType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: AppStrings.all,
            icon: Icons.inbox_rounded,
            isSelected: selected == null,
            isCompact: isCompact,
            onSelected: () => onChanged(null),
          ),
          ...CustomerServiceType.values.map(
            (type) => _FilterChip(
              label: type.label,
              icon: _iconFor(type),
              isSelected: selected == type,
              isCompact: isCompact,
              onSelected: () => onChanged(type),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(CustomerServiceType type) {
    return switch (type) {
      CustomerServiceType.buyer => Icons.shopping_bag_outlined,
      CustomerServiceType.jobWork => Icons.content_cut_outlined,
      CustomerServiceType.both => Icons.swap_horiz_rounded,
      CustomerServiceType.other => Icons.more_horiz_rounded,
    };
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isCompact,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 11 : 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        avatar: Icon(
          icon,
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
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
