part of 'supplier_form_bloc.dart';

sealed class SupplierFormEvent extends Equatable {
  const SupplierFormEvent();

  @override
  List<Object?> get props => [];
}

final class SupplierFormInitialized extends SupplierFormEvent {
  const SupplierFormInitialized({required this.factoryId});

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

final class SupplierFormLoadRequested extends SupplierFormEvent {
  const SupplierFormLoadRequested(this.supplierId);

  final String supplierId;

  @override
  List<Object?> get props => [supplierId];
}

final class SupplierFormSubmitted extends SupplierFormEvent {
  const SupplierFormSubmitted(this.supplier);

  final Supplier supplier;

  @override
  List<Object?> get props => [supplier];
}

final class SupplierFormDeleteRequested extends SupplierFormEvent {
  const SupplierFormDeleteRequested(this.supplierId);

  final String supplierId;

  @override
  List<Object?> get props => [supplierId];
}
