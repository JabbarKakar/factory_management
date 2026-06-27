part of 'finished_goods_list_bloc.dart';

enum FinishedGoodsListStatus { initial, loading, loaded, failure }

class FinishedGoodsListState extends Equatable {
  const FinishedGoodsListState({
    this.status = FinishedGoodsListStatus.initial,
    this.items = const [],
    this.visibleItems = const [],
    this.searchQuery = '',
    this.filter = FinishedGoodsListFilter.all,
    this.totalStockValue = 0,
    this.lowStockCount = 0,
    this.errorMessage,
  });

  final FinishedGoodsListStatus status;
  final List<FinishedGood> items;
  final List<FinishedGood> visibleItems;
  final String searchQuery;
  final FinishedGoodsListFilter filter;
  final double totalStockValue;
  final int lowStockCount;
  final String? errorMessage;

  FinishedGoodsListState copyWith({
    FinishedGoodsListStatus? status,
    List<FinishedGood>? items,
    List<FinishedGood>? visibleItems,
    String? searchQuery,
    FinishedGoodsListFilter? filter,
    double? totalStockValue,
    int? lowStockCount,
    String? errorMessage,
  }) {
    return FinishedGoodsListState(
      status: status ?? this.status,
      items: items ?? this.items,
      visibleItems: visibleItems ?? this.visibleItems,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      totalStockValue: totalStockValue ?? this.totalStockValue,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        visibleItems,
        searchQuery,
        filter,
        totalStockValue,
        lowStockCount,
        errorMessage,
      ];
}
