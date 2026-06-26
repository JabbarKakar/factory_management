import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/job_work_invoice_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/raw_material_repository.dart';
import '../../data/repositories/sales_invoice_repository.dart';
import '../../data/repositories/sales_order_repository.dart';
import '../../data/services/payment_due_scanner_service.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/dashboard_kpis.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/raw_material.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/entities/sales_order.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required PaymentRepository paymentRepository,
    required JobWorkRepository jobWorkRepository,
    required SalesOrderRepository salesOrderRepository,
    required CustomerRepository customerRepository,
    required JobWorkInvoiceRepository jobWorkInvoiceRepository,
    required SalesInvoiceRepository salesInvoiceRepository,
    required ExpenseRepository expenseRepository,
    required RawMaterialRepository rawMaterialRepository,
    required PaymentDueScannerService scannerService,
  })  : _paymentRepository = paymentRepository,
        _jobWorkRepository = jobWorkRepository,
        _salesOrderRepository = salesOrderRepository,
        _customerRepository = customerRepository,
        _jobWorkInvoiceRepository = jobWorkInvoiceRepository,
        _salesInvoiceRepository = salesInvoiceRepository,
        _expenseRepository = expenseRepository,
        _rawMaterialRepository = rawMaterialRepository,
        _scannerService = scannerService,
        super(const DashboardState()) {
    on<DashboardWatchStarted>(_onWatchStarted);
    on<DashboardWatchStopped>(_onWatchStopped);
    on<_DashboardDataUpdated>(_onDataUpdated);
    on<_DashboardStreamFailed>(_onStreamFailed);
  }

  final PaymentRepository _paymentRepository;
  final JobWorkRepository _jobWorkRepository;
  final SalesOrderRepository _salesOrderRepository;
  final CustomerRepository _customerRepository;
  final JobWorkInvoiceRepository _jobWorkInvoiceRepository;
  final SalesInvoiceRepository _salesInvoiceRepository;
  final ExpenseRepository _expenseRepository;
  final RawMaterialRepository _rawMaterialRepository;
  final PaymentDueScannerService _scannerService;

  StreamSubscription<List<Payment>>? _paymentsSub;
  StreamSubscription<List<JobWorkOrder>>? _jobWorkSub;
  StreamSubscription<List<SalesOrder>>? _salesSub;
  StreamSubscription<List<Customer>>? _customersSub;
  StreamSubscription<List<JobWorkInvoice>>? _jobWorkInvoicesSub;
  StreamSubscription<List<SalesInvoice>>? _salesInvoicesSub;
  StreamSubscription<List<Expense>>? _expensesSub;
  StreamSubscription<List<RawMaterial>>? _rawMaterialsSub;

  List<Payment> _payments = const [];
  List<JobWorkOrder> _orders = const [];
  List<SalesOrder> _salesOrders = const [];
  List<Customer> _customers = const [];
  List<JobWorkInvoice> _jobWorkInvoices = const [];
  List<SalesInvoice> _salesInvoices = const [];
  List<Expense> _expenses = const [];
  List<RawMaterial> _rawMaterials = const [];

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

    _salesSub = _salesOrderRepository
        .watchSalesOrders(event.factoryId)
        .listen(
          (orders) {
            _salesOrders = orders;
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

    _expensesSub = _expenseRepository
        .watchExpenses(event.factoryId)
        .listen(
          (expenses) {
            _expenses = expenses;
            add(const _DashboardDataUpdated());
          },
          onError: (_) => add(
            const _DashboardStreamFailed('Could not load dashboard data.'),
          ),
        );

    _rawMaterialsSub = _rawMaterialRepository
        .watchMaterials(event.factoryId)
        .listen(
          (materials) {
            _rawMaterials = materials;
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

    final activeSalesCount =
        _salesOrders.where((order) => order.status.isActive).length;

    final pendingPickupCount =
        _orders.where((order) => order.status.isPendingPickup).length;

    final pendingPickups = _orders
        .where((order) => order.status.isPendingPickup)
        .toList()
      ..sort((a, b) {
        final rankCompare = a.status.listSortRank.compareTo(b.status.listSortRank);
        if (rankCompare != 0) return rankCompare;
        return a.createdAt.compareTo(b.createdAt);
      });

    final overdueSummary = _scannerService.summarizeAll(
      jobWorkInvoices: _jobWorkInvoices,
      salesInvoices: _salesInvoices,
    );

    final expensesThisMonthList = _expenses.where((expense) {
      final date = expense.expenseDate;
      return date.year == now.year && date.month == now.month;
    }).toList();

    final expensesThisMonth = expensesThisMonthList.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final lowStockCount =
        _rawMaterials.where((material) => material.isLowStock).length;

    emit(
      state.copyWith(
        status: DashboardStatus.loaded,
        kpis: DashboardKpis(
          revenueToday: revenueToday,
          activeJobWorkCount: activeJobWorkCount,
          activeSalesCount: activeSalesCount,
          pendingPickupCount: pendingPickupCount,
          expensesThisMonth: expensesThisMonth,
          expenseCountThisMonth: expensesThisMonthList.length,
          lowStockCount: lowStockCount,
          overdueAmount: overdueSummary.overdueAmount,
          overdueCount: overdueSummary.overdueCount,
          customerCount: _customers.length,
        ),
        pendingPickups: pendingPickups.take(5).toList(),
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
    await _salesSub?.cancel();
    await _customersSub?.cancel();
    await _jobWorkInvoicesSub?.cancel();
    await _salesInvoicesSub?.cancel();
    await _expensesSub?.cancel();
    await _rawMaterialsSub?.cancel();
    _paymentsSub = null;
    _jobWorkSub = null;
    _salesSub = null;
    _customersSub = null;
    _jobWorkInvoicesSub = null;
    _salesInvoicesSub = null;
    _expensesSub = null;
    _rawMaterialsSub = null;
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
