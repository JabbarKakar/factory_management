import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../core/constants/marble_data.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/enums/customer_enums.dart';
import '../../domain/enums/job_work_enums.dart';

part 'job_work_form_event.dart';
part 'job_work_form_state.dart';

class JobWorkFormBloc extends Bloc<JobWorkFormEvent, JobWorkFormState> {
  JobWorkFormBloc({required JobWorkRepository repository})
      : _repository = repository,
        super(const JobWorkFormState()) {
    on<JobWorkFormInitialized>(_onInitialized);
    on<JobWorkFormLoadRequested>(_onLoadRequested);
    on<JobWorkFormSubmitted>(_onSubmitted);
    on<JobWorkFormCancelRequested>(_onCancelRequested);
  }

  final JobWorkRepository _repository;

  Future<void> _onInitialized(
    JobWorkFormInitialized event,
    Emitter<JobWorkFormState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkFormStatus.loading));
    try {
      final customers =
          await _repository.fetchJobWorkEligibleCustomers(event.factoryId);

      emit(
        JobWorkFormState(
          status: JobWorkFormStatus.ready,
          eligibleCustomers: customers,
          order: _emptyOrder(event.factoryId),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkFormStatus.failure,
          errorMessage: 'Could not load customers for job work.',
        ),
      );
    }
  }

  Future<void> _onLoadRequested(
    JobWorkFormLoadRequested event,
    Emitter<JobWorkFormState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkFormStatus.loading, isEditing: true));
    try {
      final order = await _repository.getJobWorkOrder(event.jobWorkId);
      if (order == null) {
        emit(
          state.copyWith(
            status: JobWorkFormStatus.failure,
            errorMessage: 'Job work order not found.',
          ),
        );
        return;
      }

      final customers =
          await _repository.fetchJobWorkEligibleCustomers(order.factoryId);

      emit(
        state.copyWith(
          status: JobWorkFormStatus.ready,
          order: order,
          eligibleCustomers: customers,
          isEditing: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkFormStatus.failure,
          errorMessage: 'Could not load job work order.',
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    JobWorkFormSubmitted event,
    Emitter<JobWorkFormState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkFormStatus.saving));
    try {
      if (event.order.id.isEmpty) {
        final created = await _repository.createJobWorkOrder(event.order);
        emit(
          state.copyWith(
            status: JobWorkFormStatus.saved,
            order: created,
          ),
        );
      } else {
        await _repository.updateJobWorkOrder(event.order);
        emit(
          state.copyWith(
            status: JobWorkFormStatus.saved,
            order: event.order,
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkFormStatus.failure,
          errorMessage: 'Could not save job work order.',
        ),
      );
    }
  }

  Future<void> _onCancelRequested(
    JobWorkFormCancelRequested event,
    Emitter<JobWorkFormState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkFormStatus.saving));
    try {
      await _repository.cancelJobWorkOrder(event.jobWorkId);
      emit(state.copyWith(status: JobWorkFormStatus.cancelled));
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkFormStatus.failure,
          errorMessage: 'Could not cancel job work order.',
        ),
      );
    }
  }

  JobWorkOrder _emptyOrder(String factoryId) {
    return JobWorkOrder(
      id: '',
      jobWorkNumber: '',
      factoryId: factoryId,
      customerId: '',
      customerName: '',
      status: JobWorkStatus.received,
      receivedDate: DateTime.now(),
      marbleVariety: MarbleData.varieties.first,
      blockCount: 1,
      totalTons: 0,
      cuttingStrategy: CuttingStrategy.gangSaw,
      targetProduct: TargetProduct.slabs,
      sizes: const [],
      thickness: MarbleData.thicknesses[2],
      finish: FinishType.unpolished,
      pricingModel: PricingModel.perTon,
      agreedRate: 0,
      estimatedTotal: 0,
      negotiatedFinalAmount: 0,
      advanceReceived: 0,
      balanceDue: 0,
      paymentTerms: PaymentTerms.cash,
      createdAt: DateTime.now(),
    );
  }
}
