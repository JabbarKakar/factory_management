part of 'finished_goods_detail_bloc.dart';

enum FinishedGoodsDetailStatus { initial, loading, loaded, saving, failure }

class FinishedGoodsDetailState extends Equatable {
  const FinishedGoodsDetailState({
    this.status = FinishedGoodsDetailStatus.initial,
    this.item,
    this.transactions = const [],
    this.errorMessage,
  });

  final FinishedGoodsDetailStatus status;
  final FinishedGood? item;
  final List<InventoryTransaction> transactions;
  final String? errorMessage;

  FinishedGoodsDetailState copyWith({
    FinishedGoodsDetailStatus? status,
    FinishedGood? item,
    List<InventoryTransaction>? transactions,
    String? errorMessage,
  }) {
    return FinishedGoodsDetailState(
      status: status ?? this.status,
      item: item ?? this.item,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, item, transactions, errorMessage];
}
