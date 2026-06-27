part of 'production_list_bloc.dart';

abstract class ProductionListEvent extends Equatable {
  const ProductionListEvent();

  @override
  List<Object?> get props => [];
}

class ProductionListWatchStarted extends ProductionListEvent {
  const ProductionListWatchStarted(this.factoryId);

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

class ProductionListSearchChanged extends ProductionListEvent {
  const ProductionListSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class ProductionListFilterChanged extends ProductionListEvent {
  const ProductionListFilterChanged(this.filter);

  final ProductionListFilter filter;

  @override
  List<Object?> get props => [filter];
}

class _ProductionListUpdated extends ProductionListEvent {
  const _ProductionListUpdated(this.batches);

  final List<ProductionBatch> batches;

  @override
  List<Object?> get props => [batches];
}

class _ProductionListStreamFailed extends ProductionListEvent {
  const _ProductionListStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
