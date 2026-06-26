part of 'supplier_list_bloc.dart';

sealed class SupplierListEvent extends Equatable {
  const SupplierListEvent();

  @override
  List<Object?> get props => [];
}

final class SupplierListWatchStarted extends SupplierListEvent {
  const SupplierListWatchStarted(this.factoryId);

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

final class SupplierListWatchStopped extends SupplierListEvent {
  const SupplierListWatchStopped();
}

final class SupplierListSearchChanged extends SupplierListEvent {
  const SupplierListSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class SupplierListFilterChanged extends SupplierListEvent {
  const SupplierListFilterChanged(this.supplierType);

  final SupplierType? supplierType;

  @override
  List<Object?> get props => [supplierType];
}
