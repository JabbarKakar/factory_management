import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/job_work_invoice_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/services/customer_ledger_service.dart';
import '../../data/services/payment_due_scanner_service.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/payment.dart';
import '../../domain/enums/invoice_enums.dart';

part 'job_work_invoice_event.dart';
part 'job_work_invoice_state.dart';

class JobWorkInvoiceBloc
    extends Bloc<JobWorkInvoiceEvent, JobWorkInvoiceState> {
  JobWorkInvoiceBloc({
    required JobWorkInvoiceRepository invoiceRepository,
    required PaymentRepository paymentRepository,
    required CustomerLedgerService ledgerService,
    required PaymentDueScannerService scannerService,
  })  : _invoiceRepository = invoiceRepository,
        _paymentRepository = paymentRepository,
        _ledgerService = ledgerService,
        _scannerService = scannerService,
        super(const JobWorkInvoiceState()) {
    on<JobWorkInvoiceLoadByJobWork>(_onLoadByJobWork);
    on<JobWorkInvoiceLoadById>(_onLoadById);
    on<JobWorkInvoiceGenerateRequested>(_onGenerate);
    on<JobWorkInvoicePaymentSubmitted>(_onPaymentSubmitted);
    on<_JobWorkInvoiceStreamUpdated>(_onInvoiceStreamUpdated);
    on<_JobWorkInvoicePaymentsUpdated>(_onPaymentsStreamUpdated);
  }

  final JobWorkInvoiceRepository _invoiceRepository;
  final PaymentRepository _paymentRepository;
  final CustomerLedgerService _ledgerService;
  final PaymentDueScannerService _scannerService;
  StreamSubscription<JobWorkInvoice?>? _invoiceSubscription;
  StreamSubscription<List<Payment>>? _paymentsSubscription;
  String? _watchedInvoiceId;

  Future<void> _onLoadByJobWork(
    JobWorkInvoiceLoadByJobWork event,
    Emitter<JobWorkInvoiceState> emit,
  ) async {
    await _cancelSubscriptions();
    emit(state.copyWith(status: JobWorkInvoiceStatus.loading));
    try {
      final invoice = await _invoiceRepository.getInvoiceByJobWorkId(
        factoryId: event.factoryId,
        jobWorkId: event.jobWorkId,
      );
      if (invoice == null) {
        emit(
          state.copyWith(
            status: JobWorkInvoiceStatus.notFound,
            jobWorkId: event.jobWorkId,
          ),
        );
        _invoiceSubscription = _invoiceRepository
            .watchInvoiceByJobWorkId(
              factoryId: event.factoryId,
              jobWorkId: event.jobWorkId,
            )
            .listen(
              (updated) => add(_JobWorkInvoiceStreamUpdated(updated)),
              onError: (_) {},
            );
        return;
      }
      await _startWatching(invoice, emit);
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkInvoiceStatus.failure,
          errorMessage: 'Could not load invoice.',
        ),
      );
    }
  }

  Future<void> _onLoadById(
    JobWorkInvoiceLoadById event,
    Emitter<JobWorkInvoiceState> emit,
  ) async {
    await _cancelSubscriptions();
    emit(state.copyWith(status: JobWorkInvoiceStatus.loading));
    try {
      final invoice = await _invoiceRepository.getInvoice(event.invoiceId);
      if (invoice == null) {
        emit(
          state.copyWith(
            status: JobWorkInvoiceStatus.failure,
            errorMessage: 'Invoice not found.',
          ),
        );
        return;
      }
      await _startWatching(invoice, emit);
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkInvoiceStatus.failure,
          errorMessage: 'Could not load invoice.',
        ),
      );
    }
  }

  Future<void> _onGenerate(
    JobWorkInvoiceGenerateRequested event,
    Emitter<JobWorkInvoiceState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkInvoiceStatus.saving));
    try {
      final invoice =
          await _invoiceRepository.generateFromJobWorkOrder(event.jobWorkId);
      await _paymentRepository.ensureInvoicePaidAmountRecorded(
        invoiceId: invoice.id,
        invoiceType: InvoiceType.jobWork,
      );
      await _ledgerService.syncCustomerBalance(invoice.customerId);
      await _scannerService.scan(invoice.factoryId);
      await _startWatching(invoice, emit, saved: true);
    } catch (e) {
      emit(
        state.copyWith(
          status: JobWorkInvoiceStatus.failure,
          errorMessage: e is StateError
              ? e.message
              : 'Could not generate invoice.',
        ),
      );
    }
  }

  Future<void> _onPaymentSubmitted(
    JobWorkInvoicePaymentSubmitted event,
    Emitter<JobWorkInvoiceState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkInvoiceStatus.saving));
    try {
      await _paymentRepository.recordJobWorkPayment(
        invoiceId: event.invoiceId,
        amount: event.amount,
        method: event.method,
        paymentDate: event.paymentDate,
        reference: event.reference,
        notes: event.notes,
      );
      final invoice = await _invoiceRepository.getInvoice(event.invoiceId);
      if (invoice == null) {
        emit(
          state.copyWith(
            status: JobWorkInvoiceStatus.failure,
            errorMessage: 'Invoice not found after payment.',
          ),
        );
        return;
      }
      await _startWatching(invoice, emit, paymentRecorded: true);
    } catch (e) {
      emit(
        state.copyWith(
          status: JobWorkInvoiceStatus.failure,
          errorMessage:
              e is StateError ? e.message : 'Could not record payment.',
        ),
      );
    }
  }

  Future<void> _onInvoiceStreamUpdated(
    _JobWorkInvoiceStreamUpdated event,
    Emitter<JobWorkInvoiceState> emit,
  ) async {
    final invoice = event.invoice;
    if (invoice == null) return;

    await _paymentRepository.ensureInvoicePaidAmountRecorded(
      invoiceId: invoice.id,
      invoiceType: InvoiceType.jobWork,
    );
    _ensurePaymentsWatch(invoice);

    emit(
      state.copyWith(
        status: JobWorkInvoiceStatus.loaded,
        invoice: invoice,
        jobWorkId: invoice.jobWorkId,
        errorMessage: null,
      ),
    );
  }

  void _onPaymentsStreamUpdated(
    _JobWorkInvoicePaymentsUpdated event,
    Emitter<JobWorkInvoiceState> emit,
  ) {
    emit(state.copyWith(payments: event.payments));
  }

  Future<void> _startWatching(
    JobWorkInvoice invoice,
    Emitter<JobWorkInvoiceState> emit, {
    bool saved = false,
    bool paymentRecorded = false,
  }) async {
    await _emitWithPayments(
      invoice,
      emit,
      saved: saved,
      paymentRecorded: paymentRecorded,
    );

    _invoiceSubscription?.cancel();
    _invoiceSubscription = _invoiceRepository.watchInvoice(invoice.id).listen(
          (updated) => add(_JobWorkInvoiceStreamUpdated(updated)),
          onError: (_) {},
        );
    _ensurePaymentsWatch(invoice);
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
          (payments) => add(_JobWorkInvoicePaymentsUpdated(payments)),
          onError: (_) {},
        );
  }

  Future<void> _cancelSubscriptions() async {
    await _invoiceSubscription?.cancel();
    await _paymentsSubscription?.cancel();
    _invoiceSubscription = null;
    _paymentsSubscription = null;
    _watchedInvoiceId = null;
  }

  Future<void> _emitWithPayments(
    JobWorkInvoice invoice,
    Emitter<JobWorkInvoiceState> emit, {
    bool saved = false,
    bool paymentRecorded = false,
  }) async {
    await _paymentRepository.ensureInvoicePaidAmountRecorded(
      invoiceId: invoice.id,
      invoiceType: InvoiceType.jobWork,
    );
    final invoicePayments = await _paymentRepository.getPaymentsForInvoice(
      factoryId: invoice.factoryId,
      invoiceId: invoice.id,
    );

    emit(
      state.copyWith(
        status: paymentRecorded
            ? JobWorkInvoiceStatus.paymentRecorded
            : saved
                ? JobWorkInvoiceStatus.generated
                : JobWorkInvoiceStatus.loaded,
        invoice: invoice,
        payments: invoicePayments,
        jobWorkId: invoice.jobWorkId,
        errorMessage: null,
      ),
    );
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
