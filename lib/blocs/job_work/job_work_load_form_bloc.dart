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
      await _loadRepository.ensureDefaultLoad(event.jobWorkId);
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
      emit(
        state.copyWith(
          status: JobWorkLoadFormStatus.ready,
          parentOrder: order,
          draft: _emptyLoad(order),
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkLoadFormStatus.failure,
          errorMessage: 'Could not prepare add load form.',
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
