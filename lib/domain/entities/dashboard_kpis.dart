import 'package:equatable/equatable.dart';

class DashboardKpis extends Equatable {
  const DashboardKpis({
    required this.revenueToday,
    required this.activeJobWorkCount,
    required this.activeSalesCount,
    required this.pendingPickupCount,
    required this.expensesThisMonth,
    required this.expenseCountThisMonth,
    required this.lowStockCount,
    required this.overdueAmount,
    required this.overdueCount,
    required this.customerCount,
    required this.activeLabourCount,
    required this.presentLabourToday,
    required this.unmarkedAttendanceToday,
    required this.activeDeliveriesCount,
    required this.scheduledDeliveriesToday,
    required this.maintenanceOverdueCount,
    required this.maintenanceDueSoonCount,
    required this.qcRejectsThisMonth,
    required this.jobWorkPendingQcCount,
    required this.salesRevenueToday,
    required this.jobWorkRevenueToday,
    required this.revenueThisMonth,
    required this.dueThisWeekCount,
    required this.dueThisWeekAmount,
    required this.ownProductionTodaySqFt,
    required this.jobWorkOutputTodaySqFt,
    required this.productionThisMonthSqFt,
  });

  static const empty = DashboardKpis(
    revenueToday: 0,
    activeJobWorkCount: 0,
    activeSalesCount: 0,
    pendingPickupCount: 0,
    expensesThisMonth: 0,
    expenseCountThisMonth: 0,
    lowStockCount: 0,
    overdueAmount: 0,
    overdueCount: 0,
    customerCount: 0,
    activeLabourCount: 0,
    presentLabourToday: 0,
    unmarkedAttendanceToday: 0,
    activeDeliveriesCount: 0,
    scheduledDeliveriesToday: 0,
    maintenanceOverdueCount: 0,
    maintenanceDueSoonCount: 0,
    qcRejectsThisMonth: 0,
    jobWorkPendingQcCount: 0,
    salesRevenueToday: 0,
    jobWorkRevenueToday: 0,
    revenueThisMonth: 0,
    dueThisWeekCount: 0,
    dueThisWeekAmount: 0,
    ownProductionTodaySqFt: 0,
    jobWorkOutputTodaySqFt: 0,
    productionThisMonthSqFt: 0,
  );

  final double revenueToday;
  final int activeJobWorkCount;
  final int activeSalesCount;
  final int pendingPickupCount;
  final double expensesThisMonth;
  final int expenseCountThisMonth;
  final int lowStockCount;
  final int overdueCount;
  final double overdueAmount;
  final int customerCount;
  final int activeLabourCount;
  final int presentLabourToday;
  final int unmarkedAttendanceToday;
  final int activeDeliveriesCount;
  final int scheduledDeliveriesToday;
  final int maintenanceOverdueCount;
  final int maintenanceDueSoonCount;
  final int qcRejectsThisMonth;
  final int jobWorkPendingQcCount;
  final double salesRevenueToday;
  final double jobWorkRevenueToday;
  final double revenueThisMonth;
  final int dueThisWeekCount;
  final double dueThisWeekAmount;
  final double ownProductionTodaySqFt;
  final double jobWorkOutputTodaySqFt;
  final double productionThisMonthSqFt;

  double get productionTodaySqFt =>
      ownProductionTodaySqFt + jobWorkOutputTodaySqFt;

  @override
  List<Object?> get props => [
        revenueToday,
        activeJobWorkCount,
        activeSalesCount,
        pendingPickupCount,
        expensesThisMonth,
        expenseCountThisMonth,
        lowStockCount,
        overdueCount,
        overdueAmount,
        customerCount,
        activeLabourCount,
        presentLabourToday,
        unmarkedAttendanceToday,
        activeDeliveriesCount,
        scheduledDeliveriesToday,
        maintenanceOverdueCount,
        maintenanceDueSoonCount,
        qcRejectsThisMonth,
        jobWorkPendingQcCount,
        salesRevenueToday,
        jobWorkRevenueToday,
        revenueThisMonth,
        dueThisWeekCount,
        dueThisWeekAmount,
        ownProductionTodaySqFt,
        jobWorkOutputTodaySqFt,
        productionThisMonthSqFt,
      ];
}
