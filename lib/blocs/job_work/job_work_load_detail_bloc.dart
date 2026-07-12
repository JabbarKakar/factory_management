import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/job_work_collection_repository.dart';
import '../../data/repositories/job_work_load_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/repositories/quality_check_repository.dart';
import '../../domain/entities/job_work_collection.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/quality_check.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/quality_enums.dart';

part 'job_work_load_detail_event.dart';
part 'job_work_load_detail_state.dart';

class JobWorkLoadDetailBloc
    extends Bloc<JobWorkLoadDetailEvent, JobWorkLoadDetailState> {
  JobWorkLoadDetailBloc({
    required JobWorkRepository jobWorkRepository,
    required JobWorkLoadRepository loadRepository,
    required JobWorkCollectionRepository collectionRepository,
    required QualityCheckRepository qualityCheckRepository,
  })  : _jobWorkRepository = jobWorkRepository,
        _loadRepository = loadRepository,
        _collectionRepository = collectionRepository,
        _qualityCheckRepository = qualityCheckRepository,
        super(const JobWorkLoadDetailState()) {
    on<JobWorkLoadDetailStarted>(_onStarted);
    on<_JobWorkLoadDetailLoadUpdated>(_onLoadUpdated);
    on<_JobWorkLoadDetailCollectionsUpdated>(_onCollectionsUpdated);
    on<_JobWorkLoadDetailQualityUpdated>(_onQualityUpdated);
    on<JobWorkLoadDetailAdvanceStatusRequested>(_onAdvanceStatus);
    on<JobWorkLoadDetailAdvanceCompletionRequested>(_onAdvanceCompletion);
  }

  final JobWorkRepository _jobWorkRepository;
  final JobWorkLoadRepository _loadRepository;
  final JobWorkCollectionRepository _collectionRepository;
  final QualityCheckRepository _qualityCheckRepository;

  StreamSubscription<JobWorkLoad?>? _loadSub;
  StreamSubscription<List<JobWorkCollection>>? _collectionsSub;
  StreamSubscription<List<QualityCheck>>? _qualitySub;

  Future<void> _onStarted(
    JobWorkLoadDetailStarted event,
    Emitter<JobWorkLoadDetailState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkLoadDetailStatus.loading));
    await _loadSub?.cancel();
    await _collectionsSub?.cancel();
    await _qualitySub?.cancel();

    try {
      final order =
          await _jobWorkRepository.getJobWorkOrder(event.jobWorkId);
      if (order == null) {
        emit(
          state.copyWith(
            status: JobWorkLoadDetailStatus.failure,
            errorMessage: 'Job work order not found.',
          ),
        );
        return;
      }

      final load = await _loadRepository.getLoad(event.loadId);
      if (load == null || load.jobWorkId != event.jobWorkId) {
        emit(
          state.copyWith(
            status: JobWorkLoadDetailStatus.failure,
            errorMessage: 'Load not found.',
            order: order,
          ),
        );
        return;
      }

      // Heal status when pieces are fully collected but sq.ft dust remains.
      await _collectionRepository.syncLoadCollectionDerivedStatus(load.id);
      final syncedLoad = await _loadRepository.getLoad(event.loadId) ?? load;

      emit(
        state.copyWith(
          status: JobWorkLoadDetailStatus.ready,
          order: order,
          load: syncedLoad,
          errorMessage: null,
        ),
      );

      _loadSub = _loadRepository.watchLoad(event.loadId).listen(
            (updated) => add(_JobWorkLoadDetailLoadUpdated(updated)),
          );
      _collectionsSub = _collectionRepository
          .watchCollectionsForJobWork(
            factoryId: order.factoryId,
            jobWorkOrderId: order.id,
          )
          .listen(
            (items) => add(_JobWorkLoadDetailCollectionsUpdated(items)),
          );
      _qualitySub = _qualityCheckRepository
          .watchQualityChecksForReference(
            factoryId: order.factoryId,
            referenceType: QcReferenceType.jobWorkLoad,
            referenceId: syncedLoad.id,
          )
          .listen(
            (checks) => add(_JobWorkLoadDetailQualityUpdated(checks)),
          );
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkLoadDetailStatus.failure,
          errorMessage: 'Could not load details.',
        ),
      );
    }
  }

  void _onLoadUpdated(
    _JobWorkLoadDetailLoadUpdated event,
    Emitter<JobWorkLoadDetailState> emit,
  ) {
    if (event.load == null) return;
    emit(
      state.copyWith(
        load: event.load,
        status: JobWorkLoadDetailStatus.ready,
      ),
    );
  }

  void _onCollectionsUpdated(
    _JobWorkLoadDetailCollectionsUpdated event,
    Emitter<JobWorkLoadDetailState> emit,
  ) {
    emit(state.copyWith(collections: event.collections));
  }

  void _onQualityUpdated(
    _JobWorkLoadDetailQualityUpdated event,
    Emitter<JobWorkLoadDetailState> emit,
  ) {
    emit(state.copyWith(qualityChecks: event.qualityChecks));
  }

  Future<void> _onAdvanceStatus(
    JobWorkLoadDetailAdvanceStatusRequested event,
    Emitter<JobWorkLoadDetailState> emit,
  ) async {
    final load = state.load;
    if (load == null) return;
    emit(state.copyWith(status: JobWorkLoadDetailStatus.saving));
    try {
      final updated = await _loadRepository.advanceLoadStatus(
        loadId: load.id,
        newStatus: event.nextStatus,
      );
      emit(
        state.copyWith(
          status: JobWorkLoadDetailStatus.ready,
          load: updated,
          errorMessage: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkLoadDetailStatus.ready,
          errorMessage: 'Could not update load status.',
        ),
      );
    }
  }

  Future<void> _onAdvanceCompletion(
    JobWorkLoadDetailAdvanceCompletionRequested event,
    Emitter<JobWorkLoadDetailState> emit,
  ) async {
    final load = state.load;
    if (load == null) return;
    emit(state.copyWith(status: JobWorkLoadDetailStatus.saving));
    try {
      final updated = await _loadRepository.advanceLoadCompletionStatus(
        loadId: load.id,
        targetStatus: event.nextStatus,
      );
      emit(
        state.copyWith(
          status: JobWorkLoadDetailStatus.ready,
          load: updated,
          errorMessage: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkLoadDetailStatus.ready,
          errorMessage: 'Could not close load.',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _loadSub?.cancel();
    await _collectionsSub?.cancel();
    await _qualitySub?.cancel();
    return super.close();
  }
}
