import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/job_work_load_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/services/job_work_load_resolver.dart';
import '../../domain/entities/job_work_load.dart';

part 'job_work_output_event.dart';
part 'job_work_output_state.dart';

class JobWorkOutputBloc extends Bloc<JobWorkOutputEvent, JobWorkOutputState> {
  JobWorkOutputBloc({
    required JobWorkRepository repository,
    required JobWorkLoadRepository loadRepository,
  })  : _repository = repository,
        _loadRepository = loadRepository,
        super(const JobWorkOutputState()) {
    on<JobWorkOutputLoadRequested>(_onLoadRequested);
    on<JobWorkOutputSubmitted>(_onSubmitted);
  }

  final JobWorkRepository _repository;
  final JobWorkLoadRepository _loadRepository;

  Future<void> _onLoadRequested(
    JobWorkOutputLoadRequested event,
    Emitter<JobWorkOutputState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkOutputStatus.loading));
    try {
      final load = await _resolveLoad(event);
      if (load == null) {
        emit(
          state.copyWith(
            status: JobWorkOutputStatus.failure,
            errorMessage: 'Load not found.',
          ),
        );
        return;
      }

      if (!load.status.canRecordOutput) {
        emit(
          state.copyWith(
            status: JobWorkOutputStatus.failure,
            errorMessage: 'Output cannot be recorded for this load status.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: JobWorkOutputStatus.ready,
          load: load,
        ),
      );
    } on JobWorkLoadException catch (error) {
      emit(
        state.copyWith(
          status: JobWorkOutputStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkOutputStatus.failure,
          errorMessage: 'Could not load job work load.',
        ),
      );
    }
  }

  Future<JobWorkLoad?> _resolveLoad(JobWorkOutputLoadRequested event) async {
    if (event.loadId != null && event.loadId!.isNotEmpty) {
      var load = await _loadRepository.getLoad(event.loadId!);
      if (load != null) return load;
    }

    final jobWorkId = event.jobWorkId;
    if (jobWorkId == null || jobWorkId.isEmpty) return null;

    final order = await _repository.getJobWorkOrder(jobWorkId);
    if (order == null) return null;
    final existing = await _loadRepository.fetchLoadsForJobWork(
      factoryId: order.factoryId,
      jobWorkId: jobWorkId,
    );
    if (existing.length > 1) {
      throw const JobWorkLoadException(
        'Select a load before recording output.',
      );
    }

    await _loadRepository.ensureDefaultLoad(jobWorkId);
    final loads = await _loadRepository.fetchLoadsForJobWork(
      factoryId: order.factoryId,
      jobWorkId: jobWorkId,
    );
    final resolved = JobWorkLoadResolver.resolveLoads(order, loads);
    if (resolved.isEmpty) return null;
    return JobWorkLoadResolver.preferredDefaultLoad(order, resolved);
  }

  Future<void> _onSubmitted(
    JobWorkOutputSubmitted event,
    Emitter<JobWorkOutputState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkOutputStatus.saving));
    try {
      final saved = await _loadRepository.recordLoadOutput(event.load);
      emit(
        state.copyWith(
          status: JobWorkOutputStatus.saved,
          load: saved,
        ),
      );
    } on JobWorkLoadException catch (error) {
      emit(
        state.copyWith(
          status: JobWorkOutputStatus.failure,
          errorMessage: error.message,
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
