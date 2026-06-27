part of 'production_detail_bloc.dart';

enum ProductionDetailStatus { initial, loading, loaded, failure }

class ProductionDetailState extends Equatable {
  const ProductionDetailState({
    this.status = ProductionDetailStatus.initial,
    this.batch,
    this.errorMessage,
  });

  final ProductionDetailStatus status;
  final ProductionBatch? batch;
  final String? errorMessage;

  ProductionDetailState copyWith({
    ProductionDetailStatus? status,
    ProductionBatch? batch,
    String? errorMessage,
  }) {
    return ProductionDetailState(
      status: status ?? this.status,
      batch: batch ?? this.batch,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, batch, errorMessage];
}
