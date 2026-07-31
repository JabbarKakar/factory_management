part of 'dashboard_bloc.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

final class DashboardWatchStarted extends DashboardEvent {
  const DashboardWatchStarted(this.factoryId);

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

final class DashboardWatchStopped extends DashboardEvent {
  const DashboardWatchStopped();
}

final class DashboardFinancePeriodChanged extends DashboardEvent {
  const DashboardFinancePeriodChanged(this.period);

  final DashboardFinancePeriod period;

  @override
  List<Object?> get props => [period];
}

final class DashboardStockCutPeriodChanged extends DashboardEvent {
  const DashboardStockCutPeriodChanged(this.period);

  final DashboardFinancePeriod period;

  @override
  List<Object?> get props => [period];
}
