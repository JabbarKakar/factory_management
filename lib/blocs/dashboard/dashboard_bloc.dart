import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/job_work_invoice_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/sales_invoice_repository.dart';
import '../../data/services/payment_due_scanner_service.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/dashboard_kpis.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/sales_invoice.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required PaymentRepository paymentRepository,
    required JobWorkRepository jobWorkRepository,
    required CustomerRepository customerRepository,
    required JobWorkInvoiceRepository jobWorkInvoiceRepository,
    required SalesInvoiceRepository salesInvoiceRepository,
    required PaymentDueScannerService scannerService,
  })  : _paymentRepository = paymentRepository,
        _jobWorkRepository = jobWorkRepository,
        _customerRepository = customerRepository,
        _jobWorkInvoiceRepository = jobWorkInvoiceRepository,
        _salesInvoiceRepository = salesInvoiceRepository,
        _scannerService = scannerService,
        super(const DashboardState()) {
    on<DashboardWatchStarted>(_onWatchStarted);
    on<DashboardWatchStopped>(_onWatchStopped);
    on<_DashboardDataUpdated>(_onDataUpdated);
    on<_DashboardStreamFailed>(_onStreamFailed);
  }

  final PaymentRepository _paymentRepository;
  final JobWorkRepository _jobWorkRepository;
  final CustomerRepository _customerRepository;
  final JobWorkInvoiceRepository _jobWorkInvoiceRepository;
  final SalesInvoiceRepository _salesInvoiceRepository;
  final PaymentDueScannerService _scannerService;

  StreamSubscription<List<Payment>>? _paymentsSub;
  StreamSubscription<List<JobWorkOrder>>? _jobWorkSub;
  StreamSubscription<List<Customer>>? _customersSub;
  StreamSubscription<List<JobWorkInvoice>>? _jobWorkInvoicesSub;
  StreamSubscription<List<SalesInvoice>>? _salesInvoicesSub;

  List<Payment> _payments = const [];
  List<JobWorkOrder> _orders = const [];
  List<Customer> _customers = const [];
  List<JobWorkInvoice> _jobWorkInvoices = const [];
  List<SalesInvoice> _salesInvoices = const [];

  Future<void> _onWatchStarted(
    DashboardWatchStarted event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(status: DashboardStatus.loading, factoryId: event.factoryId));
    await _cancelSubscriptions();

    _paymentsSub = _paymentRepository
        .watchPaymentsForFactory(event.factoryId)
        .listen(
          (payments) {
            _payments = payments;
            add(const _DashboardDataUpdated());
          },
          onError: (_) => add(
            const _DashboardStreamFailed('Could not load dashboard data.'),
          ),
        );

    _jobWorkSub = _jobWorkRepository
        .watchJobWorkOrders(event.factoryId)
        .listen(
          (orders) {
            _orders = orders;
            add(const _DashboardDataUpdated());
          },
          onError: (_) => add(
            const _DashboardStreamFailed('Could not load dashboard data.'),
          ),
        );

    _customersSub = _customerRepository
        .watchCustomers(event.factoryId)
        .listen(
          (customers) {
            _customers = customers;
            add(const _DashboardDataUpdated());
          },
          onError: (_) => add(
            const _DashboardStreamFailed('Could not load dashboard data.'),
          ),
        );

    _jobWorkInvoicesSub = _jobWorkInvoiceRepository
        .watchOpenInvoicesForFactory(event.factoryId)
        .listen(
          (invoices) {
            _jobWorkInvoices = invoices;
            add(const _DashboardDataUpdated());
          },
          onError: (_) => add(
            const _DashboardStreamFailed('Could not load dashboard data.'),
          ),
        );

    _salesInvoicesSub = _salesInvoiceRepository
        .watchOpenInvoicesForFactory(event.factoryId)
        .listen(
          (invoices) {
            _salesInvoices = invoices;
            add(const _DashboardDataUpdated());
          },
          onError: (_) => add(
            const _DashboardStreamFailed('Could not load dashboard data.'),
          ),
        );
  }

  Future<void> _onWatchStopped(
    DashboardWatchStopped event,
    Emitter<DashboardState> emit,
  ) async {
    await _cancelSubscriptions();
  }

  void _onDataUpdated(
    _DashboardDataUpdated event,
    Emitter<DashboardState> emit,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final revenueToday = _payments
        .where((payment) => _isSameDay(payment.paymentDate, today))
        .fold<double>(0, (sum, payment) => sum + payment.amount);

    final activeJobWorkCount =
        _orders.where((order) => order.status.isActive).length;

    final overdueSummary = _scannerService.summarizeAll(
      jobWorkInvoices: _jobWorkInvoices,
      salesInvoices: _salesInvoices,
    );

    emit(
      state.copyWith(
        status: DashboardStatus.loaded,
        kpis: DashboardKpis(
          revenueToday: revenueToday,
          activeJobWorkCount: activeJobWorkCount,
          overdueAmount: overdueSummary.overdueAmount,
          overdueCount: overdueSummary.overdueCount,
          customerCount: _customers.length,
        ),
        errorMessage: null,
      ),
    );
  }

  void _onStreamFailed(
    _DashboardStreamFailed event,
    Emitter<DashboardState> emit,
  ) {
    emit(
      state.copyWith(
        status: DashboardStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _cancelSubscriptions() async {
    await _paymentsSub?.cancel();
    await _jobWorkSub?.cancel();
    await _customersSub?.cancel();
    await _jobWorkInvoicesSub?.cancel();
    await _salesInvoicesSub?.cancel();
    _paymentsSub = null;
    _jobWorkSub = null;
    _customersSub = null;
    _jobWorkInvoicesSub = null;
    _salesInvoicesSub = null;
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}

final class _DashboardDataUpdated extends DashboardEvent {
  const _DashboardDataUpdated();
}

final class _DashboardStreamFailed extends DashboardEvent {
  const _DashboardStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
