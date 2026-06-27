part of 'qc_list_bloc.dart';

sealed class QcListEvent extends Equatable {
  const QcListEvent();

  @override
  List<Object?> get props => [];
}

final class QcListWatchStarted extends QcListEvent {
  const QcListWatchStarted(this.factoryId, {this.initialFilter});

  final String factoryId;
  final QcListFilter? initialFilter;

  @override
  List<Object?> get props => [factoryId, initialFilter];
}

final class QcListWatchStopped extends QcListEvent {
  const QcListWatchStopped();
}

final class QcListSearchChanged extends QcListEvent {
  const QcListSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class QcListFilterChanged extends QcListEvent {
  const QcListFilterChanged(this.filter);

  final QcListFilter filter;

  @override
  List<Object?> get props => [filter];
}
