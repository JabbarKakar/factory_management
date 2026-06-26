part of 'sales_order_form_bloc.dart';

sealed class SalesOrderFormEvent extends Equatable {
  const SalesOrderFormEvent();

  @override
  List<Object?> get props => [];
}

final class SalesOrderFormInitialized extends SalesOrderFormEvent {
  const SalesOrderFormInitialized({required this.factoryId});

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

final class SalesOrderFormLoadRequested extends SalesOrderFormEvent {
  const SalesOrderFormLoadRequested(this.salesOrderId);

  final String salesOrderId;

  @override
  List<Object?> get props => [salesOrderId];
}

final class SalesOrderFormSubmitted extends SalesOrderFormEvent {
  const SalesOrderFormSubmitted(this.order);

  final SalesOrder order;

  @override
  List<Object?> get props => [order];
}

final class SalesOrderFormCancelRequested extends SalesOrderFormEvent {
  const SalesOrderFormCancelRequested(this.salesOrderId);

  final String salesOrderId;

  @override
  List<Object?> get props => [salesOrderId];
}

final class SalesOrderFormStatusAdvanceRequested extends SalesOrderFormEvent {
  const SalesOrderFormStatusAdvanceRequested({
    required this.salesOrderId,
    required this.newStatus,
  });

  final String salesOrderId;
  final SalesOrderStatus newStatus;

  @override
  List<Object?> get props => [salesOrderId, newStatus];
}
