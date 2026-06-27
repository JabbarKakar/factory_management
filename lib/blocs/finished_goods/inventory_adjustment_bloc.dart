import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/finished_goods_repository.dart';
import '../../data/services/finished_goods_stock_service.dart';
import '../../domain/enums/inventory_enums.dart';

part 'inventory_adjustment_event.dart';
part 'inventory_adjustment_state.dart';

class InventoryAdjustmentBloc
    extends Bloc<InventoryAdjustmentEvent, InventoryAdjustmentState> {
  InventoryAdjustmentBloc({required FinishedGoodsRepository repository})
      : _repository = repository,
        super(const InventoryAdjustmentState()) {
    on<InventoryAdjustmentInitialized>(_onInitialized);
    on<InventoryAdjustmentSubmitted>(_onSubmitted);
  }

  final FinishedGoodsRepository _repository;

  void _onInitialized(
    InventoryAdjustmentInitialized event,
    Emitter<InventoryAdjustmentState> emit,
  ) {
    emit(
      InventoryAdjustmentState(
        status: InventoryAdjustmentStatus.ready,
        factoryId: event.factoryId,
        finishedGoodId: event.finishedGoodId,
        movementType: event.movementType,
      ),
    );
  }

  Future<void> _onSubmitted(
    InventoryAdjustmentSubmitted event,
    Emitter<InventoryAdjustmentState> emit,
  ) async {
    final factoryId = state.factoryId;
    final finishedGoodId = state.finishedGoodId;
    final movementType = state.movementType;

    if (factoryId == null ||
        finishedGoodId == null ||
        movementType == null ||
        movementType == InventoryMovementType.productionIn) {
      return;
    }

    emit(state.copyWith(status: InventoryAdjustmentStatus.saving));
    try {
      await _repository.recordAdjustment(
        factoryId: factoryId,
        finishedGoodId: finishedGoodId,
        movementType: movementType,
        quantity: event.quantity,
        transactionDate: event.transactionDate,
        reason: event.reason,
        notes: event.notes,
      );
      emit(state.copyWith(status: InventoryAdjustmentStatus.saved));
    } on FinishedGoodsStockException catch (error) {
      emit(
        state.copyWith(
          status: InventoryAdjustmentStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: InventoryAdjustmentStatus.failure,
          errorMessage: 'Could not record adjustment.',
        ),
      );
    }
  }
}
