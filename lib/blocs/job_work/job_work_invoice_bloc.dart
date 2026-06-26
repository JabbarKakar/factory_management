import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/job_work_invoice_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/services/customer_ledger_service.dart';
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
  })  : _invoiceRepository = invoiceRepository,
        _paymentRepository = paymentRepository,
        _ledgerService = ledgerService,
        super(const JobWorkInvoiceState()) {
    on<JobWorkInvoiceLoadByJobWork>(_onLoadByJobWork);
    on<JobWorkInvoiceLoadById>(_onLoadById);
    on<JobWorkInvoiceGenerateRequested>(_onGenerate);
    on<JobWorkInvoicePaymentSubmitted>(_onPaymentSubmitted);
  }

  final JobWorkInvoiceRepository _invoiceRepository;
  final PaymentRepository _paymentRepository;
  final CustomerLedgerService _ledgerService;

  Future<void> _onLoadByJobWork(
    JobWorkInvoiceLoadByJobWork event,
    Emitter<JobWorkInvoiceState> emit,
  ) async {
    emit(state.copyWith(status: JobWorkInvoiceStatus.loading));
    try {
      final invoice =
          await _invoiceRepository.getInvoiceByJobWorkId(event.jobWorkId);
      if (invoice == null) {
        emit(
          state.copyWith(
            status: JobWorkInvoiceStatus.notFound,
            jobWorkId: event.jobWorkId,
          ),
        );
        return;
      }
      await _emitWithPayments(invoice, emit);
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
      await _emitWithPayments(invoice, emit);
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
      await _ledgerService.syncCustomerBalance(invoice.customerId);
      await _emitWithPayments(invoice, emit, saved: true);
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
      await _emitWithPayments(invoice, emit, paymentRecorded: true);
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

  Future<void> _emitWithPayments(
    JobWorkInvoice invoice,
    Emitter<JobWorkInvoiceState> emit, {
    bool saved = false,
    bool paymentRecorded = false,
  }) async {
    final payments =
        await _paymentRepository.getPaymentsForCustomer(invoice.customerId);
    final invoicePayments = payments
        .where((payment) => payment.invoiceId == invoice.id)
        .toList();

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
}
