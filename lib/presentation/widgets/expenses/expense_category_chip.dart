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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
