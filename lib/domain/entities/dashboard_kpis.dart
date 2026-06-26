import 'package:equatable/equatable.dart';

class DashboardKpis extends Equatable {
  const DashboardKpis({
    required this.revenueToday,
    required this.activeJobWorkCount,
    required this.overdueAmount,
    required this.overdueCount,
    required this.customerCount,
  });

  static const empty = DashboardKpis(
    revenueToday: 0,
    activeJobWorkCount: 0,
    overdueAmount: 0,
    overdueCount: 0,
    customerCount: 0,
  );

  final double revenueToday;
  final int activeJobWorkCount;
  final int overdueCount;
  final double overdueAmount;
  final int customerCount;

  @override
  List<Object?> get props => [
        revenueToday,
        activeJobWorkCount,
        overdueCount,
        overdueAmount,
        customerCount,
      ];
}
