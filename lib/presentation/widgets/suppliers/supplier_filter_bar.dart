import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/supplier_enums.dart';

class SupplierFilterBar extends StatelessWidget {
  const SupplierFilterBar({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final SupplierType? selected;
  final ValueChanged<SupplierType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(
            context,
            theme: theme,
            isCompact: isCompact,
            label: AppStrings.all,
            icon: Icons.inbox_rounded,
            isSelected: selected == null,
            onSelected: () => onChanged(null),
          ),
          ...SupplierType.values.map(
            (type) => _buildChip(
              context,
              theme: theme,
              isCompact: isCompact,
              label: type.label,
              icon: _iconFor(type),
              isSelected: selected == type,
              onSelected: () => onChanged(type),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required ThemeData theme,
    required bool isCompact,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
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

  IconData _iconFor(SupplierType type) {
    return switch (type) {
      SupplierType.marbleBlockSlab => Icons.layers_outlined,
      SupplierType.consumables => Icons.shopping_bag_outlined,
      SupplierType.chemical => Icons.science_outlined,
      SupplierType.machinery => Icons.precision_manufacturing_outlined,
      SupplierType.spareParts => Icons.build_outlined,
      SupplierType.transportLogistics => Icons.local_shipping_outlined,
      SupplierType.utility => Icons.bolt_outlined,
      SupplierType.other => Icons.category_outlined,
    };
  }
}
