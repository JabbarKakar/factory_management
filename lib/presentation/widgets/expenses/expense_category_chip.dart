import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/expense_enums.dart';

class ExpenseCategoryChip extends StatelessWidget {
  const ExpenseCategoryChip({
    required this.category,
    this.compact = false,
    super.key,
  });

  final ExpenseCategory category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foreground = isDark
        ? AppColors.warning.withValues(alpha: 0.95)
        : AppColors.warning;
    final background = foreground.withValues(alpha: isDark ? 0.18 : 0.1);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconFor(category),
              size: 10,
              color: foreground,
            ),
            const SizedBox(width: 3),
            Text(
              category.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
                fontSize: 9,
                height: 1.1,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: foreground.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(category), size: 13, color: foreground),
          const SizedBox(width: 5),
          Text(
            category.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 11,
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
