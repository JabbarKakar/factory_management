import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/finished_goods_repository.dart';
import '../../domain/entities/finished_good.dart';
import '../../domain/entities/inventory_transaction.dart';

part 'finished_goods_detail_event.dart';
part 'finished_goods_detail_state.dart';

class FinishedGoodsDetailBloc
    extends Bloc<FinishedGoodsDetailEvent, FinishedGoodsDetailState> {
  FinishedGoodsDetailBloc({required FinishedGoodsRepository repository})
      : _repository = repository,
        super(const FinishedGoodsDetailState()) {
    on<FinishedGoodsDetailWatchStarted>(_onWatchStarted);
    on<FinishedGoodsReorderLevelUpdated>(_onReorderLevelUpdated);
    on<FinishedGoodsLocationUpdated>(_onLocationUpdated);
    on<_FinishedGoodsDetailDataUpdated>(_onDataUpdated);
    on<_FinishedGoodsDetailStreamFailed>(_onStreamFailed);
  }

  final FinishedGoodsRepository _repository;
  StreamSubscription<FinishedGood?>? _itemSub;
  StreamSubscription<List<InventoryTransaction>>? _transactionsSub;

  FinishedGood? _item;
  List<InventoryTransaction> _transactions = const [];

  Future<void> _onWatchStarted(
    FinishedGoodsDetailWatchStarted event,
    Emitter<FinishedGoodsDetailState> emit,
  ) async {
    emit(state.copyWith(status: FinishedGoodsDetailStatus.loading));
    await _cancelSubscriptions();

    _itemSub = _repository.watchFinishedGood(event.finishedGoodId).listen(
          (item) {
            _item = item;
            add(const _FinishedGoodsDetailDataUpdated());
          },
          onError: (_) => add(
            const _FinishedGoodsDetailStreamFailed(
              'Could not load stock item.',
            ),
          ),
        );

    _transactionsSub = _repository
        .watchTransactions(
          factoryId: event.factoryId,
          finishedGoodId: event.finishedGoodId,
        )
        .listen(
          (transactions) {
            _transactions = transactions;
            add(const _FinishedGoodsDetailDataUpdated());
          },
          onError: (_) => add(
            const _FinishedGoodsDetailStreamFailed(
              'Could not load stock history.',
            ),
          ),
        );
  }

  Future<void> _onReorderLevelUpdated(
    FinishedGoodsReorderLevelUpdated event,
    Emitter<FinishedGoodsDetailState> emit,
  ) async {
    final item = state.item;
    if (item == null) return;

    emit(state.copyWith(status: FinishedGoodsDetailStatus.saving));
    try {
      await _repository.updateReorderLevel(
        finishedGoodId: item.id,
        reorderLevel: event.reorderLevel,
      );
      emit(state.copyWith(status: FinishedGoodsDetailStatus.loaded));
    } catch (_) {
      emit(
        state.copyWith(
          status: FinishedGoodsDetailStatus.failure,
          errorMessage: 'Could not update reorder level.',
        ),
      );
    }
  }

  Future<void> _onLocationUpdated(
    FinishedGoodsLocationUpdated event,
    Emitter<FinishedGoodsDetailState> emit,
  ) async {
    final item = state.item;
    if (item == null) return;

    emit(state.copyWith(status: FinishedGoodsDetailStatus.saving));
    try {
      await _repository.updateLocation(
        finishedGoodId: item.id,
        location: event.location,
      );
      emit(state.copyWith(status: FinishedGoodsDetailStatus.loaded));
    } catch (_) {
      emit(
        state.copyWith(
          status: FinishedGoodsDetailStatus.failure,
          errorMessage: 'Could not update location.',
        ),
      );
    }
  }

  void _onDataUpdated(
    _FinishedGoodsDetailDataUpdated event,
    Emitter<FinishedGoodsDetailState> emit,
  ) {
    if (_item == null) {
      emit(
        state.copyWith(
          status: FinishedGoodsDetailStatus.failure,
          errorMessage: 'Stock item not found.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: FinishedGoodsDetailStatus.loaded,
        item: _item,
        transactions: _transactions,
        errorMessage: null,
      ),
    );
  }

  void _onStreamFailed(
    _FinishedGoodsDetailStreamFailed event,
    Emitter<FinishedGoodsDetailState> emit,
  ) {
    emit(
      state.copyWith(
        status: FinishedGoodsDetailStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  Future<void> _cancelSubscriptions() async {
    await _itemSub?.cancel();
    await _transactionsSub?.cancel();
    _itemSub = null;
    _transactionsSub = null;
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
