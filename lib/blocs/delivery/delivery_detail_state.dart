part of 'delivery_detail_bloc.dart';

enum DeliveryDetailStatus { initial, loading, loaded, saving, failure }

class DeliveryDetailState extends Equatable {
  const DeliveryDetailState({
    this.status = DeliveryDetailStatus.initial,
    this.delivery,
    this.errorMessage,
    this.successMessage,
  });

  final DeliveryDetailStatus status;
  final Delivery? delivery;
  final String? errorMessage;
  final String? successMessage;

  DeliveryDetailState copyWith({
    DeliveryDetailStatus? status,
    Delivery? delivery,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return DeliveryDetailState(
      status: status ?? this.status,
      delivery: delivery ?? this.delivery,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [status, delivery, errorMessage, successMessage];
}
