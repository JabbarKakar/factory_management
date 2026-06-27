part of 'delivery_list_bloc.dart';

enum DeliveryListStatus { initial, loading, loaded, failure }

class DeliveryListState extends Equatable {
  const DeliveryListState({
    this.status = DeliveryListStatus.initial,
    this.deliveries = const [],
    this.visibleDeliveries = const [],
    this.searchQuery = '',
    this.filter = DeliveryListFilter.active,
    this.errorMessage,
  });

  final DeliveryListStatus status;
  final List<Delivery> deliveries;
  final List<Delivery> visibleDeliveries;
  final String searchQuery;
  final DeliveryListFilter filter;
  final String? errorMessage;

  int get activeCount => deliveries.where((d) => d.status.isActive).length;

  DeliveryListState copyWith({
    DeliveryListStatus? status,
    List<Delivery>? deliveries,
    List<Delivery>? visibleDeliveries,
    String? searchQuery,
    DeliveryListFilter? filter,
    String? errorMessage,
  }) {
    return DeliveryListState(
      status: status ?? this.status,
      deliveries: deliveries ?? this.deliveries,
      visibleDeliveries: visibleDeliveries ?? this.visibleDeliveries,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        deliveries,
        visibleDeliveries,
        searchQuery,
        filter,
        errorMessage,
      ];
}
