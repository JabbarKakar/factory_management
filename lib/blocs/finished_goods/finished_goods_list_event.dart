part of 'finished_goods_list_bloc.dart';

abstract class FinishedGoodsListEvent extends Equatable {
  const FinishedGoodsListEvent();

  @override
  List<Object?> get props => [];
}

class FinishedGoodsListWatchStarted extends FinishedGoodsListEvent {
  const FinishedGoodsListWatchStarted(this.factoryId);

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

class FinishedGoodsListSearchChanged extends FinishedGoodsListEvent {
  const FinishedGoodsListSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class FinishedGoodsListFilterChanged extends FinishedGoodsListEvent {
  const FinishedGoodsListFilterChanged(this.filter);

  final FinishedGoodsListFilter filter;

  @override
  List<Object?> get props => [filter];
}

class _FinishedGoodsListUpdated extends FinishedGoodsListEvent {
  const _FinishedGoodsListUpdated(this.items);

  final List<FinishedGood> items;

  @override
  List<Object?> get props => [items];
}

class _FinishedGoodsListStreamFailed extends FinishedGoodsListEvent {
  const _FinishedGoodsListStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
