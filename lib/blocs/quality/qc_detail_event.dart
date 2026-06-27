part of 'qc_detail_bloc.dart';

sealed class QcDetailEvent extends Equatable {
  const QcDetailEvent();

  @override
  List<Object?> get props => [];
}

final class QcDetailWatchStarted extends QcDetailEvent {
  const QcDetailWatchStarted(this.qcId);

  final String qcId;

  @override
  List<Object?> get props => [qcId];
}

final class QcDetailWatchStopped extends QcDetailEvent {
  const QcDetailWatchStopped();
}
