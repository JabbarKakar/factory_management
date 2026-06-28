import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../dashboard/dashboard_surface.dart';

class ReportMonthNavigator extends StatelessWidget {
  const ReportMonthNavigator({
    required this.selectedMonth,
    required this.onPrevious,
    this.onNext,
    super.key,
  });

  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthLabel = DateFormat.yMMMM().format(selectedMonth);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: DashboardSurfaceCard(
        compact: true,
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded, size: 22),
              tooltip: AppStrings.previousMonth,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Text(
                monthLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded, size: 22),
              tooltip: AppStrings.nextMonth,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
