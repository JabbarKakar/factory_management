import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/marble_data.dart';
import '../../data/repositories/job_work_invoice_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/quality_check_repository.dart';
import '../../data/services/operational_alert_scanner_service.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/job_work_invoice.dart';
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
    required PaymentRepository paymentRepository,
    required QualityCheckRepository qualityCheckRepository,
    required OperationalAlertScannerService operationalAlertScannerService,
  })  : _repository = repository,
        _invoiceRepository = invoiceRepository,
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
    on<_JobWorkOrderUpdated>(_onOrderUpdated);
    on<_JobWorkInvoiceUpdated>(_onInvoiceUpdated);
    on<_JobWorkPaymentsUpdated>(_onPaymentsUpdated);
    on<_JobWorkQualityChecksUpdated>(_onQualityChecksUpdated);
  }

  final JobWorkRepository _repository;
  final JobWorkInvoiceRepository _invoiceRepository;
  final PaymentRepository _paymentRepository;
  final QualityCheckRepository _qualityCheckRepository;
  final OperationalAlertScannerService _operationalAlertScannerService;
  StreamSubscription<JobWorkOrder?>? _orderSubscription;
  StreamSubscription<JobWorkInvoice?>? _invoiceSubscription;
  StreamSubscription<List<Payment>>? _paymentsSubscription;
  StreamSubscription<List<QualityCheck>>? _qualityChecksSubscription;
  String? _watchedInvoiceId;

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
        qualityChecks: const [],
        payments: const [],
      ),
    );

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
          eligibleCustomers: _repository.customersForOrderForm(
            eligible: customers,
            order: order,
          ),
          isEditing: true,
        ),
      );

      _orderSubscription = _repository.watchJobWorkOrder(event.jobWorkId).listen(
            (updated) => add(_JobWorkOrderUpdated(updated)),
            onError: (_) {},
          );

      _invoiceSubscription = _invoiceRepository
          .watchInvoiceByJobWorkId(
            factoryId: order.factoryId,
            jobWorkId: event.jobWorkId,
          )
          .listen(
            (invoice) => add(_JobWorkInvoiceUpdated(invoice)),
            onError: (_) {},
          );

      _qualityChecksSubscription = _qualityCheckRepository
          .watchQualityChecksForReference(
            referenceType: QcReferenceType.jobWork,
            referenceId: event.jobWorkId,
          )
          .listen(
            (checks) => add(_JobWorkQualityChecksUpdated(checks)),
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

    emit(
      state.copyWith(
        status: JobWorkFormStatus.ready,
        order: event.order,
      ),
    );
  }

  Future<void> _onInvoiceUpdated(
    _JobWorkInvoiceUpdated event,
    Emitter<JobWorkFormState> emit,
  ) async {
    final invoice = event.invoice;
    emit(state.copyWith(invoice: invoice));

    if (invoice == null) {
      await _paymentsSubscription?.cancel();
      _paymentsSubscription = null;
      _watchedInvoiceId = null;
      emit(state.copyWith(payments: const []));
      return;
    }

    await _paymentRepository.ensureInvoicePaidAmountRecorded(
      invoiceId: invoice.id,
      invoiceType: InvoiceType.jobWork,
    );
    _ensurePaymentsWatch(invoice);
  }

  void _onPaymentsUpdated(
    _JobWorkPaymentsUpdated event,
    Emitter<JobWorkFormState> emit,
  ) {
    emit(state.copyWith(payments: event.payments));
  }

  void _ensurePaymentsWatch(JobWorkInvoice invoice) {
    if (_watchedInvoiceId == invoice.id) return;
    _paymentsSubscription?.cancel();
    _watchedInvoiceId = invoice.id;
    _paymentsSubscription = _paymentRepository
        .watchPaymentsForInvoice(
          factoryId: invoice.factoryId,
          invoiceId: invoice.id,
        )
        .listen(
          (payments) => add(_JobWorkPaymentsUpdated(payments)),
          onError: (_) {},
        );
  }

  Future<void> _cancelDetailSubscriptions() async {
    await _orderSubscription?.cancel();
    await _invoiceSubscription?.cancel();
    await _paymentsSubscription?.cancel();
    _orderSubscription = null;
    _invoiceSubscription = null;
    _paymentsSubscription = null;
    _watchedInvoiceId = null;
  }

  void _onQualityChecksUpdated(
    _JobWorkQualityChecksUpdated event,
    Emitter<JobWorkFormState> emit,
  ) {
    emit(state.copyWith(qualityChecks: event.checks));
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

final class _JobWorkInvoiceUpdated extends JobWorkFormEvent {
  const _JobWorkInvoiceUpdated(this.invoice);

  final JobWorkInvoice? invoice;

  @override
  List<Object?> get props => [invoice];
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
