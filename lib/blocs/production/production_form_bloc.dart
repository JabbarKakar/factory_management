import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/production_repository.dart';
import '../../data/repositories/quality_check_repository.dart';
import '../../domain/entities/production_batch.dart';
import '../../domain/enums/production_enums.dart';
import '../../domain/enums/quality_enums.dart';
import '../../domain/enums/raw_material_enums.dart';

part 'production_form_event.dart';
part 'production_form_state.dart';

class ProductionFormBloc extends Bloc<ProductionFormEvent, ProductionFormState> {
  ProductionFormBloc({
    required ProductionRepository repository,
    required QualityCheckRepository qualityCheckRepository,
  })  : _repository = repository,
        _qualityCheckRepository = qualityCheckRepository,
        super(const ProductionFormState()) {
    on<ProductionFormInitialized>(_onInitialized);
    on<ProductionFormLoadRequested>(_onLoadRequested);
    on<ProductionFormSubmitted>(_onSubmitted);
  }

  final ProductionRepository _repository;
  final QualityCheckRepository _qualityCheckRepository;

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

  Future<void> _onLoadRequested(
    ProductionFormLoadRequested event,
    Emitter<ProductionFormState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ProductionFormStatus.loading,
        isEditing: true,
        errorMessage: null,
      ),
    );

    try {
      final batch = await _repository.getBatch(event.batchId);
      if (batch == null) {
        emit(
          state.copyWith(
            status: ProductionFormStatus.failure,
            errorMessage: 'Production batch not found.',
          ),
        );
        return;
      }

      final hasLinkedQc =
          await _qualityCheckRepository.hasQualityChecksForReference(
        factoryId: batch.factoryId,
        referenceType: QcReferenceType.production,
        referenceId: batch.id,
      );

      emit(
        state.copyWith(
          status: ProductionFormStatus.ready,
          factoryId: batch.factoryId,
          batch: batch,
          isEditing: true,
          hasLinkedQc: hasLinkedQc,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProductionFormStatus.failure,
          errorMessage: 'Could not load production batch.',
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    ProductionFormSubmitted event,
    Emitter<ProductionFormState> emit,
  ) async {
    final factoryId = state.factoryId;
    if (factoryId == null) return;

    emit(state.copyWith(status: ProductionFormStatus.saving, errorMessage: null));
    try {
      final ProductionBatch batch;
      if (state.isEditing) {
        final existing = state.batch;
        if (existing == null) return;

        batch = await _repository.updateBatch(
          existing: existing,
          productionDate: event.productionDate,
          shift: event.shift,
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
          inventoryFieldsLocked: state.inventoryFieldsLocked,
        );
      } else {
        batch = await _repository.createBatch(
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
      }

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
          errorMessage: state.isEditing
              ? 'Could not update production batch.'
              : 'Could not save production batch.',
        ),
      );
    }
  }
}
