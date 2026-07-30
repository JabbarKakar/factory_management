import 'package:equatable/equatable.dart';

import '../enums/dashboard_finance_period.dart';
import 'dashboard_kpis.dart';

/// Income / expense totals for the selected dashboard finance period.
class DashboardCashflowMetrics extends Equatable {
  const DashboardCashflowMetrics({
    required this.period,
    required this.income,
    required this.expenses,
    required this.previousIncome,
    required this.previousExpenses,
  });

  static const empty = DashboardCashflowMetrics(
    period: DashboardFinancePeriod.daily,
    income: 0,
    expenses: 0,
    previousIncome: 0,
    previousExpenses: 0,
  );

  final DashboardFinancePeriod period;
  final double income;
  final double expenses;
  final double previousIncome;
  final double previousExpenses;

  double get net => income - expenses;

  double? get incomeChangePercent =>
      DashboardKpis.dayOverDayPercent(income, previousIncome);

  double? get expensesChangePercent =>
      DashboardKpis.dayOverDayPercent(expenses, previousExpenses);

  double? get expensesToIncomePercent =>
      income > 0 ? (expenses / income) * 100 : null;

  @override
  List<Object?> get props => [
        period,
        income,
        expenses,
        previousIncome,
        previousExpenses,
      ];
}

/// Inclusive calendar-day windows for current vs previous period.
class DashboardFinancePeriodRange {
  const DashboardFinancePeriodRange({
    required this.currentStart,
    required this.currentEnd,
    required this.previousStart,
    required this.previousEnd,
  });

  final DateTime currentStart;
  final DateTime currentEnd;
  final DateTime previousStart;
  final DateTime previousEnd;

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool contains(DateTime date, DateTime start, DateTime end) {
    final day = dateOnly(date);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  static DateTime _clampDay(int year, int month, int day) {
    final maxDay = _daysInMonth(year, month);
    return DateTime(year, month, day.clamp(1, maxDay));
  }

  /// Builds current/previous ranges for [period] relative to [now].
  static DashboardFinancePeriodRange forPeriod(
    DashboardFinancePeriod period,
    DateTime now,
  ) {
    final today = dateOnly(now);

    switch (period) {
      case DashboardFinancePeriod.daily:
        final yesterday = today.subtract(const Duration(days: 1));
        return DashboardFinancePeriodRange(
          currentStart: today,
          currentEnd: today,
          previousStart: yesterday,
          previousEnd: yesterday,
        );

      case DashboardFinancePeriod.weekly:
        final weekStart =
            today.subtract(Duration(days: today.weekday - DateTime.monday));
        final elapsed = today.difference(weekStart).inDays;
        final prevWeekStart = weekStart.subtract(const Duration(days: 7));
        final prevWeekEnd = prevWeekStart.add(Duration(days: elapsed));
        return DashboardFinancePeriodRange(
          currentStart: weekStart,
          currentEnd: today,
          previousStart: prevWeekStart,
          previousEnd: prevWeekEnd,
        );

      case DashboardFinancePeriod.monthly:
        final monthStart = DateTime(today.year, today.month, 1);
        final prevMonthYear =
            today.month == 1 ? today.year - 1 : today.year;
        final prevMonth = today.month == 1 ? 12 : today.month - 1;
        final prevMonthStart = DateTime(prevMonthYear, prevMonth, 1);
        final prevMonthEnd =
            _clampDay(prevMonthYear, prevMonth, today.day);
        return DashboardFinancePeriodRange(
          currentStart: monthStart,
          currentEnd: today,
          previousStart: prevMonthStart,
          previousEnd: prevMonthEnd,
        );

      case DashboardFinancePeriod.sixMonths:
        final currentStart = today.subtract(const Duration(days: 179));
        final previousEnd = currentStart.subtract(const Duration(days: 1));
        final previousStart = previousEnd.subtract(const Duration(days: 179));
        return DashboardFinancePeriodRange(
          currentStart: currentStart,
          currentEnd: today,
          previousStart: previousStart,
          previousEnd: previousEnd,
        );

      case DashboardFinancePeriod.yearly:
        final yearStart = DateTime(today.year, 1, 1);
        final prevYearEnd =
            _clampDay(today.year - 1, today.month, today.day);
        final prevYearStart = DateTime(today.year - 1, 1, 1);
        return DashboardFinancePeriodRange(
          currentStart: yearStart,
          currentEnd: today,
          previousStart: prevYearStart,
          previousEnd: prevYearEnd,
        );
    }
  }
}
