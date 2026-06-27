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
    this.factoryId,
    this.errorMessage,
  });

  final DashboardStatus status;
  final DashboardKpis kpis;
  final DashboardAnalytics analytics;
  final List<JobWorkOrder> pendingPickups;
  final String? factoryId;
  final String? errorMessage;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardKpis? kpis,
    DashboardAnalytics? analytics,
    List<JobWorkOrder>? pendingPickups,
    String? factoryId,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      kpis: kpis ?? this.kpis,
      analytics: analytics ?? this.analytics,
      pendingPickups: pendingPickups ?? this.pendingPickups,
      factoryId: factoryId ?? this.factoryId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, kpis, analytics, pendingPickups, factoryId, errorMessage];
}
