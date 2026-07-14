import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../core/constants/job_work_sizes.dart';
import '../../data/repositories/job_work_load_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/repositories/quality_check_repository.dart';
import '../../data/services/operational_alert_scanner_service.dart';
import '../../domain/entities/job_work_load.dart';
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
    required JobWorkLoadRepository loadRepository,
    required OperationalAlertScannerService operationalAlertScannerService,
  })  : _repository = repository,
        _jobWorkRepository = jobWorkRepository,
        _loadRepository = loadRepository,
        _operationalAlertScannerService = operationalAlertScannerService,
        super(const QcFormState()) {
    on<QcFormInitialized>(_onInitialized);
    on<QcFormLoadRequested>(_onLoadRequested);
    on<QcFormReferenceTypeChanged>(_onReferenceTypeChanged);
    on<QcFormReferenceSelected>(_onReferenceSelected);
    on<QcFormSubmitted>(_onSubmitted);
    on<QcFormMarkReadyConfirmed>(_onMarkReadyConfirmed);
  }

  final QualityCheckRepository _repository;
  final JobWorkRepository _jobWorkRepository;
  final JobWorkLoadRepository _loadRepository;
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
      JobWorkLoad? selectedLoad;

      if (event.referenceId != null) {
        if (referenceType == QcReferenceType.production) {
          final matches = productionBatches
              .where((batch) => batch.id == event.referenceId);
          selectedBatch = matches.isEmpty ? null : matches.first;
        } else if (referenceType == QcReferenceType.jobWorkLoad) {
          selectedLoad = await _loadRepository.getLoad(event.referenceId!);
          if (selectedLoad != null) {
            selectedOrder = await _jobWorkRepository.getJobWorkOrder(
              selectedLoad.jobWorkId,
            );
          }
        } else {
          final matches =
              jobWorkOrders.where((order) => order.id == event.referenceId);
          selectedOrder = matches.isEmpty ? null : matches.first;
        }
        if (selectedBatch == null &&
            selectedOrder == null &&
            selectedLoad == null) {
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
        selectedLoad: selectedLoad,
      );
      emit(nextState);

      if (selectedBatch != null ||
          selectedOrder != null ||
          selectedLoad != null) {
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

  Future<void> _onLoadRequested(
    QcFormLoadRequested event,
    Emitter<QcFormState> emit,
  ) async {
    emit(state.copyWith(status: QcFormStatus.loading, isEditing: true));
    try {
      final check = await _repository.getQualityCheck(event.qcId);
      if (check == null) {
        emit(
          state.copyWith(
            status: QcFormStatus.failure,
            errorMessage: 'Quality inspection not found.',
          ),
        );
        return;
      }

      var productionBatches =
          await _repository.fetchEligibleProductionBatches(check.factoryId);
      var jobWorkOrders =
          await _repository.fetchEligibleJobWorkOrders(check.factoryId);

      ProductionBatch? selectedBatch;
      JobWorkOrder? selectedOrder;
      JobWorkLoad? selectedLoad;

      if (check.referenceType == QcReferenceType.production) {
        for (final batch in productionBatches) {
          if (batch.id == check.referenceId) {
            selectedBatch = batch;
            break;
          }
        }
        selectedBatch ??= await _repository.getProductionBatchReference(
          check.referenceId,
        );
        if (selectedBatch != null &&
            !productionBatches.any((batch) => batch.id == selectedBatch!.id)) {
          productionBatches = [selectedBatch, ...productionBatches];
        }
      } else if (check.referenceType == QcReferenceType.jobWorkLoad) {
        selectedLoad = await _loadRepository.getLoad(check.referenceId);
        if (selectedLoad != null) {
          selectedOrder = await _jobWorkRepository.getJobWorkOrder(
            selectedLoad.jobWorkId,
          );
          if (selectedOrder != null &&
              !jobWorkOrders.any((order) => order.id == selectedOrder!.id)) {
            jobWorkOrders = [selectedOrder, ...jobWorkOrders];
          }
        }
      } else {
        for (final order in jobWorkOrders) {
          if (order.id == check.referenceId) {
            selectedOrder = order;
            break;
          }
        }
        selectedOrder ??= await _repository.getJobWorkReference(
          check.referenceId,
        );
        if (selectedOrder != null &&
            !jobWorkOrders.any((order) => order.id == selectedOrder!.id)) {
          jobWorkOrders = [selectedOrder, ...jobWorkOrders];
        }
      }

      emit(
        QcFormState(
          status: QcFormStatus.ready,
          productionBatches: productionBatches,
          jobWorkOrders: jobWorkOrders,
          referenceType: check.referenceType,
          selectedBatch: selectedBatch,
          selectedOrder: selectedOrder,
          selectedLoad: selectedLoad,
          editingCheck: check,
          isEditing: true,
          prefill: QcFormPrefill(
            productLabel: check.productLabel,
            marbleVariety: check.marbleVariety,
            sizeThickness: check.sizeThickness,
            quantityInspected: check.quantityInspected,
            gradeASqFt: check.gradeASqFt,
            gradeBSqFt: check.gradeBSqFt,
            gradeCSqFt: check.gradeCSqFt,
            rejectSqFt: check.rejectSqFt,
          ),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: QcFormStatus.failure,
          errorMessage: 'Could not load quality inspection.',
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
        clearSelectedLoad: true,
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
      clearSelectedLoad: true,
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

    final load = current.selectedLoad;
    if (load != null) {
      final output = load.output;
      if (output == null) {
        return current.copyWith(prefill: const QcFormPrefill());
      }
      final sizeLabel = load.hasAnySize
          ? JobWorkSizes.joinForDisplay(
              smallSizes: load.smallSizes,
              largeSizes: load.largeSizes,
              legacySizes: load.legacySizes,
            )
          : null;
      return current.copyWith(
        prefill: QcFormPrefill(
          productLabel: load.targetProduct.label,
          marbleVariety: load.marbleVariety,
          sizeThickness: sizeLabel == null
              ? load.thickness
              : '$sizeLabel · ${load.thickness}',
          quantityInspected: output.totalOutputSqFt,
          gradeASqFt: output.hasStockOutputs
              ? output.totalUsableSqFt
              : output.gradeASqFt,
          gradeBSqFt: output.hasStockOutputs ? 0 : output.gradeBSqFt,
          gradeCSqFt: output.hasStockOutputs ? 0 : output.gradeCSqFt,
          rejectSqFt: output.rejectSqFt,
        ),
      );
    }

    final order = current.selectedOrder;
    if (order != null) {
      final output = order.output!;
      final sizeLabel = order.hasAnySize
          ? JobWorkSizes.joinForDisplay(
              smallSizes: order.smallSizes,
              largeSizes: order.largeSizes,
              legacySizes: order.legacySizes,
            )
          : null;
      return current.copyWith(
        prefill: QcFormPrefill(
          productLabel: order.targetProduct.label,
          marbleVariety: order.marbleVariety,
          sizeThickness: sizeLabel == null
              ? order.thickness
              : '$sizeLabel · ${order.thickness}',
          quantityInspected: output.totalOutputSqFt,
          gradeASqFt: output.hasStockOutputs
              ? output.totalUsableSqFt
              : output.gradeASqFt,
          gradeBSqFt: output.hasStockOutputs ? 0 : output.gradeBSqFt,
          gradeCSqFt: output.hasStockOutputs ? 0 : output.gradeCSqFt,
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
      if (state.isEditing) {
        await _repository.updateQualityCheck(event.check);
        emit(
          state.copyWith(
            status: QcFormStatus.saved,
          ),
        );
        return;
      }

      final created = await _repository.createQualityCheck(event.check);
      await _operationalAlertScannerService.notifyQcReject(created);

      String? pendingMarkReadyJobWorkId;
      String? pendingMarkReadyLoadId;
      var advancedToQc = false;

      if (event.check.referenceType == QcReferenceType.jobWorkLoad &&
          event.check.disposition == QcDisposition.pass) {
        final load = await _loadRepository.getLoad(event.check.referenceId);
        if (load != null) {
          if (load.status == JobWorkStatus.qc) {
            pendingMarkReadyLoadId = load.id;
          } else if (load.status == JobWorkStatus.inCutting ||
              load.status == JobWorkStatus.agreed) {
            await _loadRepository.advanceLoadStatus(
              loadId: load.id,
              newStatus: JobWorkStatus.qc,
            );
            advancedToQc = true;
          }
        }
      } else if (event.check.referenceType == QcReferenceType.jobWork &&
          event.check.disposition == QcDisposition.pass) {
        final order =
            await _jobWorkRepository.getJobWorkOrder(event.check.referenceId);
        if (order != null) {
          // Sprint 7: migrated containers — advance the default Load, not JW FSM.
          if (order.isLoadsAuthoritative) {
            final loadId = order.defaultLoadId;
            final load = loadId == null || loadId.isEmpty
                ? null
                : await _loadRepository.getLoad(loadId);
            if (load != null) {
              if (load.status == JobWorkStatus.qc) {
                pendingMarkReadyLoadId = load.id;
              } else if (load.status == JobWorkStatus.inCutting ||
                  load.status == JobWorkStatus.agreed) {
                await _loadRepository.advanceLoadStatus(
                  loadId: load.id,
                  newStatus: JobWorkStatus.qc,
                );
                advancedToQc = true;
              }
            }
          } else if (order.status == JobWorkStatus.qc) {
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
          pendingMarkReadyLoadId: pendingMarkReadyLoadId,
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
    final loadId = state.pendingMarkReadyLoadId;
    if (loadId != null) {
      try {
        await _loadRepository.advanceLoadStatus(
          loadId: loadId,
          newStatus: JobWorkStatus.ready,
        );
        final load = await _loadRepository.getLoad(loadId);
        if (load != null) {
          final order =
              await _jobWorkRepository.getJobWorkOrder(load.jobWorkId);
          if (order != null) {
            await _operationalAlertScannerService.notifyJobWorkReady(
              order,
              load: load,
            );
          }
        }
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
            errorMessage: 'Could not mark job work load as ready.',
            clearPendingMarkReady: true,
          ),
        );
      }
      return;
    }

    final jobWorkId = state.pendingMarkReadyJobWorkId;
    if (jobWorkId == null) return;

    try {
      await _jobWorkRepository.advanceJobWorkStatus(
        jobWorkId,
        JobWorkStatus.ready,
      );
      final order = await _jobWorkRepository.getJobWorkOrder(jobWorkId);
      if (order != null) {
        await _operationalAlertScannerService.notifyJobWorkReady(order);
      }
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
