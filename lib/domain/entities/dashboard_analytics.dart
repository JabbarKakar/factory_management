import 'package:equatable/equatable.dart';

class DailyProductionPoint extends Equatable {
  const DailyProductionPoint({
    required this.date,
    required this.ownProductionSqFt,
    required this.jobWorkSqFt,
  });

  final DateTime date;
  final double ownProductionSqFt;
  final double jobWorkSqFt;

  double get totalSqFt => ownProductionSqFt + jobWorkSqFt;

  @override
  List<Object?> get props => [date, ownProductionSqFt, jobWorkSqFt];
}

class DailyRevenuePoint extends Equatable {
  const DailyRevenuePoint({
    required this.date,
    required this.salesAmount,
    required this.jobWorkAmount,
  });

  final DateTime date;
  final double salesAmount;
  final double jobWorkAmount;

  double get totalAmount => salesAmount + jobWorkAmount;

  @override
  List<Object?> get props => [date, salesAmount, jobWorkAmount];
}

class RevenueBreakdownSlice extends Equatable {
  const RevenueBreakdownSlice({
    required this.label,
    required this.amount,
  });

  final String label;
  final double amount;

  @override
  List<Object?> get props => [label, amount];
}

enum RecentActivityType {
  payment,
}

class RecentActivityItem extends Equatable {
  const RecentActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.amount,
  });

  final String id;
  final RecentActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final double? amount;

  @override
  List<Object?> get props => [id, type, title, subtitle, timestamp, amount];
}

class DashboardAnalytics extends Equatable {
  const DashboardAnalytics({
    this.productionLast7Days = const [],
    this.revenueLast30Days = const [],
    this.revenueBreakdownThisMonth = const [],
    this.recentActivity = const [],
  });

  static const empty = DashboardAnalytics();

  final List<DailyProductionPoint> productionLast7Days;
  final List<DailyRevenuePoint> revenueLast30Days;
  final List<RevenueBreakdownSlice> revenueBreakdownThisMonth;
  final List<RecentActivityItem> recentActivity;

  bool get hasProductionChart =>
      productionLast7Days.any((point) => point.totalSqFt > 0);

  bool get hasRevenueChart =>
      revenueLast30Days.any((point) => point.totalAmount > 0);

  bool get hasRevenueBreakdown =>
      revenueBreakdownThisMonth.any((slice) => slice.amount > 0);

  @override
  List<Object?> get props => [
        productionLast7Days,
        revenueLast30Days,
        revenueBreakdownThisMonth,
        recentActivity,
      ];
}
