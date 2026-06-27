part of 'production_detail_bloc.dart';

abstract class ProductionDetailEvent extends Equatable {
  const ProductionDetailEvent();

  @override
  List<Object?> get props => [];
}

class ProductionDetailWatchStarted extends ProductionDetailEvent {
  const ProductionDetailWatchStarted(this.batchId);

  final String batchId;

  @override
  List<Object?> get props => [batchId];
}

class _ProductionDetailUpdated extends ProductionDetailEvent {
  const _ProductionDetailUpdated(this.batch);

  final ProductionBatch? batch;

  @override
  List<Object?> get props => [batch];
}

class _ProductionDetailStreamFailed extends ProductionDetailEvent {
  const _ProductionDetailStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class _ProductionDetailQcUpdated extends ProductionDetailEvent {
  const _ProductionDetailQcUpdated(this.checks);

  final List<QualityCheck> checks;

  @override
  List<Object?> get props => [checks];
}
