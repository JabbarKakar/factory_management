part of 'delivery_confirm_bloc.dart';

enum DeliveryConfirmStatus { initial, loading, ready, saving, saved, failure }

class DeliveryConfirmState extends Equatable {
  const DeliveryConfirmState({
    this.status = DeliveryConfirmStatus.initial,
    this.delivery,
    this.errorMessage,
  });

  final DeliveryConfirmStatus status;
  final Delivery? delivery;
  final String? errorMessage;

  DeliveryConfirmState copyWith({
    DeliveryConfirmStatus? status,
    Delivery? delivery,
    String? errorMessage,
  }) {
    return DeliveryConfirmState(
      status: status ?? this.status,
      delivery: delivery ?? this.delivery,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, delivery, errorMessage];
}
