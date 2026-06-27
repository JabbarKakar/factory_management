import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/production_repository.dart';
import '../../data/repositories/quality_check_repository.dart';
import '../../domain/entities/production_batch.dart';
import '../../domain/entities/quality_check.dart';
import '../../domain/enums/quality_enums.dart';

part 'production_detail_event.dart';
part 'production_detail_state.dart';

class ProductionDetailBloc
    extends Bloc<ProductionDetailEvent, ProductionDetailState> {
  ProductionDetailBloc({
    required ProductionRepository repository,
    required QualityCheckRepository qualityCheckRepository,
  })  : _repository = repository,
        _qualityCheckRepository = qualityCheckRepository,
        super(const ProductionDetailState()) {
    on<ProductionDetailWatchStarted>(_onWatchStarted);
    on<_ProductionDetailUpdated>(_onUpdated);
    on<_ProductionDetailQcUpdated>(_onQcUpdated);
    on<_ProductionDetailStreamFailed>(_onStreamFailed);
  }

  final ProductionRepository _repository;
  final QualityCheckRepository _qualityCheckRepository;
  StreamSubscription<ProductionBatch?>? _subscription;
  StreamSubscription<List<QualityCheck>>? _qcSubscription;

  Future<void> _onWatchStarted(
    ProductionDetailWatchStarted event,
    Emitter<ProductionDetailState> emit,
  ) async {
    emit(state.copyWith(status: ProductionDetailStatus.loading));
    await _subscription?.cancel();
    await _qcSubscription?.cancel();

    _subscription = _repository.watchBatch(event.batchId).listen(
          (batch) => add(_ProductionDetailUpdated(batch)),
          onError: (_) => add(
            const _ProductionDetailStreamFailed(
              'Could not load production batch.',
            ),
          ),
        );

    _qcSubscription = _qualityCheckRepository
        .watchQualityChecksForReference(
          referenceType: QcReferenceType.production,
          referenceId: event.batchId,
        )
        .listen(
          (checks) => add(_ProductionDetailQcUpdated(checks)),
          onError: (_) => add(
            const _ProductionDetailStreamFailed(
              'Could not load quality inspections.',
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

  void _onQcUpdated(
    _ProductionDetailQcUpdated event,
    Emitter<ProductionDetailState> emit,
  ) {
    emit(
      state.copyWith(
        qualityChecks: event.checks,
        status: state.batch != null
            ? ProductionDetailStatus.loaded
            : state.status,
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
    _qcSubscription?.cancel();
    return super.close();
  }
}
