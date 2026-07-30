import 'package:equatable/equatable.dart';

class DashboardKpis extends Equatable {
  const DashboardKpis({
    required this.revenueToday,
    required this.activeJobWorkCount,
    required this.activeLoadCount,
    required this.activeSalesCount,
    required this.pendingPickupCount,
    required this.partiallyCollectedOrdersCount,
    required this.stalePickupCount,
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
    required this.partiallyDispatchedOrdersCount,
    required this.readyForDispatchCount,
    required this.dispatchedTodayPieces,
    required this.dispatchedTodaySquareFeet,
    required this.overdueDeliveriesCount,
    required this.maintenanceOverdueCount,
    required this.maintenanceDueSoonCount,
    required this.qcRejectsThisMonth,
    required this.jobWorkPendingQcCount,
    required this.salesRevenueToday,
    required this.jobWorkRevenueToday,
    required this.revenueYesterday,
    required this.revenueThisMonth,
    required this.expensesToday,
    required this.expensesYesterday,
    required this.dueThisWeekCount,
    required this.dueThisWeekAmount,
    required this.ownProductionTodaySqFt,
    required this.jobWorkOutputTodaySqFt,
    required this.productionThisMonthSqFt,
  });

  static const empty = DashboardKpis(
    revenueToday: 0,
    activeJobWorkCount: 0,
    activeLoadCount: 0,
    activeSalesCount: 0,
    pendingPickupCount: 0,
    partiallyCollectedOrdersCount: 0,
    stalePickupCount: 0,
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
    partiallyDispatchedOrdersCount: 0,
    readyForDispatchCount: 0,
    dispatchedTodayPieces: 0,
    dispatchedTodaySquareFeet: 0,
    overdueDeliveriesCount: 0,
    maintenanceOverdueCount: 0,
    maintenanceDueSoonCount: 0,
    qcRejectsThisMonth: 0,
    jobWorkPendingQcCount: 0,
    salesRevenueToday: 0,
    jobWorkRevenueToday: 0,
    revenueYesterday: 0,
    revenueThisMonth: 0,
    expensesToday: 0,
    expensesYesterday: 0,
    dueThisWeekCount: 0,
    dueThisWeekAmount: 0,
    ownProductionTodaySqFt: 0,
    jobWorkOutputTodaySqFt: 0,
    productionThisMonthSqFt: 0,
  );

  final double revenueToday;
  /// Job Work containers with an active status (rollup).
  final int activeJobWorkCount;
  /// Persisted Loads currently in active production/ops statuses.
  final int activeLoadCount;
  final int activeSalesCount;
  /// Loads (or legacy JW) awaiting customer pickup.
  final int pendingPickupCount;
  /// Loads (or legacy JW) that are partially collected.
  final int partiallyCollectedOrdersCount;
  /// Loads (or legacy JW) with stale pending pickup.
  final int stalePickupCount;
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
  final int partiallyDispatchedOrdersCount;
  final int readyForDispatchCount;
  final int dispatchedTodayPieces;
  final double dispatchedTodaySquareFeet;
  final int overdueDeliveriesCount;
  final int maintenanceOverdueCount;
  final int maintenanceDueSoonCount;
  final int qcRejectsThisMonth;
  final int jobWorkPendingQcCount;
  final double salesRevenueToday;
  final double jobWorkRevenueToday;
  final double revenueYesterday;
  final double revenueThisMonth;
  final double expensesToday;
  final double expensesYesterday;
  final int dueThisWeekCount;
  final double dueThisWeekAmount;
  final double ownProductionTodaySqFt;
  final double jobWorkOutputTodaySqFt;
  final double productionThisMonthSqFt;

  double get productionTodaySqFt =>
      ownProductionTodaySqFt + jobWorkOutputTodaySqFt;

  /// Day-over-day % for income; `null` when both days are zero.
  double? get revenueDayOverDayPercent =>
      dayOverDayPercent(revenueToday, revenueYesterday);

  /// Day-over-day % for expenses; `null` when both days are zero.
  double? get expensesDayOverDayPercent =>
      dayOverDayPercent(expensesToday, expensesYesterday);

  /// Today's expenses as a % of today's income; `null` when income is 0.
  double? get expensesToIncomePercent =>
      revenueToday > 0 ? (expensesToday / revenueToday) * 100 : null;

  /// Income received today minus expenses recorded today.
  double get netCashflowToday => revenueToday - expensesToday;

  /// `((today - yesterday) / yesterday) * 100`.
  /// Returns `null` when both are 0; `100` when yesterday is 0 and today > 0.
  static double? dayOverDayPercent(double today, double yesterday) {
    if (yesterday == 0) {
      if (today == 0) return null;
      return 100;
    }
    return ((today - yesterday) / yesterday) * 100;
  }

  @override
  List<Object?> get props => [
        revenueToday,
        activeJobWorkCount,
        activeLoadCount,
        activeSalesCount,
        pendingPickupCount,
        partiallyCollectedOrdersCount,
        stalePickupCount,
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
        partiallyDispatchedOrdersCount,
        readyForDispatchCount,
        dispatchedTodayPieces,
        dispatchedTodaySquareFeet,
        overdueDeliveriesCount,
        maintenanceOverdueCount,
        maintenanceDueSoonCount,
        qcRejectsThisMonth,
        jobWorkPendingQcCount,
        salesRevenueToday,
        jobWorkRevenueToday,
        revenueYesterday,
        revenueThisMonth,
        expensesToday,
        expensesYesterday,
        dueThisWeekCount,
        dueThisWeekAmount,
        ownProductionTodaySqFt,
        jobWorkOutputTodaySqFt,
        productionThisMonthSqFt,
      ];
}
