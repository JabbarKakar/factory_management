import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/expense_enums.dart';

class ExpenseCategoryFilterBar extends StatelessWidget {
  const ExpenseCategoryFilterBar({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final ExpenseCategory? selected;
  final ValueChanged<ExpenseCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: AppStrings.allCategories,
            icon: Icons.inbox_rounded,
            isSelected: selected == null,
            isCompact: isCompact,
            onSelected: () => onChanged(null),
          ),
          ...ExpenseCategory.values.map(
            (category) => _FilterChip(
              label: category.label,
              icon: _iconFor(category),
              isSelected: selected == category,
              isCompact: isCompact,
              onSelected: () => onChanged(category),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(ExpenseCategory category) {
    return switch (category) {
      ExpenseCategory.rawMaterialPurchase => Icons.inventory_2_outlined,
      ExpenseCategory.labourWages => Icons.groups_outlined,
      ExpenseCategory.electricity => Icons.bolt_outlined,
      ExpenseCategory.waterSewage => Icons.water_drop_outlined,
      ExpenseCategory.fuel => Icons.local_gas_station_outlined,
      ExpenseCategory.machineMaintenance => Icons.build_circle_outlined,
      ExpenseCategory.spareParts => Icons.settings_outlined,
      ExpenseCategory.transportInward ||
      ExpenseCategory.transportOutward =>
        Icons.local_shipping_outlined,
      ExpenseCategory.rent => Icons.home_work_outlined,
      ExpenseCategory.officeSupplies => Icons.edit_note_outlined,
      ExpenseCategory.communication => Icons.phone_outlined,
      ExpenseCategory.bankCharges => Icons.account_balance_outlined,
      ExpenseCategory.depreciation => Icons.trending_down_rounded,
      ExpenseCategory.insurance => Icons.shield_outlined,
      ExpenseCategory.marketing => Icons.campaign_outlined,
      ExpenseCategory.professionalFees => Icons.gavel_outlined,
      ExpenseCategory.miscellaneous => Icons.more_horiz_rounded,
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
