/// Time window for dashboard cashflow / stock-cut metrics.
enum DashboardFinancePeriod {
  daily,
  weekly,
  monthly,
  sixMonths,
  yearly,
  allTime;

  String get label => switch (this) {
        DashboardFinancePeriod.daily => 'Daily',
        DashboardFinancePeriod.weekly => 'Weekly',
        DashboardFinancePeriod.monthly => 'Monthly',
        DashboardFinancePeriod.sixMonths => '6 Months',
        DashboardFinancePeriod.yearly => 'Yearly',
        DashboardFinancePeriod.allTime => 'Last 24 mo',
      };

  /// Short comparison label for trend captions.
  String get vsPreviousLabel => switch (this) {
        DashboardFinancePeriod.daily => 'vs yesterday',
        DashboardFinancePeriod.weekly => 'vs last week',
        DashboardFinancePeriod.monthly => 'vs last month',
        DashboardFinancePeriod.sixMonths => 'vs prior 6 mo',
        DashboardFinancePeriod.yearly => 'vs last year',
        DashboardFinancePeriod.allTime => 'vs prior 24 mo',
      };
}
