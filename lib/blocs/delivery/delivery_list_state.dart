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
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.hasMoreData = true,
    this.lastDocument,
    this.factoryId = '',
  });

  final DeliveryListStatus status;
  final List<Delivery> deliveries;
  final List<Delivery> visibleDeliveries;
  final String searchQuery;
  final DeliveryListFilter filter;
  final String? errorMessage;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool hasMoreData;
  final DocumentSnapshot? lastDocument;
  final String factoryId;

  int get activeCount => deliveries.where((d) => d.status.isActive).length;

  DeliveryListState copyWith({
    DeliveryListStatus? status,
    List<Delivery>? deliveries,
    List<Delivery>? visibleDeliveries,
    String? searchQuery,
    DeliveryListFilter? filter,
    String? errorMessage,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMoreData,
    DocumentSnapshot? lastDocument,
    bool clearLastDocument = false,
    String? factoryId,
  }) {
    return DeliveryListState(
      status: status ?? this.status,
      deliveries: deliveries ?? this.deliveries,
      visibleDeliveries: visibleDeliveries ?? this.visibleDeliveries,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
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
        deliveries,
        visibleDeliveries,
        searchQuery,
        filter,
        errorMessage,
        isLoadingInitial,
        isLoadingMore,
        hasMoreData,
        lastDocument,
        factoryId,
      ];
}
