part of 'raw_material_detail_bloc.dart';

enum RawMaterialDetailStatus { initial, loading, loaded, saving, failure }

class RawMaterialDetailState extends Equatable {
  RawMaterialDetailState({
    this.status = RawMaterialDetailStatus.initial,
    RawMaterial? material,
    this.transactions = const [],
    this.errorMessage,
  }) : material = material ??
            RawMaterial.placeholder(
              factoryId: '',
              materialType: RawMaterialType.marbleBlocks,
            );

  final RawMaterialDetailStatus status;
  final RawMaterial material;
  final List<StockTransaction> transactions;
  final String? errorMessage;

  RawMaterialDetailState copyWith({
    RawMaterialDetailStatus? status,
    RawMaterial? material,
    List<StockTransaction>? transactions,
    String? errorMessage,
  }) {
    return RawMaterialDetailState(
      status: status ?? this.status,
      material: material ?? this.material,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, material, transactions, errorMessage];
}
