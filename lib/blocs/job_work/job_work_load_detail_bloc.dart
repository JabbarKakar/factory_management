import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/job_work_collection_repository.dart';
import '../../data/repositories/job_work_invoice_repository.dart';
import '../../data/repositories/job_work_load_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/quality_check_repository.dart';
import '../../domain/entities/job_work_collection.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/payment.dart';
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
    required JobWorkInvoiceRepository invoiceRepository,
    required PaymentRepository paymentRepository,
  })  : _jobWorkRepository = jobWorkRepository,
        _loadRepository = loadRepository,
        _collectionRepository = collectionRepository,
        _qualityCheckRepository = qualityCheckRepository,
        _invoiceRepository = invoiceRepository,
        _paymentRepository = paymentRepository,
        super(const JobWorkLoadDetailState()) {
    on<JobWorkLoadDetailStarted>(_onStarted);
    on<_JobWorkLoadDetailLoadUpdated>(_onLoadUpdated);
    on<_JobWorkLoadDetailCollectionsUpdated>(_onCollectionsUpdated);
    on<_JobWorkLoadDetailQualityUpdated>(_onQualityUpdated);
    on<_JobWorkLoadDetailInvoiceUpdated>(_onInvoiceUpdated);
    on<_JobWorkLoadDetailPaymentsUpdated>(_onPaymentsUpdated);
    on<JobWorkLoadDetailAdvanceStatusRequested>(_onAdvanceStatus);
    on<JobWorkLoadDetailAdvanceCompletionRequested>(_onAdvanceCompletion);
    on<_JobWorkLoadDetailSiblingLoadsUpdated>(_onSiblingLoadsUpdated);
    on<_JobWorkLoadDetailAllInvoicesUpdated>(_onAllInvoicesUpdated);
  }

  final JobWorkRepository _jobWorkRepository;
  final JobWorkLoadRepository _loadRepository;
  final JobWorkCollectionRepository _collectionRepository;
  final QualityCheckRepository _qualityCheckRepository;
  final JobWorkInvoiceRepository _invoiceRepository;
  final PaymentRepository _paymentRepository;

  StreamSubscription<JobWorkLoad?>? _loadSub;
  StreamSubscription<List<JobWorkCollection>>? _collectionsSub;
  StreamSubscription<List<QualityCheck>>? _qualitySub;
  StreamSubscription<JobWorkInvoice?>? _invoiceSub;
  StreamSubscription<List<Payment>>? _paymentsSub;
  StreamSubscription<List<JobWorkLoad>>? _siblingLoadsSub;
  StreamSubscription<List<JobWorkInvoice>>? _allInvoicesSub;
  String? _watchedInvoiceId;

  Future<void> _onStarted(
    JobWorkLoadDetailStarted event,
    Emitter<JobWorkLoadDetailState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkLoadDetailStatus.loading));
    await _cancelWatches();

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
      final siblingLoads = await _loadRepository.fetchLoadsForJobWork(
        factoryId: order.factoryId,
        jobWorkId: order.id,
      );
      final invoices = await _invoiceRepository.getInvoicesByJobWorkId(
        factoryId: order.factoryId,
        jobWorkId: order.id,
      );

      emit(
        state.copyWith(
          status: JobWorkLoadDetailStatus.ready,
          order: order,
          load: syncedLoad,
          siblingLoadCount: siblingLoads.length,
          siblingLoads: siblingLoads,
          invoices: invoices,
          invoice: null,
          payments: const [],
          clearInvoice: true,
          errorMessage: null,
        ),
      );

      _loadSub = _loadRepository.watchLoad(event.loadId).listen(
            (updated) => add(_JobWorkLoadDetailLoadUpdated(updated)),
          );
      _siblingLoadsSub = _loadRepository
          .watchLoadsForJobWork(
            factoryId: order.factoryId,
            jobWorkId: order.id,
          )
          .listen(
            (updated) => add(_JobWorkLoadDetailSiblingLoadsUpdated(updated)),
          );
      _allInvoicesSub = _invoiceRepository
          .watchInvoicesByJobWorkId(
            factoryId: order.factoryId,
            jobWorkId: order.id,
          )
          .listen(
            (updated) => add(_JobWorkLoadDetailAllInvoicesUpdated(updated)),
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
      _invoiceSub = _invoiceRepository
          .watchInvoiceByLoadId(
            factoryId: syncedLoad.factoryId,
            loadId: syncedLoad.id,
          )
          .asyncMap((invoice) async {
            if (invoice != null) return invoice;
            return _invoiceRepository.getInvoiceForLoad(
              factoryId: syncedLoad.factoryId,
              loadId: syncedLoad.id,
            );
          })
          .listen(
            (invoice) => add(_JobWorkLoadDetailInvoiceUpdated(invoice)),
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

  Future<void> _onInvoiceUpdated(
    _JobWorkLoadDetailInvoiceUpdated event,
    Emitter<JobWorkLoadDetailState> emit,
  ) async {
    var invoice = event.invoice;
    if (invoice == null) {
      final load = state.load;
      if (load != null) {
        invoice = await _invoiceRepository.getInvoiceForLoad(
          factoryId: load.factoryId,
          loadId: load.id,
        );
      }
    }

    if (invoice == null) {
      await _paymentsSub?.cancel();
      _paymentsSub = null;
      _watchedInvoiceId = null;
      emit(state.copyWith(clearInvoice: true, payments: const []));
      return;
    }

    emit(state.copyWith(invoice: invoice));
    if (_watchedInvoiceId == invoice.id) return;

    await _paymentsSub?.cancel();
    _watchedInvoiceId = invoice.id;
    _paymentsSub = _paymentRepository
        .watchPaymentsForInvoice(
          factoryId: invoice.factoryId,
          invoiceId: invoice.id,
        )
        .listen(
          (payments) => add(_JobWorkLoadDetailPaymentsUpdated(payments)),
        );
  }

  void _onPaymentsUpdated(
    _JobWorkLoadDetailPaymentsUpdated event,
    Emitter<JobWorkLoadDetailState> emit,
  ) {
    emit(state.copyWith(payments: event.payments));
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

  Future<void> _cancelWatches() async {
    await _loadSub?.cancel();
    await _collectionsSub?.cancel();
    await _qualitySub?.cancel();
    await _invoiceSub?.cancel();
    await _paymentsSub?.cancel();
    await _siblingLoadsSub?.cancel();
    await _allInvoicesSub?.cancel();
    _loadSub = null;
    _collectionsSub = null;
    _qualitySub = null;
    _invoiceSub = null;
    _paymentsSub = null;
    _siblingLoadsSub = null;
    _allInvoicesSub = null;
    _watchedInvoiceId = null;
  }

  void _onSiblingLoadsUpdated(
    _JobWorkLoadDetailSiblingLoadsUpdated event,
    Emitter<JobWorkLoadDetailState> emit,
  ) {
    emit(
      state.copyWith(
        siblingLoads: event.siblingLoads,
        siblingLoadCount: event.siblingLoads.length,
      ),
    );
  }

  void _onAllInvoicesUpdated(
    _JobWorkLoadDetailAllInvoicesUpdated event,
    Emitter<JobWorkLoadDetailState> emit,
  ) {
    emit(state.copyWith(invoices: event.invoices));
  }

  @override
  Future<void> close() async {
    await _cancelWatches();
    return super.close();
  }
}
