import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/job_work_collection_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/services/job_work_collection_quantity_helper.dart';
import '../../domain/entities/job_work_collection.dart';
import '../../domain/entities/job_work_order.dart';

part 'job_work_collection_form_event.dart';
part 'job_work_collection_form_state.dart';

class JobWorkCollectionFormBloc
    extends Bloc<JobWorkCollectionFormEvent, JobWorkCollectionFormState> {
  JobWorkCollectionFormBloc({
    required JobWorkRepository jobWorkRepository,
    required JobWorkCollectionRepository collectionRepository,
  })  : _jobWorkRepository = jobWorkRepository,
        _collectionRepository = collectionRepository,
        super(const JobWorkCollectionFormState()) {
    on<JobWorkCollectionFormInitialized>(_onInitialized);
    on<JobWorkCollectionFormSubmitted>(_onSubmitted);
  }

  final JobWorkRepository _jobWorkRepository;
  final JobWorkCollectionRepository _collectionRepository;

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
      if (!order.status.canCollectMaterial) {
        emit(
          state.copyWith(
            status: JobWorkCollectionFormStatus.failure,
            errorMessage:
                'Material can only be collected after cutting has started.',
            order: order,
          ),
        );
        return;
      }

      final collections =
          await _collectionRepository.fetchCollectionsForJobWork(
        factoryId: order.factoryId,
        jobWorkOrderId: order.id,
      );
      final remaining = JobWorkCollectionQuantityHelper.remainingLines(
        order,
        collections,
      );
      if (remaining.isEmpty) {
        emit(
          state.copyWith(
            status: JobWorkCollectionFormStatus.failure,
            errorMessage: 'No remaining stock to collect.',
            order: order,
            collections: collections,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: JobWorkCollectionFormStatus.ready,
          order: order,
          collections: collections,
          errorMessage: null,
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

  Future<void> _onSubmitted(
    JobWorkCollectionFormSubmitted event,
    Emitter<JobWorkCollectionFormState> emit,
  ) async {
    final order = state.order;
    if (order == null) return;

    emit(state.copyWith(status: JobWorkCollectionFormStatus.saving));
    try {
      await _collectionRepository.recordCollection(
        jobWorkOrderId: order.id,
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
