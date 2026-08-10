part of 'sales_order_list_bloc.dart';

enum SalesOrderListStatus { initial, loading, loaded, failure }

class SalesOrderListState extends Equatable {
  const SalesOrderListState({
    this.status = SalesOrderListStatus.initial,
    this.orders = const [],
    this.visibleOrders = const [],
    this.searchQuery = '',
    this.stageFilter = SalesListFilter.all,
    this.errorMessage,
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.hasMoreData = true,
    this.lastDocument,
    this.factoryId = '',
  });

  final SalesOrderListStatus status;
  final List<SalesOrder> orders;
  final List<SalesOrder> visibleOrders;
  final String searchQuery;
  final SalesListFilter stageFilter;
  final String? errorMessage;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool hasMoreData;
  final DocumentSnapshot? lastDocument;
  final String factoryId;

  SalesOrderListState copyWith({
    SalesOrderListStatus? status,
    List<SalesOrder>? orders,
    List<SalesOrder>? visibleOrders,
    String? searchQuery,
    SalesListFilter? stageFilter,
    String? errorMessage,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMoreData,
    DocumentSnapshot? lastDocument,
    bool clearLastDocument = false,
    String? factoryId,
  }) {
    return SalesOrderListState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      visibleOrders: visibleOrders ?? this.visibleOrders,
      searchQuery: searchQuery ?? this.searchQuery,
      stageFilter: stageFilter ?? this.stageFilter,
      errorMessage: errorMessage,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      lastDocument:
          clearLastDocument ? null : (lastDocument ?? this.lastDocument),
      factoryId: factoryId ?? this.factoryId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        orders,
        visibleOrders,
        searchQuery,
        stageFilter,
        errorMessage,
        isLoadingInitial,
        isLoadingMore,
        hasMoreData,
        lastDocument,
        factoryId,
      ];
}
