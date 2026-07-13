import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/job_work_collection_repository.dart';
import '../../data/repositories/job_work_load_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/services/job_work_collection_quantity_helper.dart';
import '../../data/services/job_work_load_resolver.dart';
import '../../domain/entities/job_work_collection.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';

part 'job_work_collection_form_event.dart';
part 'job_work_collection_form_state.dart';

class JobWorkCollectionFormBloc
    extends Bloc<JobWorkCollectionFormEvent, JobWorkCollectionFormState> {
  JobWorkCollectionFormBloc({
    required JobWorkRepository jobWorkRepository,
    required JobWorkCollectionRepository collectionRepository,
    required JobWorkLoadRepository loadRepository,
  })  : _jobWorkRepository = jobWorkRepository,
        _collectionRepository = collectionRepository,
        _loadRepository = loadRepository,
        super(const JobWorkCollectionFormState()) {
    on<JobWorkCollectionFormInitialized>(_onInitialized);
    on<JobWorkCollectionFormSubmitted>(_onSubmitted);
  }

  final JobWorkRepository _jobWorkRepository;
  final JobWorkCollectionRepository _collectionRepository;
  final JobWorkLoadRepository _loadRepository;

  Future<void> _onInitialized(
    JobWorkCollectionFormInitialized event,
    Emitter<JobWorkCollectionFormState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkCollectionFormStatus.loading));
    try {
      final order =
          await _jobWorkRepository.getJobWorkOrder(event.jobWorkOrderId);
      if (order == null) {
        emit(
          state.copyWith(
            status: JobWorkCollectionFormStatus.failure,
            errorMessage: 'Job work order not found.',
          ),
        );
        return;
      }

      final load = await _resolveLoad(
        jobWorkOrderId: order.id,
        loadId: event.loadId,
      );
      if (load == null) {
        emit(
          state.copyWith(
            status: JobWorkCollectionFormStatus.failure,
            errorMessage: 'Load not found.',
            order: order,
          ),
        );
        return;
      }

      if (!load.status.canCollectMaterial) {
        emit(
          state.copyWith(
            status: JobWorkCollectionFormStatus.failure,
            errorMessage:
                'Material can only be collected after cutting has started.',
            order: order,
            load: load,
          ),
        );
        return;
      }

      final collections =
          await _collectionRepository.fetchCollectionsForJobWork(
        factoryId: order.factoryId,
        jobWorkOrderId: order.id,
      );
      final remaining = JobWorkCollectionQuantityHelper.remainingLinesForLoad(
        load,
        collections,
      );
      if (remaining.isEmpty) {
        emit(
          state.copyWith(
            status: JobWorkCollectionFormStatus.failure,
            errorMessage: 'No remaining stock to collect.',
            order: order,
            load: load,
            collections: collections,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: JobWorkCollectionFormStatus.ready,
          order: order,
          load: load,
          collections: collections,
          errorMessage: null,
        ),
      );
    } on JobWorkCollectionException catch (error) {
      emit(
        state.copyWith(
          status: JobWorkCollectionFormStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkCollectionFormStatus.failure,
          errorMessage: 'Could not load collect material form.',
        ),
      );
    }
  }

  Future<JobWorkLoad?> _resolveLoad({
    required String jobWorkOrderId,
    String? loadId,
  }) async {
    if (loadId != null && loadId.isNotEmpty) {
      return _loadRepository.getLoad(loadId);
    }

    final order = await _jobWorkRepository.getJobWorkOrder(jobWorkOrderId);
    if (order == null) return null;
    final existing = await _loadRepository.fetchLoadsForJobWork(
      factoryId: order.factoryId,
      jobWorkId: jobWorkOrderId,
    );
    if (existing.length > 1) {
      throw const JobWorkCollectionException(
        'Select a load before collecting material.',
      );
    }

    await _loadRepository.ensureDefaultLoad(jobWorkOrderId);
    final loads = await _loadRepository.fetchLoadsForJobWork(
      factoryId: order.factoryId,
      jobWorkId: jobWorkOrderId,
    );
    final resolved = JobWorkLoadResolver.resolveLoads(order, loads);
    if (resolved.isEmpty) return null;
    return JobWorkLoadResolver.preferredDefaultLoad(order, resolved);
  }

  Future<void> _onSubmitted(
    JobWorkCollectionFormSubmitted event,
    Emitter<JobWorkCollectionFormState> emit,
  ) async {
    final order = state.order;
    final load = state.load;
    if (order == null || load == null) return;

    emit(state.copyWith(status: JobWorkCollectionFormStatus.saving));
    try {
      await _collectionRepository.recordCollection(
        jobWorkOrderId: order.id,
        loadId: load.id,
        collectedAt: event.collectedAt,
        lineItems: event.lineItems,
        receiverName: event.receiverName,
        notes: event.notes,
      );
      emit(state.copyWith(status: JobWorkCollectionFormStatus.saved));
    } on JobWorkCollectionException catch (error) {
      emit(
        state.copyWith(
          status: JobWorkCollectionFormStatus.ready,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkCollectionFormStatus.ready,
          errorMessage: 'Could not save material collection.',
        ),
      );
    }
  }
}
