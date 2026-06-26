import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/job_work_repository.dart';
import '../../domain/entities/job_work_order.dart';

part 'job_work_output_event.dart';
part 'job_work_output_state.dart';

class JobWorkOutputBloc extends Bloc<JobWorkOutputEvent, JobWorkOutputState> {
  JobWorkOutputBloc({required JobWorkRepository repository})
      : _repository = repository,
        super(const JobWorkOutputState()) {
    on<JobWorkOutputLoadRequested>(_onLoadRequested);
    on<JobWorkOutputSubmitted>(_onSubmitted);
  }

  final JobWorkRepository _repository;

  Future<void> _onLoadRequested(
    JobWorkOutputLoadRequested event,
    Emitter<JobWorkOutputState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkOutputStatus.loading));
    try {
      final order = await _repository.getJobWorkOrder(event.jobWorkId);
      if (order == null) {
        emit(
          state.copyWith(
            status: JobWorkOutputStatus.failure,
            errorMessage: 'Job work order not found.',
          ),
        );
        return;
      }

      if (!order.status.canRecordOutput) {
        emit(
          state.copyWith(
            status: JobWorkOutputStatus.failure,
            errorMessage: 'Output cannot be recorded for this order status.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: JobWorkOutputStatus.ready,
          order: order,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkOutputStatus.failure,
          errorMessage: 'Could not load job work order.',
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    JobWorkOutputSubmitted event,
    Emitter<JobWorkOutputState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkOutputStatus.saving));
    try {
      final saved = await _repository.recordJobWorkOutput(event.order);
      emit(
        state.copyWith(
          status: JobWorkOutputStatus.saved,
          order: saved,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkOutputStatus.failure,
          errorMessage: 'Could not save output recording.',
        ),
      );
    }
  }
}
