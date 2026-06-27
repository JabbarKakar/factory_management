import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/job_work_repository.dart';
import '../../data/repositories/quality_check_repository.dart';
import '../../data/services/operational_alert_scanner_service.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/production_batch.dart';
import '../../domain/entities/quality_check.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/quality_enums.dart';

part 'qc_form_event.dart';
part 'qc_form_state.dart';

class QcFormBloc extends Bloc<QcFormEvent, QcFormState> {
  QcFormBloc({
    required QualityCheckRepository repository,
    required JobWorkRepository jobWorkRepository,
    required OperationalAlertScannerService operationalAlertScannerService,
  })  : _repository = repository,
        _jobWorkRepository = jobWorkRepository,
        _operationalAlertScannerService = operationalAlertScannerService,
        super(const QcFormState()) {
    on<QcFormInitialized>(_onInitialized);
    on<QcFormReferenceTypeChanged>(_onReferenceTypeChanged);
    on<QcFormReferenceSelected>(_onReferenceSelected);
    on<QcFormSubmitted>(_onSubmitted);
    on<QcFormMarkReadyConfirmed>(_onMarkReadyConfirmed);
  }

  final QualityCheckRepository _repository;
  final JobWorkRepository _jobWorkRepository;
  final OperationalAlertScannerService _operationalAlertScannerService;

  Future<void> _onInitialized(
    QcFormInitialized event,
    Emitter<QcFormState> emit,
  ) async {
    emit(state.copyWith(status: QcFormStatus.loading, clearWorkflow: true));
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
        clearWorkflow: true,
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
      clearWorkflow: true,
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
      final sizeLabel = order.sizes.isEmpty ? null : order.sizes.join(', ');
      return current.copyWith(
        prefill: QcFormPrefill(
          productLabel: order.targetProduct.label,
          marbleVariety: order.marbleVariety,
          sizeThickness: sizeLabel == null
              ? order.thickness
              : '$sizeLabel · ${order.thickness}',
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
    emit(state.copyWith(status: QcFormStatus.saving, clearWorkflow: true));
    try {
      final created = await _repository.createQualityCheck(event.check);
      await _operationalAlertScannerService.notifyQcReject(created);

      String? pendingMarkReadyJobWorkId;
      var advancedToQc = false;

      if (event.check.referenceType == QcReferenceType.jobWork &&
          event.check.disposition == QcDisposition.pass) {
        final order =
            await _jobWorkRepository.getJobWorkOrder(event.check.referenceId);
        if (order != null) {
          if (order.status == JobWorkStatus.qc) {
            pendingMarkReadyJobWorkId = order.id;
          } else if (order.status == JobWorkStatus.inCutting ||
              order.status == JobWorkStatus.agreed) {
            await _jobWorkRepository.advanceJobWorkStatus(
              order.id,
              JobWorkStatus.qc,
            );
            advancedToQc = true;
          }
        }
      }

      emit(
        state.copyWith(
          status: QcFormStatus.saved,
          pendingMarkReadyJobWorkId: pendingMarkReadyJobWorkId,
          advancedToQc: advancedToQc,
        ),
      );
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

  Future<void> _onMarkReadyConfirmed(
    QcFormMarkReadyConfirmed event,
    Emitter<QcFormState> emit,
  ) async {
    final jobWorkId = state.pendingMarkReadyJobWorkId;
    if (jobWorkId == null) return;

    try {
      await _jobWorkRepository.advanceJobWorkStatus(
        jobWorkId,
        JobWorkStatus.ready,
      );
      emit(
        state.copyWith(
          clearPendingMarkReady: true,
          markedReady: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: QcFormStatus.failure,
          errorMessage: 'Could not mark job work order as ready.',
          clearPendingMarkReady: true,
        ),
      );
    }
  }
}
