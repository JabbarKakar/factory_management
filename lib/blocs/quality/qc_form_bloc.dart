import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/quality_check_repository.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/production_batch.dart';
import '../../domain/entities/quality_check.dart';
import '../../domain/enums/quality_enums.dart';

part 'qc_form_event.dart';
part 'qc_form_state.dart';

class QcFormBloc extends Bloc<QcFormEvent, QcFormState> {
  QcFormBloc({required QualityCheckRepository repository})
      : _repository = repository,
        super(const QcFormState()) {
    on<QcFormInitialized>(_onInitialized);
    on<QcFormReferenceTypeChanged>(_onReferenceTypeChanged);
    on<QcFormReferenceSelected>(_onReferenceSelected);
    on<QcFormSubmitted>(_onSubmitted);
  }

  final QualityCheckRepository _repository;

  Future<void> _onInitialized(
    QcFormInitialized event,
    Emitter<QcFormState> emit,
  ) async {
    emit(state.copyWith(status: QcFormStatus.loading));
    try {
      final productionBatches =
          await _repository.fetchEligibleProductionBatches(event.factoryId);
      final jobWorkOrders =
          await _repository.fetchEligibleJobWorkOrders(event.factoryId);

      var referenceType = event.referenceType ?? QcReferenceType.production;
      ProductionBatch? selectedBatch;
      JobWorkOrder? selectedOrder;

      if (event.referenceId != null) {
        if (referenceType == QcReferenceType.production) {
          final matches = productionBatches
              .where((batch) => batch.id == event.referenceId);
          selectedBatch = matches.isEmpty ? null : matches.first;
        } else {
          final matches =
              jobWorkOrders.where((order) => order.id == event.referenceId);
          selectedOrder = matches.isEmpty ? null : matches.first;
        }
        if (selectedBatch == null && selectedOrder == null) {
          referenceType = event.referenceType ?? QcReferenceType.production;
        }
      }

      var nextState = QcFormState(
        status: QcFormStatus.ready,
        productionBatches: productionBatches,
        jobWorkOrders: jobWorkOrders,
        referenceType: referenceType,
        selectedBatch: selectedBatch,
        selectedOrder: selectedOrder,
      );
      emit(nextState);

      if (selectedBatch != null || selectedOrder != null) {
        nextState = _prefillFromReference(nextState);
        emit(nextState);
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: QcFormStatus.failure,
          errorMessage: 'Could not load QC form data.',
        ),
      );
    }
  }

  void _onReferenceTypeChanged(
    QcFormReferenceTypeChanged event,
    Emitter<QcFormState> emit,
  ) {
    emit(
      state.copyWith(
        referenceType: event.referenceType,
        clearSelectedBatch: true,
        clearSelectedOrder: true,
        prefill: const QcFormPrefill(),
      ),
    );
  }

  void _onReferenceSelected(
    QcFormReferenceSelected event,
    Emitter<QcFormState> emit,
  ) {
    ProductionBatch? batch;
    JobWorkOrder? order;

    if (state.referenceType == QcReferenceType.production) {
      for (final item in state.productionBatches) {
        if (item.id == event.referenceId) {
          batch = item;
          break;
        }
      }
    } else {
      for (final item in state.jobWorkOrders) {
        if (item.id == event.referenceId) {
          order = item;
          break;
        }
      }
    }

    var nextState = state.copyWith(
      selectedBatch: batch,
      clearSelectedBatch: batch == null,
      selectedOrder: order,
      clearSelectedOrder: order == null,
    );
    emit(nextState);

    if (batch != null || order != null) {
      nextState = _prefillFromReference(nextState);
      emit(nextState);
    }
  }

  QcFormState _prefillFromReference(QcFormState current) {
    final batch = current.selectedBatch;
    if (batch != null) {
      final sizeParts = <String>[
        if (batch.size != null && batch.size!.isNotEmpty) batch.size!,
        if (batch.thickness != null && batch.thickness!.isNotEmpty)
          batch.thickness!,
      ];
      return current.copyWith(
        prefill: QcFormPrefill(
          productLabel: batch.productType.label,
          marbleVariety: batch.marbleVariety,
          sizeThickness: sizeParts.isEmpty ? null : sizeParts.join(' · '),
          quantityInspected: batch.totalOutputSqFt,
          gradeASqFt: batch.gradeASqFt,
          gradeBSqFt: batch.gradeBSqFt,
          gradeCSqFt: batch.gradeCSqFt,
          rejectSqFt: batch.rejectSqFt,
        ),
      );
    }

    final order = current.selectedOrder;
    if (order != null) {
      final output = order.output!;
      final sizeLabel =
          order.sizes.isEmpty ? null : order.sizes.join(', ');
      return current.copyWith(
        prefill: QcFormPrefill(
          productLabel: order.targetProduct.label,
          marbleVariety: order.marbleVariety,
          sizeThickness: sizeLabel == null
              ? order.thickness
              : '${sizeLabel} · ${order.thickness}',
          quantityInspected: output.totalOutputSqFt,
          gradeASqFt: output.gradeASqFt,
          gradeBSqFt: output.gradeBSqFt,
          gradeCSqFt: output.gradeCSqFt,
          rejectSqFt: output.rejectSqFt,
        ),
      );
    }

    return current.copyWith(prefill: const QcFormPrefill());
  }

  Future<void> _onSubmitted(
    QcFormSubmitted event,
    Emitter<QcFormState> emit,
  ) async {
    emit(state.copyWith(status: QcFormStatus.saving));
    try {
      await _repository.createQualityCheck(event.check);
      emit(state.copyWith(status: QcFormStatus.saved));
    } on QualityCheckException catch (error) {
      emit(
        state.copyWith(
          status: QcFormStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: QcFormStatus.failure,
          errorMessage: 'Could not save quality check.',
        ),
      );
    }
  }
}
