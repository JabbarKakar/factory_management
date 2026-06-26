part of 'sales_order_list_bloc.dart';

sealed class SalesOrderListEvent extends Equatable {
  const SalesOrderListEvent();

  @override
  List<Object?> get props => [];
}

final class SalesOrderListWatchStarted extends SalesOrderListEvent {
  const SalesOrderListWatchStarted(this.factoryId, {this.initialFilter});

  final String factoryId;
  final SalesListFilter? initialFilter;

  @override
  List<Object?> get props => [factoryId, initialFilter];
}

final class SalesOrderListSearchChanged extends SalesOrderListEvent {
  const SalesOrderListSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class SalesOrderListStageFilterChanged extends SalesOrderListEvent {
  const SalesOrderListStageFilterChanged(this.stageFilter);

  final SalesListFilter stageFilter;

  @override
  List<Object?> get props => [stageFilter];
}

final class _SalesOrderListUpdated extends SalesOrderListEvent {
  const _SalesOrderListUpdated(this.orders);

  final List<SalesOrder> orders;

  @override
  List<Object?> get props => [orders];
}

final class _SalesOrderListStreamFailed extends SalesOrderListEvent {
  const _SalesOrderListStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
