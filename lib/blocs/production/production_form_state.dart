part of 'production_form_bloc.dart';

enum ProductionFormStatus { initial, loading, ready, saving, saved, failure }

class ProductionFormState extends Equatable {
  const ProductionFormState({
    this.status = ProductionFormStatus.initial,
    this.factoryId,
    this.batch,
    this.isEditing = false,
    this.hasLinkedQc = false,
    this.savedBatchId,
    this.errorMessage,
  });

  final ProductionFormStatus status;
  final String? factoryId;
  final ProductionBatch? batch;
  final bool isEditing;
  final bool hasLinkedQc;
  final String? savedBatchId;
  final String? errorMessage;

  bool get inventoryFieldsLocked => isEditing && hasLinkedQc;

  ProductionFormState copyWith({
    ProductionFormStatus? status,
    String? factoryId,
    ProductionBatch? batch,
    bool? isEditing,
    bool? hasLinkedQc,
    String? savedBatchId,
    String? errorMessage,
  }) {
    return ProductionFormState(
      status: status ?? this.status,
      factoryId: factoryId ?? this.factoryId,
      batch: batch ?? this.batch,
      isEditing: isEditing ?? this.isEditing,
      hasLinkedQc: hasLinkedQc ?? this.hasLinkedQc,
      savedBatchId: savedBatchId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        factoryId,
        batch,
        isEditing,
        hasLinkedQc,
        savedBatchId,
        errorMessage,
      ];
}
