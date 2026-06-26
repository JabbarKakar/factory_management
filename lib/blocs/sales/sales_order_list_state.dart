part of 'sales_order_list_bloc.dart';

enum SalesOrderListStatus { initial, loading, loaded, failure }

class SalesOrderListState extends Equatable {
  const SalesOrderListState({
    this.status = SalesOrderListStatus.initial,
    this.orders = const [],
    this.visibleOrders = const [],
    this.searchQuery = '',
    this.showActiveOnly = true,
    this.stageFilter = SalesListFilter.all,
    this.errorMessage,
  });

  final SalesOrderListStatus status;
  final List<SalesOrder> orders;
  final List<SalesOrder> visibleOrders;
  final String searchQuery;
  final bool showActiveOnly;
  final SalesListFilter stageFilter;
  final String? errorMessage;

  SalesOrderListState copyWith({
    SalesOrderListStatus? status,
    List<SalesOrder>? orders,
    List<SalesOrder>? visibleOrders,
    String? searchQuery,
    bool? showActiveOnly,
    SalesListFilter? stageFilter,
    String? errorMessage,
  }) {
    return SalesOrderListState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      visibleOrders: visibleOrders ?? this.visibleOrders,
      searchQuery: searchQuery ?? this.searchQuery,
      showActiveOnly: showActiveOnly ?? this.showActiveOnly,
      stageFilter: stageFilter ?? this.stageFilter,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        orders,
        visibleOrders,
        searchQuery,
        showActiveOnly,
        stageFilter,
        errorMessage,
      ];
}
