part of 'raw_material_list_bloc.dart';

sealed class RawMaterialListEvent extends Equatable {
  const RawMaterialListEvent();

  @override
  List<Object?> get props => [];
}

final class RawMaterialListWatchStarted extends RawMaterialListEvent {
  const RawMaterialListWatchStarted(this.factoryId);

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

final class RawMaterialListWatchStopped extends RawMaterialListEvent {
  const RawMaterialListWatchStopped();
}

final class RawMaterialListSearchChanged extends RawMaterialListEvent {
  const RawMaterialListSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class RawMaterialListFilterChanged extends RawMaterialListEvent {
  const RawMaterialListFilterChanged(this.filter);

  final RawMaterialListFilter filter;

  @override
  List<Object?> get props => [filter];
}
