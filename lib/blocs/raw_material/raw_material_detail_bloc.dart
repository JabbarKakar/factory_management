import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/raw_material_repository.dart';
import '../../domain/entities/raw_material.dart';
import '../../domain/entities/stock_transaction.dart';
import '../../domain/enums/raw_material_enums.dart';

part 'raw_material_detail_event.dart';
part 'raw_material_detail_state.dart';

class RawMaterialDetailBloc
    extends Bloc<RawMaterialDetailEvent, RawMaterialDetailState> {
  RawMaterialDetailBloc({required RawMaterialRepository repository})
      : _repository = repository,
        super(RawMaterialDetailState()) {
    on<RawMaterialDetailWatchStarted>(_onWatchStarted);
    on<RawMaterialDetailWatchStopped>(_onWatchStopped);
    on<RawMaterialReorderLevelUpdated>(_onReorderLevelUpdated);
    on<_RawMaterialDetailDataUpdated>(_onDataUpdated);
    on<_RawMaterialDetailStreamFailed>(_onStreamFailed);
  }

  final RawMaterialRepository _repository;
  StreamSubscription<List<RawMaterial>>? _materialsSub;
  StreamSubscription<List<StockTransaction>>? _transactionsSub;

  String? _factoryId;
  RawMaterialType? _materialType;
  List<RawMaterial> _materials = const [];
  List<StockTransaction> _transactions = const [];

  Future<void> _onWatchStarted(
    RawMaterialDetailWatchStarted event,
    Emitter<RawMaterialDetailState> emit,
  ) async {
    _factoryId = event.factoryId;
    _materialType = event.materialType;
    emit(
      state.copyWith(
        status: RawMaterialDetailStatus.loading,
        material: RawMaterial.placeholder(
          factoryId: event.factoryId,
          materialType: event.materialType,
        ),
      ),
    );
    await _cancelSubscriptions();

    _materialsSub = _repository.watchMaterials(event.factoryId).listen(
          (materials) {
            _materials = materials;
            add(const _RawMaterialDetailDataUpdated());
          },
          onError: (_) => add(
            const _RawMaterialDetailStreamFailed(
              'Could not load material stock.',
            ),
          ),
        );

    _transactionsSub = _repository.watchTransactions(event.factoryId).listen(
          (transactions) {
            _transactions = transactions;
            add(const _RawMaterialDetailDataUpdated());
          },
          onError: (_) => add(
            const _RawMaterialDetailStreamFailed(
              'Could not load stock history.',
            ),
          ),
        );
  }

  Future<void> _onWatchStopped(
    RawMaterialDetailWatchStopped event,
    Emitter<RawMaterialDetailState> emit,
  ) async {
    await _cancelSubscriptions();
  }

  Future<void> _onReorderLevelUpdated(
    RawMaterialReorderLevelUpdated event,
    Emitter<RawMaterialDetailState> emit,
  ) async {
    final material = state.material;
    if (material.id.isEmpty) {
      emit(
        state.copyWith(
          status: RawMaterialDetailStatus.failure,
          errorMessage: 'Record stock in first before setting a reorder level.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: RawMaterialDetailStatus.saving));
    try {
      await _repository.updateReorderLevel(
        materialId: material.id,
        reorderLevel: event.reorderLevel,
      );
      emit(state.copyWith(status: RawMaterialDetailStatus.loaded, errorMessage: null));
    } catch (_) {
      emit(
        state.copyWith(
          status: RawMaterialDetailStatus.failure,
          errorMessage: 'Could not update reorder level.',
        ),
      );
    }
  }

  void _onDataUpdated(
    _RawMaterialDetailDataUpdated event,
    Emitter<RawMaterialDetailState> emit,
  ) {
    final factoryId = _factoryId;
    final materialType = _materialType;
    if (factoryId == null || materialType == null) return;

    RawMaterial? matched;
    for (final material in _materials) {
      if (material.materialType == materialType) {
        matched = material;
        break;
      }
    }

    final material = matched ??
        RawMaterial.placeholder(factoryId: factoryId, materialType: materialType);

    final transactions = _transactions
        .where((transaction) => transaction.materialType == materialType)
        .toList();

    emit(
      state.copyWith(
        status: RawMaterialDetailStatus.loaded,
        material: material,
        transactions: transactions,
        errorMessage: null,
      ),
    );
  }

  void _onStreamFailed(
    _RawMaterialDetailStreamFailed event,
    Emitter<RawMaterialDetailState> emit,
  ) {
    emit(
      state.copyWith(
        status: RawMaterialDetailStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  Future<void> _cancelSubscriptions() async {
    await _materialsSub?.cancel();
    await _transactionsSub?.cancel();
    _materialsSub = null;
    _transactionsSub = null;
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}

final class _RawMaterialDetailDataUpdated extends RawMaterialDetailEvent {
  const _RawMaterialDetailDataUpdated();
}

final class _RawMaterialDetailStreamFailed extends RawMaterialDetailEvent {
  const _RawMaterialDetailStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
