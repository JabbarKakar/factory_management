part of 'dashboard_bloc.dart';

enum DashboardStatus {
  initial,
  loading,
  loaded,
  failure,
}

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.kpis = DashboardKpis.empty,
    this.analytics = DashboardAnalytics.empty,
    this.pendingPickups = const [],
    this.cashflow = DashboardCashflowMetrics.empty,
    this.financePeriod = DashboardFinancePeriod.daily,
    this.stockCut = DashboardStockCutMetrics.empty,
    this.stockCutPeriod = DashboardFinancePeriod.daily,
    this.factoryId,
    this.errorMessage,
  });

  final DashboardStatus status;
  final DashboardKpis kpis;
  final DashboardAnalytics analytics;
  final List<DashboardPendingPickup> pendingPickups;
  final DashboardCashflowMetrics cashflow;
  final DashboardFinancePeriod financePeriod;
  final DashboardStockCutMetrics stockCut;
  final DashboardFinancePeriod stockCutPeriod;
  final String? factoryId;
  final String? errorMessage;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardKpis? kpis,
    DashboardAnalytics? analytics,
    List<DashboardPendingPickup>? pendingPickups,
    DashboardCashflowMetrics? cashflow,
    DashboardFinancePeriod? financePeriod,
    DashboardStockCutMetrics? stockCut,
    DashboardFinancePeriod? stockCutPeriod,
    String? factoryId,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      kpis: kpis ?? this.kpis,
      analytics: analytics ?? this.analytics,
      pendingPickups: pendingPickups ?? this.pendingPickups,
      cashflow: cashflow ?? this.cashflow,
      financePeriod: financePeriod ?? this.financePeriod,
      stockCut: stockCut ?? this.stockCut,
      stockCutPeriod: stockCutPeriod ?? this.stockCutPeriod,
      factoryId: factoryId ?? this.factoryId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        kpis,
        analytics,
        pendingPickups,
        cashflow,
        financePeriod,
        stockCut,
        stockCutPeriod,
        factoryId,
        errorMessage,
      ];
}
