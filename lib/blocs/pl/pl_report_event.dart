part of 'pl_report_bloc.dart';

sealed class PlReportEvent extends Equatable {
  const PlReportEvent();

  @override
  List<Object?> get props => [];
}

final class PlReportWatchStarted extends PlReportEvent {
  const PlReportWatchStarted(this.factoryId, {this.initialMonth});

  final String factoryId;
  final DateTime? initialMonth;

  @override
  List<Object?> get props => [factoryId, initialMonth];
}

final class PlReportWatchStopped extends PlReportEvent {
  const PlReportWatchStopped();
}

final class PlReportMonthChanged extends PlReportEvent {
  const PlReportMonthChanged(this.month);

  final DateTime month;

  @override
  List<Object?> get props => [month];
}
