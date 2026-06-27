part of 'delivery_form_bloc.dart';

sealed class DeliveryFormEvent extends Equatable {
  const DeliveryFormEvent();

  @override
  List<Object?> get props => [];
}

final class DeliveryFormInitialized extends DeliveryFormEvent {
  const DeliveryFormInitialized({
    required this.factoryId,
    this.salesOrderId,
  });

  final String factoryId;
  final String? salesOrderId;

  @override
  List<Object?> get props => [factoryId, salesOrderId];
}

final class DeliveryFormSalesOrderSelected extends DeliveryFormEvent {
  const DeliveryFormSalesOrderSelected(this.salesOrderId);

  final String salesOrderId;

  @override
  List<Object?> get props => [salesOrderId];
}

final class DeliveryFormSubmitted extends DeliveryFormEvent {
  const DeliveryFormSubmitted(this.delivery);

  final Delivery delivery;

  @override
  List<Object?> get props => [delivery];
}
