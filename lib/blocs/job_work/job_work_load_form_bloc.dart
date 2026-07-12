import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/job_work_load_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/enums/job_work_enums.dart';

part 'job_work_load_form_event.dart';
part 'job_work_load_form_state.dart';

class JobWorkLoadFormBloc
    extends Bloc<JobWorkLoadFormEvent, JobWorkLoadFormState> {
  JobWorkLoadFormBloc({
    required JobWorkRepository jobWorkRepository,
    required JobWorkLoadRepository loadRepository,
  })  : _jobWorkRepository = jobWorkRepository,
        _loadRepository = loadRepository,
        super(const JobWorkLoadFormState()) {
    on<JobWorkLoadFormInitialized>(_onInitialized);
    on<JobWorkLoadFormSubmitted>(_onSubmitted);
  }

  final JobWorkRepository _jobWorkRepository;
  final JobWorkLoadRepository _loadRepository;

  Future<void> _onInitialized(
    JobWorkLoadFormInitialized event,
    Emitter<JobWorkLoadFormState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkLoadFormStatus.loading));
    try {
      final order = await _jobWorkRepository.getJobWorkOrder(event.jobWorkId);
      if (order == null) {
        emit(
          state.copyWith(
            status: JobWorkLoadFormStatus.failure,
            errorMessage: 'Job work order not found.',
          ),
        );
        return;
      }

      final loadId = event.loadId;
      if (loadId != null && loadId.isNotEmpty) {
        final load = await _loadRepository.getLoad(loadId);
        if (load == null ||
            load.jobWorkId != order.id ||
            load.isVirtual) {
          emit(
            state.copyWith(
              status: JobWorkLoadFormStatus.failure,
              errorMessage: 'Load not found.',
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            status: JobWorkLoadFormStatus.ready,
            parentOrder: order,
            draft: load,
            isEditing: true,
            clearError: true,
          ),
        );
        return;
      }

      await _loadRepository.ensureDefaultLoad(event.jobWorkId);
      emit(
        state.copyWith(
          status: JobWorkLoadFormStatus.ready,
          parentOrder: order,
          draft: _emptyLoad(order),
          isEditing: false,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkLoadFormStatus.failure,
          errorMessage: 'Could not prepare load form.',
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    JobWorkLoadFormSubmitted event,
    Emitter<JobWorkLoadFormState> emit,
  ) async {
    final parent = state.parentOrder;
    if (parent == null) {
      emit(
        state.copyWith(
          status: JobWorkLoadFormStatus.failure,
          errorMessage: 'Job work order not found.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(status: JobWorkLoadFormStatus.saving, clearError: true),
    );
    try {
      if (state.isEditing) {
        final existing = state.draft;
        if (existing == null || existing.id.isEmpty) {
          emit(
            state.copyWith(
              status: JobWorkLoadFormStatus.failure,
              errorMessage: 'Load not found.',
            ),
          );
          return;
        }
        final updated = await _loadRepository.updateLoad(
          event.load.copyWith(
            id: existing.id,
            loadNumber: existing.loadNumber,
            loadSequence: existing.loadSequence,
            jobWorkId: parent.id,
            jobWorkNumber: parent.jobWorkNumber,
            factoryId: parent.factoryId,
            customerId: parent.customerId,
            customerName: parent.customerName,
            status: existing.status,
            output: existing.output,
            shiftLogs: existing.shiftLogs,
            execution: existing.execution,
            finalCuttingCharges: existing.finalCuttingCharges,
            balanceDue: existing.balanceDue,
            invoiceId: existing.invoiceId,
            isVirtual: false,
            migratedFromJobWork: existing.migratedFromJobWork,
            createdAt: existing.createdAt,
            collectedAt: existing.collectedAt,
            closedAt: existing.closedAt,
          ),
        );
        emit(
          state.copyWith(
            status: JobWorkLoadFormStatus.saved,
            draft: updated,
          ),
        );
        return;
      }

      final created = await _loadRepository.createLoad(
        event.load.copyWith(
          id: '',
          loadNumber: '',
          loadSequence: 0,
          jobWorkId: parent.id,
          jobWorkNumber: parent.jobWorkNumber,
          factoryId: parent.factoryId,
          customerId: parent.customerId,
          customerName: parent.customerName,
          isVirtual: false,
          migratedFromJobWork: false,
        ),
      );
      emit(
        state.copyWith(
          status: JobWorkLoadFormStatus.saved,
          draft: created,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkLoadFormStatus.failure,
          errorMessage: 'Could not save load.',
        ),
      );
    }
  }

  JobWorkLoad _emptyLoad(JobWorkOrder order) {
    return JobWorkLoad(
      id: '',
      loadNumber: '',
      loadSequence: 0,
      jobWorkId: order.id,
      jobWorkNumber: order.jobWorkNumber,
      factoryId: order.factoryId,
      customerId: order.customerId,
      customerName: order.customerName,
      status: JobWorkStatus.agreed,
      receivedDate: DateTime.now(),
      mineLocation: order.mineLocation,
      mineOwner: order.mineOwner,
      marbleVariety: order.marbleVariety,
      blockCount: 1,
      totalTons: 0,
      cuttingStrategy: order.cuttingStrategy,
      targetProduct: order.targetProduct,
      smallSizes: order.smallSizes,
      largeSizes: order.largeSizes,
      thickness: order.thickness,
      finish: order.finish,
      pricingModel: order.pricingModel,
      agreedRate: order.agreedRate,
      smallStockPrice: order.smallStockPrice,
      largeStockPrice: order.largeStockPrice,
      advanceReceived: 0,
      balanceDue: 0,
      paymentTerms: order.paymentTerms,
      createdAt: DateTime.now(),
    );
  }
}
