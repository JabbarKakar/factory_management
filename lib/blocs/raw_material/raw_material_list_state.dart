part of 'raw_material_list_bloc.dart';

enum RawMaterialListStatus { initial, loading, loaded, failure }

class RawMaterialListState extends Equatable {
  const RawMaterialListState({
    this.status = RawMaterialListStatus.initial,
    this.materials = const [],
    this.visibleMaterials = const [],
    this.searchQuery = '',
    this.filter = RawMaterialListFilter.all,
    this.lowStockCount = 0,
    this.errorMessage,
  });

  final RawMaterialListStatus status;
  final List<RawMaterial> materials;
  final List<RawMaterial> visibleMaterials;
  final String searchQuery;
  final RawMaterialListFilter filter;
  final int lowStockCount;
  final String? errorMessage;

  RawMaterialListState copyWith({
    RawMaterialListStatus? status,
    List<RawMaterial>? materials,
    List<RawMaterial>? visibleMaterials,
    String? searchQuery,
    RawMaterialListFilter? filter,
    int? lowStockCount,
    String? errorMessage,
  }) {
    return RawMaterialListState(
      status: status ?? this.status,
      materials: materials ?? this.materials,
      visibleMaterials: visibleMaterials ?? this.visibleMaterials,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        materials,
        visibleMaterials,
        searchQuery,
        filter,
        lowStockCount,
        errorMessage,
      ];
}
