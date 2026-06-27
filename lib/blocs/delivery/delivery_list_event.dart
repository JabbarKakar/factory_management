part of 'delivery_list_bloc.dart';

sealed class DeliveryListEvent extends Equatable {
  const DeliveryListEvent();

  @override
  List<Object?> get props => [];
}

final class DeliveryListWatchStarted extends DeliveryListEvent {
  const DeliveryListWatchStarted(this.factoryId, {this.initialFilter});

  final String factoryId;
  final DeliveryListFilter? initialFilter;

  @override
  List<Object?> get props => [factoryId, initialFilter];
}

final class DeliveryListWatchStopped extends DeliveryListEvent {
  const DeliveryListWatchStopped();
}

final class DeliveryListSearchChanged extends DeliveryListEvent {
  const DeliveryListSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class DeliveryListFilterChanged extends DeliveryListEvent {
  const DeliveryListFilterChanged(this.filter);

  final DeliveryListFilter filter;

  @override
  List<Object?> get props => [filter];
}
