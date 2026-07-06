import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/sales_invoice_repository.dart';
import '../../data/services/customer_ledger_service.dart';
import '../../data/services/payment_due_scanner_service.dart';
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

  Future<void> _emitWithPayments(
    SalesInvoice invoice,
    Emitter<SalesInvoiceState> emit, {
    bool saved = false,
    bool paymentRecorded = false,
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
        status: paymentRecorded
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
