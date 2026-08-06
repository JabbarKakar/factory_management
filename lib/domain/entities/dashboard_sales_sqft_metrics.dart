import 'package:equatable/equatable.dart';

import '../enums/dashboard_finance_period.dart';
import 'dashboard_kpis.dart';

/// Small / large / total sales square feet and monetary amounts for a dashboard period.
class DashboardSalesSqFtMetrics extends Equatable {
  const DashboardSalesSqFtMetrics({
    required this.period,
    required this.smallSqFt,
    required this.largeSqFt,
    required this.previousSmallSqFt,
    required this.previousLargeSqFt,
    this.smallAmount = 0,
    this.largeAmount = 0,
    this.previousSmallAmount = 0,
    this.previousLargeAmount = 0,
  });

  static const empty = DashboardSalesSqFtMetrics(
    period: DashboardFinancePeriod.daily,
    smallSqFt: 0,
    largeSqFt: 0,
    previousSmallSqFt: 0,
    previousLargeSqFt: 0,
    smallAmount: 0,
    largeAmount: 0,
    previousSmallAmount: 0,
    previousLargeAmount: 0,
  );

  final DashboardFinancePeriod period;
  final double smallSqFt;
  final double largeSqFt;
  final double previousSmallSqFt;
  final double previousLargeSqFt;
  final double smallAmount;
  final double largeAmount;
  final double previousSmallAmount;
  final double previousLargeAmount;

  double get totalSqFt => smallSqFt + largeSqFt;
  double get totalAmount => smallAmount + largeAmount;

  double get previousTotalSqFt => previousSmallSqFt + previousLargeSqFt;
  double get previousTotalAmount => previousSmallAmount + previousLargeAmount;

  double? get smallChangePercent =>
      DashboardKpis.dayOverDayPercent(smallSqFt, previousSmallSqFt);

  double? get largeChangePercent =>
      DashboardKpis.dayOverDayPercent(largeSqFt, previousLargeSqFt);

  double? get totalChangePercent =>
      DashboardKpis.dayOverDayPercent(totalSqFt, previousTotalSqFt);

  @override
  List<Object?> get props => [
        period,
        smallSqFt,
        largeSqFt,
        previousSmallSqFt,
        previousLargeSqFt,
        smallAmount,
        largeAmount,
        previousSmallAmount,
        previousLargeAmount,
      ];
}
