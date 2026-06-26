part of 'supplier_list_bloc.dart';

enum SupplierListStatus { initial, loading, loaded, failure }

class SupplierListState extends Equatable {
  const SupplierListState({
    this.status = SupplierListStatus.initial,
    this.suppliers = const [],
    this.visibleSuppliers = const [],
    this.searchQuery = '',
    this.supplierTypeFilter,
    this.errorMessage,
  });

  final SupplierListStatus status;
  final List<Supplier> suppliers;
  final List<Supplier> visibleSuppliers;
  final String searchQuery;
  final SupplierType? supplierTypeFilter;
  final String? errorMessage;

  SupplierListState copyWith({
    SupplierListStatus? status,
    List<Supplier>? suppliers,
    List<Supplier>? visibleSuppliers,
    String? searchQuery,
    SupplierType? supplierTypeFilter,
    bool clearSupplierTypeFilter = false,
    String? errorMessage,
  }) {
    return SupplierListState(
      status: status ?? this.status,
      suppliers: suppliers ?? this.suppliers,
      visibleSuppliers: visibleSuppliers ?? this.visibleSuppliers,
      searchQuery: searchQuery ?? this.searchQuery,
      supplierTypeFilter: clearSupplierTypeFilter
          ? null
          : (supplierTypeFilter ?? this.supplierTypeFilter),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        suppliers,
        visibleSuppliers,
        searchQuery,
        supplierTypeFilter,
        errorMessage,
      ];
}
