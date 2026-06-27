part of 'production_list_bloc.dart';

enum ProductionListStatus { initial, loading, loaded, failure }

class ProductionListState extends Equatable {
  const ProductionListState({
    this.status = ProductionListStatus.initial,
    this.batches = const [],
    this.visibleBatches = const [],
    this.searchQuery = '',
    this.filter = ProductionListFilter.all,
    this.monthTotalSqFt = 0,
    this.errorMessage,
  });

  final ProductionListStatus status;
  final List<ProductionBatch> batches;
  final List<ProductionBatch> visibleBatches;
  final String searchQuery;
  final ProductionListFilter filter;
  final double monthTotalSqFt;
  final String? errorMessage;

  ProductionListState copyWith({
    ProductionListStatus? status,
    List<ProductionBatch>? batches,
    List<ProductionBatch>? visibleBatches,
    String? searchQuery,
    ProductionListFilter? filter,
    double? monthTotalSqFt,
    String? errorMessage,
  }) {
    return ProductionListState(
      status: status ?? this.status,
      batches: batches ?? this.batches,
      visibleBatches: visibleBatches ?? this.visibleBatches,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      monthTotalSqFt: monthTotalSqFt ?? this.monthTotalSqFt,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        batches,
        visibleBatches,
        searchQuery,
        filter,
        monthTotalSqFt,
        errorMessage,
      ];
}
