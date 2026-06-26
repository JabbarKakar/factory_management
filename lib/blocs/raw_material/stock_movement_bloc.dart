import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/raw_material_repository.dart';
import '../../data/services/raw_material_stock_service.dart';
import '../../domain/enums/raw_material_enums.dart';

part 'stock_movement_event.dart';
part 'stock_movement_state.dart';

class StockMovementBloc extends Bloc<StockMovementEvent, StockMovementState> {
  StockMovementBloc({required RawMaterialRepository repository})
      : _repository = repository,
        super(const StockMovementState()) {
    on<StockMovementInitialized>(_onInitialized);
    on<StockMovementSubmitted>(_onSubmitted);
  }

  final RawMaterialRepository _repository;

  void _onInitialized(
    StockMovementInitialized event,
    Emitter<StockMovementState> emit,
  ) {
    emit(
      StockMovementState(
        status: StockMovementStatus.ready,
        factoryId: event.factoryId,
        materialType: event.materialType,
        movementType: event.movementType,
      ),
    );
  }

  Future<void> _onSubmitted(
    StockMovementSubmitted event,
    Emitter<StockMovementState> emit,
  ) async {
    final factoryId = state.factoryId;
    final materialType = state.materialType;
    final movementType = state.movementType;

    if (factoryId == null || materialType == null || movementType == null) {
      return;
    }

    emit(state.copyWith(status: StockMovementStatus.saving));
    try {
      if (movementType == StockMovementType.stockIn) {
        await _repository.recordStockIn(
          factoryId: factoryId,
          materialType: materialType,
          quantity: event.quantity,
          unitCost: event.unitCost ?? 0,
          transactionDate: event.transactionDate,
          supplierId: event.supplierId,
          referenceNumber: event.referenceNumber,
          notes: event.notes,
        );
      } else {
        await _repository.recordStockOut(
          factoryId: factoryId,
          materialType: materialType,
          quantity: event.quantity,
          transactionDate: event.transactionDate,
          notes: event.notes,
        );
      }

      emit(state.copyWith(status: StockMovementStatus.saved, errorMessage: null));
    } on RawMaterialStockException catch (error) {
      emit(
        state.copyWith(
          status: StockMovementStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: StockMovementStatus.failure,
          errorMessage: 'Could not record stock movement.',
        ),
      );
    }
  }
}
