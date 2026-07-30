/// Time window for dashboard income / expense cashflow metrics.
enum DashboardFinancePeriod {
  daily,
  weekly,
  monthly,
  sixMonths,
  yearly;

  String get label => switch (this) {
        DashboardFinancePeriod.daily => 'Daily',
        DashboardFinancePeriod.weekly => 'Weekly',
        DashboardFinancePeriod.monthly => 'Monthly',
        DashboardFinancePeriod.sixMonths => '6 Months',
        DashboardFinancePeriod.yearly => 'Yearly',
      };

  /// Short comparison label for trend captions.
  String get vsPreviousLabel => switch (this) {
        DashboardFinancePeriod.daily => 'vs yesterday',
        DashboardFinancePeriod.weekly => 'vs last week',
        DashboardFinancePeriod.monthly => 'vs last month',
        DashboardFinancePeriod.sixMonths => 'vs prior 6 mo',
        DashboardFinancePeriod.yearly => 'vs last year',
      };
}
