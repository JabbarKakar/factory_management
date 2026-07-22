import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/marble_data.dart';
import '../../data/repositories/job_work_collection_repository.dart';
import '../../data/repositories/job_work_invoice_repository.dart';
import '../../data/repositories/job_work_load_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/quality_check_repository.dart';
import '../../data/services/job_work_load_resolver.dart';
import '../../data/services/operational_alert_scanner_service.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/job_work_collection.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/quality_check.dart';
import '../../domain/enums/customer_enums.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/quality_enums.dart';

part 'job_work_form_event.dart';
part 'job_work_form_state.dart';

class JobWorkFormBloc extends Bloc<JobWorkFormEvent, JobWorkFormState> {
  JobWorkFormBloc({
    required JobWorkRepository repository,
    required JobWorkInvoiceRepository invoiceRepository,
    required JobWorkCollectionRepository collectionRepository,
    required JobWorkLoadRepository loadRepository,
    required PaymentRepository paymentRepository,
    required QualityCheckRepository qualityCheckRepository,
    required OperationalAlertScannerService operationalAlertScannerService,
  })  : _repository = repository,
        _invoiceRepository = invoiceRepository,
        _collectionRepository = collectionRepository,
        _loadRepository = loadRepository,
        _paymentRepository = paymentRepository,
        _qualityCheckRepository = qualityCheckRepository,
        _operationalAlertScannerService = operationalAlertScannerService,
        super(const JobWorkFormState()) {
    on<JobWorkFormInitialized>(_onInitialized);
    on<JobWorkFormLoadRequested>(_onLoadRequested);
    on<JobWorkFormSubmitted>(_onSubmitted);
    on<JobWorkFormCancelRequested>(_onCancelRequested);
    on<JobWorkFormStatusAdvanceRequested>(_onStatusAdvanceRequested);
    on<JobWorkFormCompletionRequested>(_onCompletionRequested);
    on<JobWorkFormLoadStatusAdvanceRequested>(_onLoadStatusAdvanceRequested);
    on<JobWorkFormLoadCompletionRequested>(_onLoadCompletionRequested);
    on<_JobWorkOrderUpdated>(_onOrderUpdated);
    on<_JobWorkInvoicesUpdated>(_onInvoicesUpdated);
    on<_JobWorkPaymentsUpdated>(_onPaymentsUpdated);
    on<_JobWorkQualityChecksUpdated>(_onQualityChecksUpdated);
    on<_JobWorkCollectionsUpdated>(_onCollectionsUpdated);
    on<_JobWorkLoadsUpdated>(_onLoadsUpdated);
  }

  final JobWorkRepository _repository;
  final JobWorkInvoiceRepository _invoiceRepository;
  final JobWorkCollectionRepository _collectionRepository;
  final JobWorkLoadRepository _loadRepository;
  final PaymentRepository _paymentRepository;
  final QualityCheckRepository _qualityCheckRepository;
  final OperationalAlertScannerService _operationalAlertScannerService;
  StreamSubscription<JobWorkOrder?>? _orderSubscription;
  StreamSubscription<List<JobWorkInvoice>>? _invoiceSubscription;
  StreamSubscription<List<QualityCheck>>? _qualityChecksSubscription;
  StreamSubscription<List<JobWorkCollection>>? _collectionsSubscription;
  StreamSubscription<List<JobWorkLoad>>? _loadsSubscription;
  final Map<String, List<Payment>> _paymentsByInvoiceId = {};
  Set<String> _watchedInvoiceIds = {};
  final Map<String, StreamSubscription<List<Payment>>> _paymentSubsByInvoice =
      {};
  List<QualityCheck> _factoryQualityChecks = const [];

  Future<void> _onInitialized(
    JobWorkFormInitialized event,
    Emitter<JobWorkFormState> emit,
  ) async {
    await _cancelDetailSubscriptions();
    await _qualityChecksSubscription?.cancel();
    _qualityChecksSubscription = null;
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
    await _cancelDetailSubscriptions();
    await _qualityChecksSubscription?.cancel();
    _qualityChecksSubscription = null;
    emit(
      state.copyWith(
        status: JobWorkFormStatus.loading,
        isEditing: true,
        clearMessages: true,
        clearInvoice: true,
        invoices: const [],
        qualityChecks: const [],
        payments: const [],
        collections: const [],
        loads: const [],
      ),
    );
    _factoryQualityChecks = const [];
    _paymentsByInvoiceId.clear();
    _watchedInvoiceIds = {};

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

      // Lazy migration: ensure legacy JW has a default Load doc.
      await _loadRepository.ensureDefaultLoad(event.jobWorkId);
      final refreshed =
          await _repository.getJobWorkOrder(event.jobWorkId) ?? order;

      final customers =
          await _repository.fetchJobWorkEligibleCustomers(refreshed.factoryId);

      emit(
        state.copyWith(
          status: JobWorkFormStatus.ready,
          order: refreshed,
          eligibleCustomers: _repository.customersForOrderForm(
            eligible: customers,
            order: refreshed,
          ),
          isEditing: true,
        ),
      );

      _orderSubscription =
          _repository.watchJobWorkOrder(event.jobWorkId).listen(
                (updated) {
                  if (!isClosed) add(_JobWorkOrderUpdated(updated));
                },
                onError: (_) {},
              );

      _invoiceSubscription = _invoiceRepository
          .watchInvoicesByJobWorkId(
            factoryId: refreshed.factoryId,
            jobWorkId: event.jobWorkId,
          )
          .listen(
            (invoices) {
              if (!isClosed) add(_JobWorkInvoicesUpdated(invoices));
            },
            onError: (_) {},
          );

      _qualityChecksSubscription = _qualityCheckRepository
          .watchQualityChecks(refreshed.factoryId)
          .listen(
            (checks) {
              if (!isClosed) add(_JobWorkQualityChecksUpdated(checks));
            },
            onError: (_) {},
          );

      _collectionsSubscription = _collectionRepository
          .watchCollectionsForJobWork(
            factoryId: refreshed.factoryId,
            jobWorkOrderId: event.jobWorkId,
          )
          .listen(
            (collections) {
              if (!isClosed) add(_JobWorkCollectionsUpdated(collections));
            },
            onError: (_) {},
          );

      _loadsSubscription = _loadRepository
          .watchLoadsForJobWork(
            factoryId: refreshed.factoryId,
            jobWorkId: event.jobWorkId,
          )
          .listen(
            (loads) {
              if (!isClosed) add(_JobWorkLoadsUpdated(loads));
            },
            onError: (_) {},
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

  void _onOrderUpdated(
    _JobWorkOrderUpdated event,
    Emitter<JobWorkFormState> emit,
  ) {
    if (event.order == null) {
      emit(
        state.copyWith(
          status: JobWorkFormStatus.failure,
          errorMessage: 'Job work order not found.',
        ),
      );
      return;
    }

    final preferred = _preferredInvoice(state.invoices, event.order, state.loads);
    emit(
      state.copyWith(
        status: JobWorkFormStatus.ready,
        order: event.order,
        invoice: preferred,
        clearInvoice: preferred == null,
      ),
    );
  }

  Future<void> _onInvoicesUpdated(
    _JobWorkInvoicesUpdated event,
    Emitter<JobWorkFormState> emit,
  ) async {
    final invoices = event.invoices;
    final preferred = _preferredInvoice(invoices, state.order, state.loads);
    emit(
      state.copyWith(
        invoices: invoices,
        invoice: preferred,
        clearInvoice: preferred == null,
      ),
    );

    if (invoices.isEmpty) {
      await _cancelPaymentSubscriptions();
      emit(state.copyWith(payments: const [], clearInvoice: true));
      return;
    }

    for (final invoice in invoices) {
      await _paymentRepository.ensureInvoicePaidAmountRecorded(
        invoiceId: invoice.id,
        invoiceType: InvoiceType.jobWork,
      );
    }
    _ensurePaymentsWatch(invoices);
  }

  JobWorkInvoice? _preferredInvoice(
    List<JobWorkInvoice> invoices,
    JobWorkOrder? order,
    List<JobWorkLoad> loads,
  ) {
    final grandInvoices = invoices.where((i) => i.loadId == null || i.loadId!.isEmpty).toList();
    if (grandInvoices.isNotEmpty) {
      final orderInvoiceId = order?.invoiceId;
      if (orderInvoiceId != null && orderInvoiceId.isNotEmpty) {
        for (final invoice in grandInvoices) {
          if (invoice.id == orderInvoiceId) return invoice;
        }
      }
      return grandInvoices.first;
    }

    // Fallback: If no grand invoice exists but load-scoped invoices do,
    // and there is only 1 active load, return the first load-scoped invoice.
    if (invoices.isNotEmpty) {
      final activeLoads = loads.where((l) => !l.isVirtual && l.status != JobWorkStatus.cancelled).toList();
      if (activeLoads.length == 1) {
        return invoices.first;
      }
    }
    return null;
  }

  void _onPaymentsUpdated(
    _JobWorkPaymentsUpdated event,
    Emitter<JobWorkFormState> emit,
  ) {
    emit(state.copyWith(payments: event.payments));
  }

  void _ensurePaymentsWatch(List<JobWorkInvoice> invoices) {
    final ids = invoices.map((invoice) => invoice.id).toSet();
    final removed = _watchedInvoiceIds.difference(ids);
    for (final id in removed) {
      _paymentSubsByInvoice[id]?.cancel();
      _paymentSubsByInvoice.remove(id);
      _paymentsByInvoiceId.remove(id);
    }

    for (final invoice in invoices) {
      if (_paymentSubsByInvoice.containsKey(invoice.id)) continue;
      _paymentSubsByInvoice[invoice.id] = _paymentRepository
          .watchPaymentsForInvoice(
            factoryId: invoice.factoryId,
            invoiceId: invoice.id,
          )
          .listen(
            (payments) {
              _paymentsByInvoiceId[invoice.id] = payments;
              final merged = _paymentsByInvoiceId.values
                  .expand((items) => items)
                  .toList();
              
              final unique = <String, Payment>{};
              for (final p in merged) {
                unique[p.id] = p;
              }
              
              final deduplicated = unique.values.toList()
                ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
              if (!isClosed) {
                add(_JobWorkPaymentsUpdated(deduplicated));
              }
            },
            onError: (_) {},
          );
    }
    _watchedInvoiceIds = ids;
  }

  Future<void> _cancelPaymentSubscriptions() async {
    for (final sub in _paymentSubsByInvoice.values) {
      await sub.cancel();
    }
    _paymentSubsByInvoice.clear();
    _paymentsByInvoiceId.clear();
    _watchedInvoiceIds = {};
  }

  Future<void> _cancelDetailSubscriptions() async {
    await _orderSubscription?.cancel();
    await _invoiceSubscription?.cancel();
    await _cancelPaymentSubscriptions();
    _orderSubscription = null;
    _invoiceSubscription = null;
    await _collectionsSubscription?.cancel();
    _collectionsSubscription = null;
    await _loadsSubscription?.cancel();
    _loadsSubscription = null;
  }

  void _onQualityChecksUpdated(
    _JobWorkQualityChecksUpdated event,
    Emitter<JobWorkFormState> emit,
  ) {
    _factoryQualityChecks = event.checks;
    emit(state.copyWith(qualityChecks: _relevantQualityChecks()));
  }

  void _onCollectionsUpdated(
    _JobWorkCollectionsUpdated event,
    Emitter<JobWorkFormState> emit,
  ) {
    emit(state.copyWith(collections: event.collections));
  }

  void _onLoadsUpdated(
    _JobWorkLoadsUpdated event,
    Emitter<JobWorkFormState> emit,
  ) {
    final order = state.order;
    final loads = order == null
        ? event.loads
        : JobWorkLoadResolver.resolveLoads(order, event.loads);
    final preferred = _preferredInvoice(state.invoices, order, loads);
    emit(
      state.copyWith(
        loads: loads,
        invoice: preferred,
        clearInvoice: preferred == null,
        qualityChecks: _relevantQualityChecks(loadIds: {
          for (final load in loads) load.id,
        }),
      ),
    );
  }

  List<QualityCheck> _relevantQualityChecks({Set<String>? loadIds}) {
    final orderId = state.order?.id;
    final ids = loadIds ?? state.loads.map((load) => load.id).toSet();
    return _factoryQualityChecks.where((check) {
      if (check.referenceType == QcReferenceType.jobWork &&
          orderId != null &&
          check.referenceId == orderId) {
        return true;
      }
      if (check.referenceType == QcReferenceType.jobWorkLoad &&
          ids.contains(check.referenceId)) {
        return true;
      }
      return false;
    }).toList();
  }

  Future<void> _onSubmitted(
    JobWorkFormSubmitted event,
    Emitter<JobWorkFormState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkFormStatus.saving));
    try {
      if (event.order.id.isEmpty) {
        final created = await _repository.createJobWorkOrder(event.order);
        await _loadRepository.ensureDefaultLoad(created.id);
        final withLoad =
            await _repository.getJobWorkOrder(created.id) ?? created;
        emit(
          state.copyWith(
            status: JobWorkFormStatus.saved,
            order: withLoad,
          ),
        );
      } else {
        await _loadRepository.ensureDefaultLoad(event.order.id);
        await _repository.updateJobWorkOrder(event.order);
        final refreshed =
            await _repository.getJobWorkOrder(event.order.id) ?? event.order;
        emit(
          state.copyWith(
            status: JobWorkFormStatus.saved,
            order: refreshed,
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

  Future<void> _onStatusAdvanceRequested(
    JobWorkFormStatusAdvanceRequested event,
    Emitter<JobWorkFormState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkFormStatus.saving));
    try {
      await _repository.advanceJobWorkStatus(event.jobWorkId, event.newStatus);
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

      emit(
        state.copyWith(
          status: JobWorkFormStatus.ready,
          order: order,
        ),
      );

      if (event.newStatus == JobWorkStatus.ready) {
        await _operationalAlertScannerService.notifyJobWorkReady(order);
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkFormStatus.failure,
          errorMessage: 'Could not update order status.',
        ),
      );
    }
  }

  Future<void> _onCompletionRequested(
    JobWorkFormCompletionRequested event,
    Emitter<JobWorkFormState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkFormStatus.saving));
    try {
      await _repository.advanceJobWorkCompletionStatus(
        event.jobWorkId,
        event.newStatus,
      );
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

      emit(
        state.copyWith(
          status: JobWorkFormStatus.ready,
          order: order,
          successMessage: event.newStatus == JobWorkStatus.collected
              ? AppStrings.jobWorkCollected
              : AppStrings.jobWorkClosed,
          errorMessage: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkFormStatus.failure,
          errorMessage: 'Could not update order completion status.',
        ),
      );
    }
  }

  Future<void> _onLoadStatusAdvanceRequested(
    JobWorkFormLoadStatusAdvanceRequested event,
    Emitter<JobWorkFormState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkFormStatus.saving, clearMessages: true));
    try {
      final updated = await _loadRepository.advanceLoadStatus(
        loadId: event.loadId,
        newStatus: event.newStatus,
      );
      final loads = state.loads
          .map((load) => load.id == updated.id ? updated : load)
          .toList();
      emit(
        state.copyWith(
          status: JobWorkFormStatus.ready,
          loads: loads,
        ),
      );

      if (event.newStatus == JobWorkStatus.ready) {
        final order = state.order ??
            await _repository.getJobWorkOrder(updated.jobWorkId);
        if (order != null) {
          await _operationalAlertScannerService.notifyJobWorkReady(
            order,
            load: updated,
          );
        }
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkFormStatus.failure,
          errorMessage: 'Could not update load status.',
        ),
      );
    }
  }

  Future<void> _onLoadCompletionRequested(
    JobWorkFormLoadCompletionRequested event,
    Emitter<JobWorkFormState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkFormStatus.saving, clearMessages: true));
    try {
      final updated = await _loadRepository.advanceLoadCompletionStatus(
        loadId: event.loadId,
        targetStatus: event.newStatus,
      );
      final loads = state.loads
          .map((load) => load.id == updated.id ? updated : load)
          .toList();
      emit(
        state.copyWith(
          status: JobWorkFormStatus.ready,
          loads: loads,
          successMessage: event.newStatus == JobWorkStatus.closed
              ? AppStrings.loadClosed
              : AppStrings.jobWorkCollected,
          errorMessage: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkFormStatus.failure,
          errorMessage: 'Could not update load completion status.',
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
      smallSizes: const [],
      largeSizes: const [],
      thickness: MarbleData.jobWorkThicknesses.first,
      finish: FinishType.unpolished,
      pricingModel: PricingModel.perTon,
      agreedRate: 0,
      smallStockPrice: 0,
      largeStockPrice: 0,
      finalCuttingCharges: 0,
      advanceReceived: 0,
      balanceDue: 0,
      paymentTerms: PaymentTerms.cash,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> close() {
    _cancelDetailSubscriptions();
    _qualityChecksSubscription?.cancel();
    return super.close();
  }
}

final class _JobWorkOrderUpdated extends JobWorkFormEvent {
  const _JobWorkOrderUpdated(this.order);

  final JobWorkOrder? order;

  @override
  List<Object?> get props => [order];
}

final class _JobWorkInvoicesUpdated extends JobWorkFormEvent {
  const _JobWorkInvoicesUpdated(this.invoices);

  final List<JobWorkInvoice> invoices;

  @override
  List<Object?> get props => [invoices];
}

final class _JobWorkPaymentsUpdated extends JobWorkFormEvent {
  const _JobWorkPaymentsUpdated(this.payments);

  final List<Payment> payments;

  @override
  List<Object?> get props => [payments];
}

final class _JobWorkQualityChecksUpdated extends JobWorkFormEvent {
  const _JobWorkQualityChecksUpdated(this.checks);

  final List<QualityCheck> checks;

  @override
  List<Object?> get props => [checks];
}

final class _JobWorkCollectionsUpdated extends JobWorkFormEvent {
  const _JobWorkCollectionsUpdated(this.collections);

  final List<JobWorkCollection> collections;

  @override
  List<Object?> get props => [collections];
}

final class _JobWorkLoadsUpdated extends JobWorkFormEvent {
  const _JobWorkLoadsUpdated(this.loads);

  final List<JobWorkLoad> loads;

  @override
  List<Object?> get props => [loads];
}
