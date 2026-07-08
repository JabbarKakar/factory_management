import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/invoice_exception.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/sales_invoice_repository.dart';
import '../../data/services/customer_ledger_service.dart';
import '../../data/services/payment_due_scanner_service.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/enums/invoice_enums.dart';

part 'sales_invoice_event.dart';
part 'sales_invoice_state.dart';

class SalesInvoiceBloc extends Bloc<SalesInvoiceEvent, SalesInvoiceState> {
  SalesInvoiceBloc({
    required SalesInvoiceRepository invoiceRepository,
    required PaymentRepository paymentRepository,
    required CustomerLedgerService ledgerService,
    required PaymentDueScannerService scannerService,
  })  : _invoiceRepository = invoiceRepository,
        _paymentRepository = paymentRepository,
        _ledgerService = ledgerService,
        _scannerService = scannerService,
        super(const SalesInvoiceState()) {
    on<SalesInvoiceLoadByOrder>(_onLoadByOrder);
    on<SalesInvoiceLoadById>(_onLoadById);
    on<SalesInvoiceGenerateRequested>(_onGenerate);
    on<SalesInvoicePaymentSubmitted>(_onPaymentSubmitted);
    on<SalesInvoicePaymentUpdated>(_onPaymentUpdated);
    on<SalesInvoicePaymentDeleteRequested>(_onPaymentDeleteRequested);
    on<SalesInvoiceUpdateRequested>(_onUpdateRequested);
  }

  final SalesInvoiceRepository _invoiceRepository;
  final PaymentRepository _paymentRepository;
  final CustomerLedgerService _ledgerService;
  final PaymentDueScannerService _scannerService;

  Future<void> _onLoadByOrder(
    SalesInvoiceLoadByOrder event,
    Emitter<SalesInvoiceState> emit,
  ) async {
    emit(state.copyWith(status: SalesInvoiceStatus.loading));
    try {
      final invoice = await _invoiceRepository.getInvoiceBySalesOrderId(
        factoryId: event.factoryId,
        salesOrderId: event.salesOrderId,
      );
      if (invoice == null) {
        emit(
          state.copyWith(
            status: SalesInvoiceStatus.notFound,
            salesOrderId: event.salesOrderId,
          ),
        );
        return;
      }
      await _emitWithPayments(invoice, emit);
    } catch (_) {
      emit(
        state.copyWith(
          status: SalesInvoiceStatus.failure,
          errorMessage: 'Could not load invoice.',
        ),
      );
    }
  }

  Future<void> _onLoadById(
    SalesInvoiceLoadById event,
    Emitter<SalesInvoiceState> emit,
  ) async {
    emit(state.copyWith(status: SalesInvoiceStatus.loading));
    try {
      final invoice = await _invoiceRepository.getInvoice(event.invoiceId);
      if (invoice == null) {
        emit(
          state.copyWith(
            status: SalesInvoiceStatus.failure,
            errorMessage: 'Invoice not found.',
          ),
        );
        return;
      }
      await _emitWithPayments(invoice, emit);
    } catch (_) {
      emit(
        state.copyWith(
          status: SalesInvoiceStatus.failure,
          errorMessage: 'Could not load invoice.',
        ),
      );
    }
  }

  Future<void> _onGenerate(
    SalesInvoiceGenerateRequested event,
    Emitter<SalesInvoiceState> emit,
  ) async {
    emit(state.copyWith(status: SalesInvoiceStatus.saving));
    try {
      final invoice =
          await _invoiceRepository.generateFromSalesOrder(event.salesOrderId);
      await _paymentRepository.ensureInvoicePaidAmountRecorded(
        invoiceId: invoice.id,
        invoiceType: InvoiceType.sales,
      );
      await _ledgerService.syncCustomerBalance(invoice.customerId);
      await _scannerService.scan(invoice.factoryId);
      await _emitWithPayments(invoice, emit, saved: true);
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesInvoiceStatus.failure,
          errorMessage:
              e is StateError ? e.message : 'Could not generate invoice.',
        ),
      );
    }
  }

  Future<void> _onPaymentSubmitted(
    SalesInvoicePaymentSubmitted event,
    Emitter<SalesInvoiceState> emit,
  ) async {
    emit(state.copyWith(status: SalesInvoiceStatus.saving));
    try {
      await _paymentRepository.recordSalesPayment(
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
            status: SalesInvoiceStatus.failure,
            errorMessage: 'Invoice not found after payment.',
          ),
        );
        return;
      }
      await _emitWithPayments(invoice, emit, paymentRecorded: true);
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesInvoiceStatus.failure,
          errorMessage:
              e is StateError ? e.message : 'Could not record payment.',
        ),
      );
    }
  }

  Future<void> _onPaymentUpdated(
    SalesInvoicePaymentUpdated event,
    Emitter<SalesInvoiceState> emit,
  ) async {
    emit(state.copyWith(status: SalesInvoiceStatus.saving));
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
            status: SalesInvoiceStatus.failure,
            errorMessage: 'Invoice not found after payment update.',
          ),
        );
        return;
      }
      final invoice = await _invoiceRepository.getInvoice(invoiceId);
      if (invoice == null) {
        emit(
          state.copyWith(
            status: SalesInvoiceStatus.failure,
            errorMessage: 'Invoice not found after payment update.',
          ),
        );
        return;
      }
      await _emitWithPayments(invoice, emit, paymentRecorded: true);
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesInvoiceStatus.failure,
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
    SalesInvoicePaymentDeleteRequested event,
    Emitter<SalesInvoiceState> emit,
  ) async {
    emit(state.copyWith(status: SalesInvoiceStatus.saving));
    try {
      await _paymentRepository.deletePayment(event.paymentId);
      final invoiceId = state.invoice?.id;
      if (invoiceId == null) return;
      final invoice = await _invoiceRepository.getInvoice(invoiceId);
      if (invoice == null) return;
      await _emitWithPayments(invoice, emit, paymentRecorded: true);
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesInvoiceStatus.failure,
          errorMessage: e is PaymentException
              ? e.message
              : 'Could not delete payment.',
        ),
      );
    }
  }

  Future<void> _onUpdateRequested(
    SalesInvoiceUpdateRequested event,
    Emitter<SalesInvoiceState> emit,
  ) async {
    final invoice = state.invoice;
    if (invoice == null) return;

    emit(state.copyWith(status: SalesInvoiceStatus.saving));
    try {
      final updated = await _invoiceRepository.updateInvoiceDetails(
        existing: invoice,
        lineItems: event.lineItems,
        dueDate: event.dueDate,
      );
      await _ledgerService.syncCustomerBalance(updated.customerId);
      await _emitWithPayments(updated, emit, updated: true);
    } on InvoiceException catch (error) {
      emit(
        state.copyWith(
          status: SalesInvoiceStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SalesInvoiceStatus.failure,
          errorMessage: 'Could not update invoice.',
        ),
      );
    }
  }

  Future<void> _emitWithPayments(
    SalesInvoice invoice,
    Emitter<SalesInvoiceState> emit, {
    bool saved = false,
    bool paymentRecorded = false,
    bool updated = false,
  }) async {
    await _paymentRepository.ensureInvoicePaidAmountRecorded(
      invoiceId: invoice.id,
      invoiceType: InvoiceType.sales,
    );
    final invoicePayments = await _paymentRepository.getPaymentsForInvoice(
      factoryId: invoice.factoryId,
      invoiceId: invoice.id,
    );

    emit(
      state.copyWith(
        status: updated
            ? SalesInvoiceStatus.updated
            : paymentRecorded
                ? SalesInvoiceStatus.paymentRecorded
                : saved
                    ? SalesInvoiceStatus.generated
                    : SalesInvoiceStatus.loaded,
        invoice: invoice,
        payments: invoicePayments,
        salesOrderId: invoice.salesOrderId,
        errorMessage: null,
      ),
    );
  }
}
