part of 'delivery_detail_bloc.dart';

sealed class DeliveryDetailEvent extends Equatable {
  const DeliveryDetailEvent();

  @override
  List<Object?> get props => [];
}

final class DeliveryDetailWatchStarted extends DeliveryDetailEvent {
  const DeliveryDetailWatchStarted(
    this.deliveryId, {
    this.driverEmployeeId,
  });

  final String deliveryId;
  final String? driverEmployeeId;

  @override
  List<Object?> get props => [deliveryId, driverEmployeeId];
}

final class DeliveryDetailWatchStopped extends DeliveryDetailEvent {
  const DeliveryDetailWatchStopped();
}

final class DeliveryDetailStatusAdvanceRequested extends DeliveryDetailEvent {
  const DeliveryDetailStatusAdvanceRequested(this.newStatus);

  final DeliveryStatus newStatus;

  @override
  List<Object?> get props => [newStatus];
}

final class DeliveryDetailMarkFailedRequested extends DeliveryDetailEvent {
  const DeliveryDetailMarkFailedRequested({this.notes});

  final String? notes;

  @override
  List<Object?> get props => [notes];
}
