part of 'finished_goods_detail_bloc.dart';

abstract class FinishedGoodsDetailEvent extends Equatable {
  const FinishedGoodsDetailEvent();

  @override
  List<Object?> get props => [];
}

class FinishedGoodsDetailWatchStarted extends FinishedGoodsDetailEvent {
  const FinishedGoodsDetailWatchStarted({
    required this.factoryId,
    required this.finishedGoodId,
  });

  final String factoryId;
  final String finishedGoodId;

  @override
  List<Object?> get props => [factoryId, finishedGoodId];
}

class FinishedGoodsReorderLevelUpdated extends FinishedGoodsDetailEvent {
  const FinishedGoodsReorderLevelUpdated(this.reorderLevel);

  final double reorderLevel;

  @override
  List<Object?> get props => [reorderLevel];
}

class FinishedGoodsLocationUpdated extends FinishedGoodsDetailEvent {
  const FinishedGoodsLocationUpdated(this.location);

  final String? location;

  @override
  List<Object?> get props => [location];
}

class _FinishedGoodsDetailDataUpdated extends FinishedGoodsDetailEvent {
  const _FinishedGoodsDetailDataUpdated();
}

class _FinishedGoodsDetailStreamFailed extends FinishedGoodsDetailEvent {
  const _FinishedGoodsDetailStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
