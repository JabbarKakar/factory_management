import 'package:equatable/equatable.dart';

class DashboardKpis extends Equatable {
  const DashboardKpis({
    required this.revenueToday,
    required this.activeJobWorkCount,
    required this.activeSalesCount,
    required this.pendingPickupCount,
    required this.expensesThisMonth,
    required this.expenseCountThisMonth,
    required this.overdueAmount,
    required this.overdueCount,
    required this.customerCount,
  });

  static const empty = DashboardKpis(
    revenueToday: 0,
    activeJobWorkCount: 0,
    activeSalesCount: 0,
    pendingPickupCount: 0,
    expensesThisMonth: 0,
    expenseCountThisMonth: 0,
    overdueAmount: 0,
    overdueCount: 0,
    customerCount: 0,
  );

  final double revenueToday;
  final int activeJobWorkCount;
  final int activeSalesCount;
  final int pendingPickupCount;
  final double expensesThisMonth;
  final int expenseCountThisMonth;
  final int overdueCount;
  final double overdueAmount;
  final int customerCount;

  @override
  List<Object?> get props => [
        revenueToday,
        activeJobWorkCount,
        activeSalesCount,
        pendingPickupCount,
        expensesThisMonth,
        expenseCountThisMonth,
        overdueCount,
        overdueAmount,
        customerCount,
      ];
}
