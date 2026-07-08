import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/raw_material_repository.dart';
import '../../data/services/raw_material_stock_service.dart';
import '../../domain/enums/raw_material_enums.dart';

part 'raw_material_adjustment_event.dart';
part 'raw_material_adjustment_state.dart';

class RawMaterialAdjustmentBloc
    extends Bloc<RawMaterialAdjustmentEvent, RawMaterialAdjustmentState> {
  RawMaterialAdjustmentBloc({required RawMaterialRepository repository})
      : _repository = repository,
        super(const RawMaterialAdjustmentState()) {
    on<RawMaterialAdjustmentInitialized>(_onInitialized);
    on<RawMaterialAdjustmentSubmitted>(_onSubmitted);
  }

  final RawMaterialRepository _repository;

  void _onInitialized(
    RawMaterialAdjustmentInitialized event,
    Emitter<RawMaterialAdjustmentState> emit,
  ) {
    emit(
      RawMaterialAdjustmentState(
        status: RawMaterialAdjustmentStatus.ready,
        factoryId: event.factoryId,
        materialType: event.materialType,
        movementType: event.movementType,
      ),
    );
  }

  Future<void> _onSubmitted(
    RawMaterialAdjustmentSubmitted event,
    Emitter<RawMaterialAdjustmentState> emit,
  ) async {
    final factoryId = state.factoryId;
    final materialType = state.materialType;
    final movementType = state.movementType;

    if (factoryId == null || materialType == null || movementType == null) {
      return;
    }

    emit(state.copyWith(status: RawMaterialAdjustmentStatus.saving));
    try {
      await _repository.recordAdjustment(
        factoryId: factoryId,
        materialType: materialType,
        movementType: movementType,
        quantity: event.quantity,
        transactionDate: event.transactionDate,
        reason: event.reason,
        notes: event.notes,
        unitCost: event.unitCost,
      );
      emit(state.copyWith(status: RawMaterialAdjustmentStatus.saved));
    } on RawMaterialStockException catch (error) {
      emit(
        state.copyWith(
          status: RawMaterialAdjustmentStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: RawMaterialAdjustmentStatus.failure,
          errorMessage: 'Could not record adjustment.',
        ),
      );
    }
  }
}
