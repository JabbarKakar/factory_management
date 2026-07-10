part of 'delivery_confirm_bloc.dart';

sealed class DeliveryConfirmEvent extends Equatable {
  const DeliveryConfirmEvent();

  @override
  List<Object?> get props => [];
}

final class DeliveryConfirmInitialized extends DeliveryConfirmEvent {
  const DeliveryConfirmInitialized(this.deliveryId);

  final String deliveryId;

  @override
  List<Object?> get props => [deliveryId];
}

final class DeliveryConfirmSubmitted extends DeliveryConfirmEvent {
  const DeliveryConfirmSubmitted({
    required this.actualDeliveryDate,
    required this.lineItems,
    this.notes,
    this.receiverName,
  });

  final DateTime actualDeliveryDate;
  final List<DeliveryLineItem> lineItems;
  final String? notes;
  final String? receiverName;

  @override
  List<Object?> get props => [actualDeliveryDate, lineItems, notes, receiverName];
}
