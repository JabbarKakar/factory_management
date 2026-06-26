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
