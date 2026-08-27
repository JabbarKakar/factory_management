import '../../domain/entities/dashboard_cashflow_metrics.dart';
import '../../domain/enums/dashboard_finance_period.dart';

/// The date window the dashboard should send to Firestore.
///
/// The selected period (and its previous-period comparison) is the floor, but
/// Daily still loads enough history for the month KPIs and the 30-day revenue
/// sparkline. All Time is capped at [allTimeCapMonths] so it cannot scan the
/// whole factory history.
class DashboardQueryWindow {
  const DashboardQueryWindow({required this.from});

  /// Inclusive lower bound for date-filtered dashboard queries.
  final DateTime from;

  static const int windowedLimit = 1500;
  static const int operationalLimit = 400;
  static const int catalogLimit = 200;
  static const int analyticsFloorDays = 30;
  static const int allTimeCapMonths = 24;

  factory DashboardQueryWindow.forDashboard({
    required DashboardFinancePeriod financePeriod,
    required DashboardFinancePeriod stockCutPeriod,
    required DashboardFinancePeriod salesSqFtPeriod,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    var earliest = today.subtract(const Duration(days: analyticsFloorDays));
    final monthStart = DateTime(today.year, today.month, 1);
    if (monthStart.isBefore(earliest)) earliest = monthStart;

    for (final period in [financePeriod, stockCutPeriod, salesSqFtPeriod]) {
      // Six months / yearly / All Time read `dashboardRollups` (S41).
      if (period.usesMonthlyRollups) continue;
      final range = DashboardFinancePeriodRange.forPeriod(period, today);
      if (range.previousStart.isBefore(earliest)) {
        earliest = range.previousStart;
      }
      if (range.currentStart.isBefore(earliest)) {
        earliest = range.currentStart;
      }
    }

    return DashboardQueryWindow(
      from: DateTime(earliest.year, earliest.month, earliest.day),
    );
  }

  bool isSameAs(DashboardQueryWindow other) =>
      from.year == other.from.year &&
      from.month == other.from.month &&
      from.day == other.from.day;
}
