import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/expense_enums.dart';

class ExpensePeriodTabBar extends StatelessWidget {
  const ExpensePeriodTabBar({
    required this.controller,
    super.key,
  });

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.3 : 0.35);
    const accent = AppColors.warning;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: isDark ? 0.35 : 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: outline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: TabBar(
          controller: controller,
          dividerHeight: 0,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
          ),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          labelColor: accent,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.1,
          ),
          tabs: ExpenseListPeriodFilter.values
              .map(
                (period) => Tab(
                  height: 38,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        period == ExpenseListPeriodFilter.thisMonth
                            ? Icons.calendar_month_outlined
                            : Icons.all_inclusive_rounded,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(period.label),
                    ],
                  ),
                ),
              )
              .toList(),
          ),
        ),
      ),
    );
  }
}
