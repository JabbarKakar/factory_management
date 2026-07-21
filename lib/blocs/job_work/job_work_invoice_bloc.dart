import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/invoice_exception.dart';
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
    on<JobWorkInvoiceLoadByLoad>(_onLoadByLoad);
    on<JobWorkInvoiceLoadById>(_onLoadById);
    on<JobWorkInvoiceGenerateFromLoadRequested>(_onGenerateFromLoad);
    on<JobWorkInvoiceGenerateFromJobWorkRequested>(_onGenerateFromJobWork);
    on<JobWorkInvoicePaymentSubmitted>(_onPaymentSubmitted);
    on<JobWorkInvoicePaymentUpdated>(_onPaymentUpdated);
    on<JobWorkInvoicePaymentDeleteRequested>(_onPaymentDeleteRequested);
    on<JobWorkInvoiceUpdateRequested>(_onUpdateRequested);
    on<_JobWorkInvoiceStreamUpdated>(_onInvoiceStreamUpdated);
    on<_JobWorkInvoicePaymentsUpdated>(_onPaymentsStreamUpdated);
  }

  final JobWorkInvoiceRepository _invoiceRepository;
  final PaymentRepository _paymentRepository;
  final CustomerLedgerService _ledgerService;
  final PaymentDueScannerService _scannerService;
  StreamSubscription<JobWorkInvoice?>? _invoiceSubscription;
  StreamSubscription<List<Payment>>? _paymentsSubscription;
  StreamSubscription<List<JobWorkInvoice>>? _allInvoicesSubscription;
  final Map<String, StreamSubscription<List<Payment>>> _paymentSubsByInvoice = {};
  final Map<String, List<Payment>> _paymentsByInvoiceId = {};
  String? _watchedInvoiceId;

  Future<void> _onLoadByJobWork(
    JobWorkInvoiceLoadByJobWork event,
    Emitter<JobWorkInvoiceState> emit,
  ) async {
    await _cancelSubscriptions();
    emit(
      state.copyWith(
        status: JobWorkInvoiceStatus.loading,
        clearLoadId: true,
      ),
    );
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
      await _startWatching(invoice, emit, watchAllJobWorkPayments: true);
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

  Future<void> _onLoadByLoad(
    JobWorkInvoiceLoadByLoad event,
    Emitter<JobWorkInvoiceState> emit,
  ) async {
    await _cancelSubscriptions();
    emit(
      state.copyWith(
        status: JobWorkInvoiceStatus.loading,
        jobWorkId: event.jobWorkId,
        loadId: event.loadId,
      ),
    );
    try {
      final invoice = await _invoiceRepository.getInvoiceForLoad(
        factoryId: event.factoryId,
        loadId: event.loadId,
      );
      if (invoice == null) {
        emit(
          state.copyWith(
            status: JobWorkInvoiceStatus.notFound,
            jobWorkId: event.jobWorkId,
            loadId: event.loadId,
          ),
        );
        _invoiceSubscription = _invoiceRepository
            .watchInvoiceByLoadId(
              factoryId: event.factoryId,
              loadId: event.loadId,
            )
            .asyncMap((updated) async {
              if (updated != null) return updated;
              return _invoiceRepository.getInvoiceForLoad(
                factoryId: event.factoryId,
                loadId: event.loadId,
              );
            })
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

  Future<void> _onGenerateFromLoad(
    JobWorkInvoiceGenerateFromLoadRequested event,
    Emitter<JobWorkInvoiceState> emit,
  ) async {
    emit(
      state.copyWith(
        status: JobWorkInvoiceStatus.saving,
        jobWorkId: event.jobWorkId,
        loadId: event.loadId,
      ),
    );
    try {
      final invoice = await _invoiceRepository.generateFromLoad(event.loadId);
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

  Future<void> _onGenerateFromJobWork(
    JobWorkInvoiceGenerateFromJobWorkRequested event,
    Emitter<JobWorkInvoiceState> emit,
  ) async {
    emit(
      state.copyWith(
        status: JobWorkInvoiceStatus.saving,
        jobWorkId: event.jobWorkId,
      ),
    );
    try {
      final invoice = await _invoiceRepository.generateFromJobWorkOrder(event.jobWorkId);
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

  Future<void> _onPaymentUpdated(
    JobWorkInvoicePaymentUpdated event,
    Emitter<JobWorkInvoiceState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkInvoiceStatus.saving));
    try {
      await _paymentRepository.updatePayment(
        paymentId: event.paymentId,
        amount: event.amount,
        method: event.method,
        paymentDate: event.paymentDate,
        reference: event.reference,
        notes: event.notes,
      );
      final invoiceId = state.invoice?.id;
      if (invoiceId == null) {
        emit(
          state.copyWith(
            status: JobWorkInvoiceStatus.failure,
            errorMessage: 'Invoice not found after payment update.',
          ),
        );
        return;
      }
      final invoice = await _invoiceRepository.getInvoice(invoiceId);
      if (invoice == null) {
        emit(
          state.copyWith(
            status: JobWorkInvoiceStatus.failure,
            errorMessage: 'Invoice not found after payment update.',
          ),
        );
        return;
      }
      await _startWatching(invoice, emit, paymentRecorded: true);
    } catch (e) {
      emit(
        state.copyWith(
          status: JobWorkInvoiceStatus.failure,
          errorMessage: e is PaymentException
              ? e.message
              : e is StateError
                  ? e.message
                  : 'Could not update payment.',
        ),
      );
    }
  }

  Future<void> _onPaymentDeleteRequested(
    JobWorkInvoicePaymentDeleteRequested event,
    Emitter<JobWorkInvoiceState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkInvoiceStatus.saving));
    try {
      await _paymentRepository.deletePayment(event.paymentId);
      final invoiceId = state.invoice?.id;
      if (invoiceId == null) return;
      final invoice = await _invoiceRepository.getInvoice(invoiceId);
      if (invoice == null) return;
      await _startWatching(invoice, emit, paymentRecorded: true);
    } catch (e) {
      emit(
        state.copyWith(
          status: JobWorkInvoiceStatus.failure,
          errorMessage: e is PaymentException
              ? e.message
              : 'Could not delete payment.',
        ),
      );
    }
  }

  Future<void> _onUpdateRequested(
    JobWorkInvoiceUpdateRequested event,
    Emitter<JobWorkInvoiceState> emit,
  ) async {
    final invoice = state.invoice;
    if (invoice == null) return;

    emit(state.copyWith(status: JobWorkInvoiceStatus.saving));
    try {
      final updated = await _invoiceRepository.updateInvoiceDetails(
        existing: invoice,
        lineItems: event.lineItems,
        dueDate: event.dueDate,
        mineLocation: event.mineLocation,
        mineOwner: event.mineOwner,
      );
      await _ledgerService.syncCustomerBalance(updated.customerId);
      await _startWatching(updated, emit, updated: true);
    } on InvoiceException catch (error) {
      emit(
        state.copyWith(
          status: JobWorkInvoiceStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: JobWorkInvoiceStatus.failure,
          errorMessage: 'Could not update invoice.',
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
    if (state.loadId == null || state.loadId!.isEmpty) {
      _ensurePaymentsWatchForJobWork(invoice.factoryId, invoice.jobWorkId);
    } else {
      _ensurePaymentsWatch(invoice);
    }

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
    bool updated = false,
    bool watchAllJobWorkPayments = false,
  }) async {
    await _emitWithPayments(
      invoice,
      emit,
      saved: saved,
      paymentRecorded: paymentRecorded,
      updated: updated,
    );

    _invoiceSubscription?.cancel();
    _invoiceSubscription = _invoiceRepository.watchInvoice(invoice.id).listen(
          (updated) {
            if (!isClosed) add(_JobWorkInvoiceStreamUpdated(updated));
          },
          onError: (_) {},
        );
    if (watchAllJobWorkPayments || state.loadId == null || state.loadId!.isEmpty) {
      _ensurePaymentsWatchForJobWork(invoice.factoryId, invoice.jobWorkId);
    } else {
      _ensurePaymentsWatch(invoice);
    }
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
          (payments) {
            if (!isClosed) add(_JobWorkInvoicePaymentsUpdated(payments));
          },
          onError: (_) {},
        );
  }

  void _ensurePaymentsWatchForJobWork(String factoryId, String jobWorkId) {
    _allInvoicesSubscription?.cancel();
    _allInvoicesSubscription = _invoiceRepository
        .watchInvoicesByJobWorkId(
          factoryId: factoryId,
          jobWorkId: jobWorkId,
        )
        .listen(
          (invoices) {
            final ids = invoices.map((i) => i.id).toSet();
            final toCancel = _paymentSubsByInvoice.keys.where((id) => !ids.contains(id)).toList();
            for (final id in toCancel) {
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
                          .toList()
                        ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
                      if (!isClosed) add(_JobWorkInvoicePaymentsUpdated(merged));
                    },
                    onError: (_) {},
                  );
            }
          },
          onError: (_) {},
        );
  }

  Future<void> _cancelSubscriptions() async {
    await _invoiceSubscription?.cancel();
    await _paymentsSubscription?.cancel();
    await _allInvoicesSubscription?.cancel();
    for (final sub in _paymentSubsByInvoice.values) {
      await sub.cancel();
    }
    _invoiceSubscription = null;
    _paymentsSubscription = null;
    _allInvoicesSubscription = null;
    _paymentSubsByInvoice.clear();
    _paymentsByInvoiceId.clear();
    _watchedInvoiceId = null;
  }

  Future<void> _emitWithPayments(
    JobWorkInvoice invoice,
    Emitter<JobWorkInvoiceState> emit, {
    bool saved = false,
    bool paymentRecorded = false,
    bool updated = false,
  }) async {
    final List<Payment> invoicePayments;
    var effectiveInvoice = invoice;

    if (state.loadId == null || state.loadId!.isEmpty) {
      final invoices = await _invoiceRepository.getInvoicesByJobWorkId(
        factoryId: invoice.factoryId,
        jobWorkId: invoice.jobWorkId,
      );
      final allPayments = <Payment>[];
      for (final inv in invoices) {
        await _paymentRepository.ensureInvoicePaidAmountRecorded(
          invoiceId: inv.id,
          invoiceType: InvoiceType.jobWork,
        );
        final pmts = await _paymentRepository.getPaymentsForInvoice(
          factoryId: inv.factoryId,
          invoiceId: inv.id,
        );
        allPayments.addAll(pmts);
      }
      allPayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      invoicePayments = allPayments;

      final totalPaidFromPayments =
          invoicePayments.fold<double>(0, (sum, p) => sum + p.amount);
      if (invoicePayments.isNotEmpty &&
          (invoice.paidAmount - totalPaidFromPayments).abs() > 0.01) {
        final newDue = (invoice.totalAmount - totalPaidFromPayments)
            .clamp(0, invoice.totalAmount)
            .toDouble();
        final newStatus = InvoiceStatus.fromAmounts(
          dueAmount: newDue,
          paidAmount: totalPaidFromPayments,
          totalAmount: invoice.totalAmount,
          dueDate: invoice.dueDate,
        );
        effectiveInvoice = invoice.copyWith(
          paidAmount: totalPaidFromPayments,
          dueAmount: newDue,
          status: newStatus,
          updatedAt: DateTime.now(),
        );

        await _invoiceRepository.updateInvoicePaidAndDue(
          invoiceId: invoice.id,
          paidAmount: totalPaidFromPayments,
          dueAmount: newDue,
          status: newStatus,
        );
      }
    } else {
      await _paymentRepository.ensureInvoicePaidAmountRecorded(
        invoiceId: invoice.id,
        invoiceType: InvoiceType.jobWork,
      );
      invoicePayments = await _paymentRepository.getPaymentsForInvoice(
        factoryId: invoice.factoryId,
        invoiceId: invoice.id,
      );
    }

    emit(
      state.copyWith(
        status: updated
            ? JobWorkInvoiceStatus.updated
            : paymentRecorded
                ? JobWorkInvoiceStatus.paymentRecorded
                : saved
                    ? JobWorkInvoiceStatus.generated
                    : JobWorkInvoiceStatus.loaded,
        invoice: effectiveInvoice,
        payments: invoicePayments,
        jobWorkId: effectiveInvoice.jobWorkId,
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
