import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/production_repository.dart';
import '../../domain/enums/production_enums.dart';
import '../../domain/enums/raw_material_enums.dart';

part 'production_form_event.dart';
part 'production_form_state.dart';

class ProductionFormBloc extends Bloc<ProductionFormEvent, ProductionFormState> {
  ProductionFormBloc({required ProductionRepository repository})
      : _repository = repository,
        super(const ProductionFormState()) {
    on<ProductionFormInitialized>(_onInitialized);
    on<ProductionFormSubmitted>(_onSubmitted);
  }

  final ProductionRepository _repository;

  void _onInitialized(
    ProductionFormInitialized event,
    Emitter<ProductionFormState> emit,
  ) {
    emit(
      state.copyWith(
        status: ProductionFormStatus.ready,
        factoryId: event.factoryId,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onSubmitted(
    ProductionFormSubmitted event,
    Emitter<ProductionFormState> emit,
  ) async {
    final factoryId = state.factoryId;
    if (factoryId == null) return;

    emit(state.copyWith(status: ProductionFormStatus.saving, errorMessage: null));
    try {
      final batch = await _repository.createBatch(
        factoryId: factoryId,
        productionDate: event.productionDate,
        shift: event.shift,
        rawMaterialType: event.rawMaterialType,
        materialConsumed: event.materialConsumed,
        productType: event.productType,
        marbleVariety: event.marbleVariety,
        gradeASqFt: event.gradeASqFt,
        gradeBSqFt: event.gradeBSqFt,
        gradeCSqFt: event.gradeCSqFt,
        rejectSqFt: event.rejectSqFt,
        thickness: event.thickness,
        size: event.size,
        wasteTons: event.wasteTons,
        supervisorName: event.supervisorName,
        notes: event.notes,
      );

      emit(
        state.copyWith(
          status: ProductionFormStatus.saved,
          savedBatchId: batch.id,
          errorMessage: null,
        ),
      );
    } on ProductionBatchException catch (error) {
      emit(
        state.copyWith(
          status: ProductionFormStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProductionFormStatus.failure,
          errorMessage: 'Could not save production batch.',
        ),
      );
    }
  }
}
