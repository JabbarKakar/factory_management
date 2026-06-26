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
    this.factoryId,
    this.errorMessage,
  });

  final DashboardStatus status;
  final DashboardKpis kpis;
  final String? factoryId;
  final String? errorMessage;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardKpis? kpis,
    String? factoryId,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      kpis: kpis ?? this.kpis,
      factoryId: factoryId ?? this.factoryId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, kpis, factoryId, errorMessage];
}
