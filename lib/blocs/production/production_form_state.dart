part of 'production_form_bloc.dart';

enum ProductionFormStatus { initial, ready, saving, saved, failure }

class ProductionFormState extends Equatable {
  const ProductionFormState({
    this.status = ProductionFormStatus.initial,
    this.factoryId,
    this.savedBatchId,
    this.errorMessage,
  });

  final ProductionFormStatus status;
  final String? factoryId;
  final String? savedBatchId;
  final String? errorMessage;

  ProductionFormState copyWith({
    ProductionFormStatus? status,
    String? factoryId,
    String? savedBatchId,
    String? errorMessage,
  }) {
    return ProductionFormState(
      status: status ?? this.status,
      factoryId: factoryId ?? this.factoryId,
      savedBatchId: savedBatchId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, factoryId, savedBatchId, errorMessage];
}
