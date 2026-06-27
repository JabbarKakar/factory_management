import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/production_repository.dart';
import '../../domain/entities/production_batch.dart';

part 'production_detail_event.dart';
part 'production_detail_state.dart';

class ProductionDetailBloc
    extends Bloc<ProductionDetailEvent, ProductionDetailState> {
  ProductionDetailBloc({required ProductionRepository repository})
      : _repository = repository,
        super(const ProductionDetailState()) {
    on<ProductionDetailWatchStarted>(_onWatchStarted);
    on<_ProductionDetailUpdated>(_onUpdated);
    on<_ProductionDetailStreamFailed>(_onStreamFailed);
  }

  final ProductionRepository _repository;
  StreamSubscription<ProductionBatch?>? _subscription;

  Future<void> _onWatchStarted(
    ProductionDetailWatchStarted event,
    Emitter<ProductionDetailState> emit,
  ) async {
    emit(state.copyWith(status: ProductionDetailStatus.loading));
    await _subscription?.cancel();
    _subscription = _repository.watchBatch(event.batchId).listen(
          (batch) => add(_ProductionDetailUpdated(batch)),
          onError: (_) => add(
            const _ProductionDetailStreamFailed(
              'Could not load production batch.',
            ),
          ),
        );
  }

  void _onUpdated(
    _ProductionDetailUpdated event,
    Emitter<ProductionDetailState> emit,
  ) {
    if (event.batch == null) {
      emit(
        state.copyWith(
          status: ProductionDetailStatus.failure,
          batch: null,
          errorMessage: 'Production batch not found.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ProductionDetailStatus.loaded,
        batch: event.batch,
        errorMessage: null,
      ),
    );
  }

  void _onStreamFailed(
    _ProductionDetailStreamFailed event,
    Emitter<ProductionDetailState> emit,
  ) {
    emit(
      state.copyWith(
        status: ProductionDetailStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
