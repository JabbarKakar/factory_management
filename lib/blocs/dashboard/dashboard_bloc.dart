import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/date_keys.dart';
import '../../core/utils/dashboard_command_center_builder.dart';
import '../../core/utils/dashboard_job_work_metrics.dart';
import '../../core/utils/dashboard_query_window.dart';
import '../../core/utils/dashboard_sales_sqft_metrics.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../data/repositories/employee_repository.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/job_work_collection_repository.dart';
import '../../data/repositories/job_work_invoice_repository.dart';
import '../../data/repositories/job_work_load_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/production_repository.dart';
import '../../data/repositories/quality_check_repository.dart';
import '../../data/repositories/raw_material_repository.dart';
import '../../data/repositories/sales_invoice_repository.dart';
import '../../data/repositories/sales_order_repository.dart';
import '../../data/services/dashboard_analytics_service.dart';
import '../../data/services/job_work_collection_quantity_helper.dart';
import '../../data/services/job_work_load_production_helper.dart';
import '../../data/services/payment_due_scanner_service.dart';
import '../../data/services/sales_container_sync_helper.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/entities/dashboard_cashflow_metrics.dart';
import '../../domain/entities/dashboard_command_center.dart';
import '../../domain/entities/dashboard_kpis.dart';
import '../../domain/entities/dashboard_pending_pickup.dart';
import '../../domain/entities/dashboard_sales_sqft_metrics.dart';
import '../../domain/entities/dashboard_stock_cut_metrics.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/job_work_collection.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/production_batch.dart';
import '../../domain/entities/quality_check.dart';
import '../../domain/entities/raw_material.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/dashboard_finance_period.dart';
import '../../domain/enums/delivery_enums.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/labour_enums.dart';
import '../../domain/enums/quality_enums.dart';
import '../../domain/enums/sales_agreement_enums.dart';

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
    required EmployeeRepository employeeRepository,
    required AttendanceRepository attendanceRepository,
    required DeliveryRepository deliveryRepository,
    required JobWorkCollectionRepository jobWorkCollectionRepository,
    required JobWorkLoadRepository jobWorkLoadRepository,
    required EquipmentRepository equipmentRepository,
    required QualityCheckRepository qualityCheckRepository,
    required ProductionRepository productionRepository,
    required PaymentDueScannerService scannerService,
    required DashboardAnalyticsService analyticsService,
  })  : _paymentRepository = paymentRepository,
        _jobWorkRepository = jobWorkRepository,
        _salesOrderRepository = salesOrderRepository,
        _customerRepository = customerRepository,
        _jobWorkInvoiceRepository = jobWorkInvoiceRepository,
        _salesInvoiceRepository = salesInvoiceRepository,
        _expenseRepository = expenseRepository,
        _rawMaterialRepository = rawMaterialRepository,
        _employeeRepository = employeeRepository,
        _attendanceRepository = attendanceRepository,
        _deliveryRepository = deliveryRepository,
        _jobWorkCollectionRepository = jobWorkCollectionRepository,
        _jobWorkLoadRepository = jobWorkLoadRepository,
        _equipmentRepository = equipmentRepository,
        _qualityCheckRepository = qualityCheckRepository,
        _productionRepository = productionRepository,
        _scannerService = scannerService,
        _analyticsService = analyticsService,
        super(const DashboardState()) {
    on<DashboardWatchStarted>(_onWatchStarted);
    on<DashboardWatchStopped>(_onWatchStopped);
    on<DashboardFinancePeriodChanged>(_onFinancePeriodChanged);
    on<DashboardGlobalPeriodChanged>(_onGlobalPeriodChanged);
    on<DashboardStockCutPeriodChanged>(_onStockCutPeriodChanged);
    on<DashboardSalesSqFtPeriodChanged>(_onSalesSqFtPeriodChanged);
    on<_DashboardDataUpdated>(_onDataUpdated);
    on<_DashboardRecomputeRequested>(_onRecomputeRequested);
  }

  final PaymentRepository _paymentRepository;
  final JobWorkRepository _jobWorkRepository;
  final SalesOrderRepository _salesOrderRepository;
  final CustomerRepository _customerRepository;
  final JobWorkInvoiceRepository _jobWorkInvoiceRepository;
  final SalesInvoiceRepository _salesInvoiceRepository;
  final ExpenseRepository _expenseRepository;
  final RawMaterialRepository _rawMaterialRepository;
  final EmployeeRepository _employeeRepository;
  final AttendanceRepository _attendanceRepository;
  final DeliveryRepository _deliveryRepository;
  final JobWorkCollectionRepository _jobWorkCollectionRepository;
  final JobWorkLoadRepository _jobWorkLoadRepository;
  final EquipmentRepository _equipmentRepository;
  final QualityCheckRepository _qualityCheckRepository;
  final ProductionRepository _productionRepository;
  final PaymentDueScannerService _scannerService;
  final DashboardAnalyticsService _analyticsService;

  StreamSubscription<List<Payment>>? _paymentsSub;
  StreamSubscription<List<JobWorkOrder>>? _jobWorkSub;
  StreamSubscription<List<SalesOrder>>? _salesSub;
  StreamSubscription<List<Customer>>? _customersSub;
  StreamSubscription<List<JobWorkInvoice>>? _jobWorkInvoicesSub;
  StreamSubscription<List<SalesInvoice>>? _salesInvoicesSub;

  String? _watchingFactoryId;
  DashboardQueryWindow? _activeWindow;
  int _snapshotGeneration = 0;

  List<Payment> _payments = const [];
  List<JobWorkOrder> _orders = const [];
  List<SalesOrder> _salesOrders = const [];
  List<Customer> _customers = const [];
  List<JobWorkInvoice> _jobWorkInvoices = const [];
  List<SalesInvoice> _salesInvoices = const [];
  List<Expense> _expenses = const [];
  List<RawMaterial> _rawMaterials = const [];
  List<Employee> _employees = const [];
  List<AttendanceRecord> _attendanceToday = const [];
  List<Delivery> _deliveries = const [];
  List<JobWorkCollection> _jobWorkCollections = const [];
  List<JobWorkLoad> _jobWorkLoads = const [];
  List<Equipment> _equipment = const [];
  List<QualityCheck> _qualityChecks = const [];
  List<ProductionBatch> _productionBatches = const [];

  Timer? _recomputeDebounce;

  void _logDashboardError(String name, Object error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('Dashboard $name failed: $error');
    }
  }

  void _handleStreamError(
    String streamName,
    void Function() reset, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logDashboardError(
      'stream ($streamName)',
      error ?? 'unknown error',
      stackTrace,
    );
    reset();
    add(const _DashboardDataUpdated());
  }

  Future<void> _onWatchStarted(
    DashboardWatchStarted event,
    Emitter<DashboardState> emit,
  ) async {
    final window = _queryWindowFor(state);
    final alreadyLive =
        _watchingFactoryId == event.factoryId && _paymentsSub != null;

    if (alreadyLive) {
      if (_activeWindow == null || !window.isSameAs(_activeWindow!)) {
        await _restartPayments(event.factoryId, window);
      }
      await _loadSnapshots(event.factoryId, window);
      return;
    }

    emit(
      state.copyWith(
        status: DashboardStatus.loading,
        factoryId: event.factoryId,
        errorMessage: null,
      ),
    );
    await _cancelSubscriptions();
    _watchingFactoryId = event.factoryId;
    _startLiveListeners(event.factoryId, window);
    await _loadSnapshots(event.factoryId, window);
  }

  DashboardQueryWindow _queryWindowFor(DashboardState current) {
    return DashboardQueryWindow.forDashboard(
      financePeriod: current.financePeriod,
      stockCutPeriod: current.stockCutPeriod,
      salesSqFtPeriod: current.salesSqFtPeriod,
    );
  }

  void _startLiveListeners(String factoryId, DashboardQueryWindow window) {
    _activeWindow = window;

    _subscribePayments(factoryId, window);

    _jobWorkSub = _jobWorkRepository
        .watchJobWorkOrders(
          factoryId,
          limit: DashboardQueryWindow.operationalLimit,
        )
        .listen(
          (orders) {
            _orders = orders;
            add(const _DashboardDataUpdated());
          },
          onError: (Object error, StackTrace stackTrace) =>
              _handleStreamError(
            'jobWork',
            () => _orders = const [],
            error: error,
            stackTrace: stackTrace,
          ),
        );

    _salesSub = _salesOrderRepository
        .watchSalesOrders(
          factoryId,
          limit: DashboardQueryWindow.operationalLimit,
        )
        .listen(
          (orders) {
            _salesOrders = orders;
            add(const _DashboardDataUpdated());
          },
          onError: (Object error, StackTrace stackTrace) =>
              _handleStreamError(
            'salesOrders',
            () => _salesOrders = const [],
            error: error,
            stackTrace: stackTrace,
          ),
        );

    _customersSub = _customerRepository
        .watchCustomers(
          factoryId,
          limit: DashboardQueryWindow.catalogLimit,
        )
        .listen(
          (customers) {
            _customers = customers;
            add(const _DashboardDataUpdated());
          },
          onError: (Object error, StackTrace stackTrace) =>
              _handleStreamError(
            'customers',
            () => _customers = const [],
            error: error,
            stackTrace: stackTrace,
          ),
        );

    _jobWorkInvoicesSub = _jobWorkInvoiceRepository
        .watchInvoicesForFactory(
          factoryId,
          limit: DashboardQueryWindow.operationalLimit,
        )
        .listen(
          (invoices) {
            _jobWorkInvoices = invoices;
            add(const _DashboardDataUpdated());
          },
          onError: (Object error, StackTrace stackTrace) =>
              _handleStreamError(
            'jobWorkInvoices',
            () => _jobWorkInvoices = const [],
            error: error,
            stackTrace: stackTrace,
          ),
        );

    _salesInvoicesSub = _salesInvoiceRepository
        .watchInvoicesForFactory(
          factoryId,
          limit: DashboardQueryWindow.operationalLimit,
        )
        .listen(
          (invoices) {
            _salesInvoices = invoices;
            add(const _DashboardDataUpdated());
          },
          onError: (Object error, StackTrace stackTrace) =>
              _handleStreamError(
            'salesInvoices',
            () => _salesInvoices = const [],
            error: error,
            stackTrace: stackTrace,
          ),
        );
  }

  void _subscribePayments(
    String factoryId,
    DashboardQueryWindow window, {
    bool useWindow = true,
  }) {
    _paymentsSub = _paymentRepository
        .watchPaymentsForFactory(
          factoryId,
          from: useWindow ? window.from : null,
          limit: DashboardQueryWindow.windowedLimit,
        )
        .listen(
          (payments) {
            _payments = payments;
            add(const _DashboardDataUpdated());
          },
          onError: (Object error, StackTrace stackTrace) {
            _logDashboardError('stream (payments)', error, stackTrace);
            if (useWindow) {
              unawaited(_fallbackPayments(factoryId, window));
              return;
            }
            _payments = const [];
            add(const _DashboardDataUpdated());
          },
        );
  }

  Future<void> _fallbackPayments(
    String factoryId,
    DashboardQueryWindow window,
  ) async {
    await _paymentsSub?.cancel();
    _paymentsSub = null;
    if (isClosed) return;
    _subscribePayments(factoryId, window, useWindow: false);
  }

  Future<void> _restartPayments(
    String factoryId,
    DashboardQueryWindow window,
  ) async {
    await _paymentsSub?.cancel();
    _paymentsSub = null;
    _activeWindow = window;
    _subscribePayments(factoryId, window);
  }

  Future<List<T>> _withWindowFallback<T>({
    required String name,
    required Future<List<T>> Function() windowed,
    required Future<List<T>> Function() unwindowed,
  }) async {
    try {
      return await windowed();
    } catch (error, stackTrace) {
      _logDashboardError('$name windowed query', error, stackTrace);
      try {
        return await unwindowed();
      } catch (fallbackError, fallbackStack) {
        _logDashboardError('$name fallback query', fallbackError, fallbackStack);
        return <T>[];
      }
    }
  }

  Future<void> _loadSnapshots(
    String factoryId,
    DashboardQueryWindow window,
  ) async {
    final generation = ++_snapshotGeneration;
    final today = DateKeys.dateOnly(DateTime.now());

    Future<void> take<T>(
      Future<T> future,
      void Function(T value) assign,
    ) async {
      try {
        final value = await future;
        if (generation != _snapshotGeneration || isClosed) return;
        assign(value);
      } catch (error, stackTrace) {
        _logDashboardError('snapshot', error, stackTrace);
      }
    }

    await Future.wait([
      take(
        _withWindowFallback(
          name: 'expenses',
          windowed: () => _expenseRepository.getExpenses(
            factoryId,
            from: window.from,
            limit: DashboardQueryWindow.windowedLimit,
          ),
          unwindowed: () => _expenseRepository.getExpenses(
            factoryId,
            limit: DashboardQueryWindow.windowedLimit,
          ),
        ),
        (value) => _expenses = value,
      ),
      take(
        _rawMaterialRepository.getMaterials(
          factoryId,
          limit: DashboardQueryWindow.catalogLimit,
        ),
        (value) => _rawMaterials = value,
      ),
      take(
        _employeeRepository.getEmployees(
          factoryId,
          limit: DashboardQueryWindow.catalogLimit,
        ),
        (value) => _employees = value,
      ),
      take(
        _attendanceRepository.getForDate(factoryId: factoryId, date: today),
        (value) => _attendanceToday = value,
      ),
      take(
        _deliveryRepository.getDeliveries(
          factoryId,
          limit: DashboardQueryWindow.operationalLimit,
        ),
        (value) => _deliveries = value,
      ),
      take(
        _jobWorkCollectionRepository.getCollections(
          factoryId,
          limit: DashboardQueryWindow.operationalLimit,
        ),
        (value) => _jobWorkCollections = value,
      ),
      take(
        _jobWorkLoadRepository.getLoads(
          factoryId,
          limit: DashboardQueryWindow.operationalLimit,
        ),
        (value) => _jobWorkLoads = value,
      ),
      take(
        _equipmentRepository.getEquipmentList(
          factoryId,
          limit: DashboardQueryWindow.catalogLimit,
        ),
        (value) => _equipment = value,
      ),
      take(
        _qualityCheckRepository.getQualityChecks(
          factoryId,
          limit: DashboardQueryWindow.operationalLimit,
        ),
        (value) => _qualityChecks = value,
      ),
      take(
        _withWindowFallback(
          name: 'production',
          windowed: () => _productionRepository.getBatches(
            factoryId,
            from: window.from,
            limit: DashboardQueryWindow.windowedLimit,
          ),
          unwindowed: () => _productionRepository.getBatches(
            factoryId,
            limit: DashboardQueryWindow.windowedLimit,
          ),
        ),
        (value) => _productionBatches = value,
      ),
    ]);

    if (generation != _snapshotGeneration || isClosed) return;
    add(const _DashboardDataUpdated());
  }

  Future<void> _applyPeriodWindow() async {
    final factoryId = _watchingFactoryId ?? state.factoryId;
    if (factoryId == null || _paymentsSub == null) return;
    final window = _queryWindowFor(state);
    if (_activeWindow != null && window.isSameAs(_activeWindow!)) return;
    await _restartPayments(factoryId, window);
    await _loadSnapshots(factoryId, window);
  }

  Future<void> _onWatchStopped(
    DashboardWatchStopped event,
    Emitter<DashboardState> emit,
  ) async {
    _recomputeDebounce?.cancel();
    await _cancelSubscriptions();
  }

  Future<void> _onFinancePeriodChanged(
    DashboardFinancePeriodChanged event,
    Emitter<DashboardState> emit,
  ) async {
    if (state.financePeriod == event.period) return;
    emit(state.copyWith(financePeriod: event.period));
    await _applyPeriodWindow();
    add(const _DashboardRecomputeRequested());
  }

  Future<void> _onGlobalPeriodChanged(
    DashboardGlobalPeriodChanged event,
    Emitter<DashboardState> emit,
  ) async {
    if (state.financePeriod == event.period &&
        state.stockCutPeriod == event.period &&
        state.salesSqFtPeriod == event.period) {
      return;
    }
    emit(
      state.copyWith(
        financePeriod: event.period,
        stockCutPeriod: event.period,
        salesSqFtPeriod: event.period,
      ),
    );
    await _applyPeriodWindow();
    add(const _DashboardRecomputeRequested());
  }

  Future<void> _onStockCutPeriodChanged(
    DashboardStockCutPeriodChanged event,
    Emitter<DashboardState> emit,
  ) async {
    if (state.stockCutPeriod == event.period) return;
    emit(state.copyWith(stockCutPeriod: event.period));
    await _applyPeriodWindow();
    add(const _DashboardRecomputeRequested());
  }

  Future<void> _onSalesSqFtPeriodChanged(
    DashboardSalesSqFtPeriodChanged event,
    Emitter<DashboardState> emit,
  ) async {
    if (state.salesSqFtPeriod == event.period) return;
    emit(state.copyWith(salesSqFtPeriod: event.period));
    await _applyPeriodWindow();
    add(const _DashboardRecomputeRequested());
  }

  void _onDataUpdated(
    _DashboardDataUpdated event,
    Emitter<DashboardState> emit,
  ) {
    _recomputeDebounce?.cancel();
    _recomputeDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!isClosed) {
        add(const _DashboardRecomputeRequested());
      }
    });
  }

  void _onRecomputeRequested(
    _DashboardRecomputeRequested event,
    Emitter<DashboardState> emit,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final yesterday = today.subtract(const Duration(days: 1));

    final revenueToday = _payments
        .where((payment) => _isSameDay(payment.paymentDate, today))
        .fold<double>(0, (sum, payment) => sum + payment.amount);

    final revenueYesterday = _payments
        .where((payment) => _isSameDay(payment.paymentDate, yesterday))
        .fold<double>(0, (sum, payment) => sum + payment.amount);

    final salesRevenueToday = _payments
        .where(
          (payment) =>
              _isSameDay(payment.paymentDate, today) &&
              payment.invoiceType == InvoiceType.sales,
        )
        .fold<double>(0, (sum, payment) => sum + payment.amount);

    final jobWorkRevenueToday = _payments
        .where(
          (payment) =>
              _isSameDay(payment.paymentDate, today) &&
              payment.invoiceType == InvoiceType.jobWork,
        )
        .fold<double>(0, (sum, payment) => sum + payment.amount);

    final revenueThisMonth = _payments
        .where((payment) {
          final date = payment.paymentDate;
          return date.year == now.year && date.month == now.month;
        })
        .fold<double>(0, (sum, payment) => sum + payment.amount);

    final ownProductionTodaySqFt = _productionBatches
        .where((batch) => _isSameDay(batch.productionDate, today))
        .fold<double>(0, (sum, batch) => sum + batch.totalUsableSqFt);

    final jobWorkOutputTodaySqFt = _orders.fold<double>(
      0,
      (sum, order) => sum +
          DashboardJobWorkMetrics.sqFtOnDay(
            order,
            today,
            loads: _jobWorkLoads,
          ),
    );

    final productionThisMonthSqFt = _productionBatches
        .where((batch) {
          final date = batch.productionDate;
          return date.year == now.year && date.month == now.month;
        })
        .fold<double>(0, (sum, batch) => sum + batch.totalUsableSqFt);

    final persistedLoads =
        _jobWorkLoads.where((load) => !load.isVirtual).toList();
    final ordersWithLoads = {
      for (final load in persistedLoads) load.jobWorkId,
    };

    final activeJobWorkCount = _orders.where((order) {
      final orderLoads = persistedLoads
          .where((load) => load.jobWorkId == order.id)
          .toList();
      if (orderLoads.isEmpty) return order.status.isActive;
      return orderLoads.any((load) => load.status.isActive);
    }).length;

    final activeLoadCount = persistedLoads
        .where((load) => load.status.isActive)
        .length;
    // Legacy JW with no Loads still counts toward active load work.
    final legacyActiveWithoutLoads = _orders
        .where(
          (order) =>
              !ordersWithLoads.contains(order.id) && order.status.isActive,
        )
        .length;
    final activeLoadsAndLegacy = activeLoadCount + legacyActiveWithoutLoads;

    final agreementStatuses =
        SalesContainerSyncHelper.summaryStatusByAgreementId(_salesOrders)
            .values
            .toList();
    final activeSalesCount = agreementStatuses
        .where((status) => status == SalesAgreementSummaryStatus.active)
        .length;

    final pendingPickupCount = persistedLoads
            .where(
              (load) =>
                  JobWorkCollectionQuantityHelper.canOpenCollectMaterialForLoad(
                load,
                _jobWorkCollections,
              ),
            )
            .length +
        _orders
            .where(
              (order) =>
                  !ordersWithLoads.contains(order.id) &&
                  JobWorkCollectionQuantityHelper.isPendingPickup(
                    order,
                    JobWorkCollectionQuantityHelper.collectionsForOrder(
                      order.id,
                      _jobWorkCollections,
                    ),
                  ),
            )
            .length;

    final partiallyCollectedOrdersCount = persistedLoads
            .where(
              (load) => load.status == JobWorkStatus.partiallyCollected,
            )
            .length +
        _orders
            .where((order) {
              if (ordersWithLoads.contains(order.id)) return false;
              if (order.status == JobWorkStatus.partiallyCollected) return true;
              final totals = JobWorkCollectionQuantityHelper.aggregateTotals(
                order: order,
                collections: _jobWorkCollections,
                loads: const [],
              );
              return totals.hasCollections && !totals.isFullyCollected;
            })
            .length;

    final stalePickupCount = persistedLoads
            .where(
              (load) => JobWorkCollectionQuantityHelper.isPickupOverdueForLoad(
                load,
                _jobWorkCollections,
                reference: today,
              ),
            )
            .length +
        _orders
            .where(
              (order) =>
                  !ordersWithLoads.contains(order.id) &&
                  JobWorkCollectionQuantityHelper.isPickupOverdue(
                    order,
                    JobWorkCollectionQuantityHelper.collectionsForOrder(
                      order.id,
                      _jobWorkCollections,
                    ),
                    reference: today,
                  ),
            )
            .length;

    final pendingPickups = <DashboardPendingPickup>[
      for (final load in persistedLoads)
        if (JobWorkCollectionQuantityHelper.canOpenCollectMaterialForLoad(
          load,
          _jobWorkCollections,
        ))
          DashboardPendingPickup(
            jobWorkId: load.jobWorkId,
            jobWorkNumber: load.jobWorkNumber,
            customerName: load.customerName,
            status: load.status,
            loadId: load.id,
            loadNumber: load.loadNumber,
            mineLocation: load.mineLocation,
            mineOwner: load.mineOwner,
          ),
      for (final order in _orders)
        if (!ordersWithLoads.contains(order.id) &&
            JobWorkCollectionQuantityHelper.isPendingPickup(
              order,
              JobWorkCollectionQuantityHelper.collectionsForOrder(
                order.id,
                _jobWorkCollections,
              ),
            ))
          DashboardPendingPickup(
            jobWorkId: order.id,
            jobWorkNumber: order.jobWorkNumber,
            customerName: order.customerName,
            status: order.status,
            mineLocation: order.mineLocation,
            mineOwner: order.mineOwner,
          ),
    ]..sort((a, b) {
        final rankCompare =
            a.status.listSortRank.compareTo(b.status.listSortRank);
        if (rankCompare != 0) return rankCompare;
        return a.jobWorkNumber.compareTo(b.jobWorkNumber);
      });

    final overdueSummary = _scannerService.summarizeAll(
      jobWorkInvoices: _jobWorkInvoices,
      salesInvoices: _salesInvoices,
    );

    final expensesToday = _expenses
        .where((expense) => _isSameDay(expense.expenseDate, today))
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    final expensesYesterday = _expenses
        .where((expense) => _isSameDay(expense.expenseDate, yesterday))
        .fold<double>(0, (sum, expense) => sum + expense.amount);

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

    final activeEmployees =
        _employees.where((employee) => employee.isActive).toList();
    final activeLabourCount = activeEmployees.length;
    final attendanceByEmployee = {
      for (final record in _attendanceToday) record.employeeId: record,
    };
    final presentLabourToday = activeEmployees
        .where(
          (employee) =>
              attendanceByEmployee[employee.id]?.status ==
              AttendanceStatus.present,
        )
        .length;
    final unmarkedAttendanceToday = activeEmployees
        .where((employee) => !attendanceByEmployee.containsKey(employee.id))
        .length;

    final activeDeliveriesCount =
        _deliveries.where((delivery) => delivery.status.isActive).length;
    final scheduledDeliveriesToday = _deliveries.where((delivery) {
      if (delivery.status != DeliveryStatus.scheduled) return false;
      final scheduled = delivery.scheduledDate;
      return scheduled.year == today.year &&
          scheduled.month == today.month &&
          scheduled.day == today.day;
    }).length;

    final partiallyDispatchedOrdersCount = agreementStatuses
        .where(
          (status) => status == SalesAgreementSummaryStatus.pendingDelivery,
        )
        .length;
    final readyForDispatchCount = agreementStatuses
        .where((status) => status == SalesAgreementSummaryStatus.idle)
        .length;
    final dispatchedTodayDeliveries = _deliveries.where((delivery) {
      if (!delivery.status.isTerminal) return false;
      final date = delivery.actualDeliveryDate ?? delivery.scheduledDate;
      return _isSameDay(date, today);
    });
    final dispatchedTodayPieces = dispatchedTodayDeliveries.fold<int>(
      0,
      (sum, delivery) => sum + delivery.effectivePieces,
    );
    final dispatchedTodaySquareFeet = dispatchedTodayDeliveries.fold<double>(
      0,
      (sum, delivery) => sum + delivery.effectiveSquareFeet,
    );
    final overdueDeliveriesCount = _deliveries
        .where((delivery) => delivery.isDispatchOverdue(reference: today))
        .length;

    final maintenanceOverdueCount = _equipment
        .where((item) => item.isMaintenanceOverdue(today: today))
        .length;
    final maintenanceDueSoonCount = _equipment
        .where(
          (item) =>
              !item.isMaintenanceOverdue(today: today) &&
              item.isMaintenanceDueSoon(today: today),
        )
        .length;

    final qcThisMonth = _qualityChecks.where((check) {
      final date = check.inspectionDate;
      return date.year == now.year && date.month == now.month;
    }).toList();
    final qcRejectsThisMonth = qcThisMonth
        .where((check) => check.disposition == QcDisposition.reject)
        .length;
    final jobWorkIdsWithQc = _qualityChecks
        .where((check) => check.referenceType == QcReferenceType.jobWork)
        .map((check) => check.referenceId)
        .toSet();
    final loadIdsWithQc = _qualityChecks
        .where((check) => check.referenceType == QcReferenceType.jobWorkLoad)
        .map((check) => check.referenceId)
        .toSet();
    final jobWorkPendingQcCount = JobWorkLoadProductionHelper.awaitingQcCount(
      orders: _orders,
      loads: _jobWorkLoads,
      loadIdsWithQc: loadIdsWithQc,
      jobWorkIdsWithQc: jobWorkIdsWithQc,
    );

    final analytics = _analyticsService.build(
      payments: _payments,
      productionBatches: _productionBatches,
      jobWorkOrders: _orders,
      jobWorkLoads: _jobWorkLoads,
      now: now,
    );

    final earliest = DashboardCommandCenterBuilder.findEarliestTransactionDate(
      payments: _payments,
      expenses: _expenses,
      jobWorkOrders: _orders,
      jobWorkLoads: _jobWorkLoads,
      jobWorkInvoices: _jobWorkInvoices,
      salesInvoices: _salesInvoices,
      salesOrders: _salesOrders,
      deliveries: _deliveries,
      jobWorkCollections: _jobWorkCollections,
    );

    final cashflow = _buildCashflowMetrics(
      period: state.financePeriod,
      now: now,
      earliestDate: earliest,
    );
    final stockCut = _buildStockCutMetrics(
      period: state.stockCutPeriod,
      now: now,
      earliestDate: earliest,
    );
    final salesSqFt = _buildSalesSqFtMetrics(
      period: state.salesSqFtPeriod,
      now: now,
      earliestDate: earliest,
    );
    final commandCenter = DashboardCommandCenterBuilder.build(
      period: state.financePeriod,
      now: now,
      payments: _payments,
      expenses: _expenses,
      jobWorkOrders: _orders,
      jobWorkLoads: _jobWorkLoads,
      jobWorkInvoices: _jobWorkInvoices,
      salesInvoices: _salesInvoices,
      salesOrders: _salesOrders,
      deliveries: _deliveries,
      activeJobWorks: activeJobWorkCount,
      jobWorkCollections: _jobWorkCollections,
      factoryCreatedAt: earliest,
    );

    emit(
      state.copyWith(
        status: DashboardStatus.loaded,
        cashflow: cashflow,
        financePeriod: state.financePeriod,
        stockCut: stockCut,
        stockCutPeriod: state.stockCutPeriod,
        salesSqFt: salesSqFt,
        salesSqFtPeriod: state.salesSqFtPeriod,
        commandCenter: commandCenter,
        kpis: DashboardKpis(
          revenueToday: revenueToday,
          activeJobWorkCount: activeJobWorkCount,
          activeLoadCount: activeLoadsAndLegacy,
          activeSalesCount: activeSalesCount,
          pendingPickupCount: pendingPickupCount,
          partiallyCollectedOrdersCount: partiallyCollectedOrdersCount,
          stalePickupCount: stalePickupCount,
          expensesThisMonth: expensesThisMonth,
          expenseCountThisMonth: expensesThisMonthList.length,
          lowStockCount: lowStockCount,
          overdueAmount: overdueSummary.overdueAmount,
          overdueCount: overdueSummary.overdueCount,
          customerCount: _customers.length,
          activeLabourCount: activeLabourCount,
          presentLabourToday: presentLabourToday,
          unmarkedAttendanceToday: unmarkedAttendanceToday,
          activeDeliveriesCount: activeDeliveriesCount,
          scheduledDeliveriesToday: scheduledDeliveriesToday,
          partiallyDispatchedOrdersCount: partiallyDispatchedOrdersCount,
          readyForDispatchCount: readyForDispatchCount,
          dispatchedTodayPieces: dispatchedTodayPieces,
          dispatchedTodaySquareFeet: dispatchedTodaySquareFeet,
          overdueDeliveriesCount: overdueDeliveriesCount,
          maintenanceOverdueCount: maintenanceOverdueCount,
          maintenanceDueSoonCount: maintenanceDueSoonCount,
          qcRejectsThisMonth: qcRejectsThisMonth,
          jobWorkPendingQcCount: jobWorkPendingQcCount,
          salesRevenueToday: salesRevenueToday,
          jobWorkRevenueToday: jobWorkRevenueToday,
          revenueYesterday: revenueYesterday,
          revenueThisMonth: revenueThisMonth,
          expensesToday: expensesToday,
          expensesYesterday: expensesYesterday,
          dueThisWeekCount: overdueSummary.dueThisWeekCount,
          dueThisWeekAmount: overdueSummary.dueThisWeekAmount,
          ownProductionTodaySqFt: ownProductionTodaySqFt,
          jobWorkOutputTodaySqFt: jobWorkOutputTodaySqFt,
          productionThisMonthSqFt: productionThisMonthSqFt,
        ),
        analytics: analytics,
        pendingPickups: pendingPickups.take(4).toList(),
        errorMessage: null,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DashboardCashflowMetrics _buildCashflowMetrics({
    required DashboardFinancePeriod period,
    required DateTime now,
    DateTime? earliestDate,
  }) {
    final range = DashboardFinancePeriodRange.forPeriod(
      period,
      now,
      earliestDate: earliestDate,
    );

    double sumPayments(DateTime start, DateTime end) {
      return _payments
          .where(
            (payment) => DashboardFinancePeriodRange.contains(
              payment.paymentDate,
              start,
              end,
            ),
          )
          .fold<double>(0, (sum, payment) => sum + payment.amount);
    }

    double sumExpenses(DateTime start, DateTime end) {
      return _expenses
          .where(
            (expense) => DashboardFinancePeriodRange.contains(
              expense.expenseDate,
              start,
              end,
            ),
          )
          .fold<double>(0, (sum, expense) => sum + expense.amount);
    }

    return DashboardCashflowMetrics(
      period: period,
      income: sumPayments(range.currentStart, range.currentEnd),
      expenses: sumExpenses(range.currentStart, range.currentEnd),
      previousIncome: sumPayments(range.previousStart, range.previousEnd),
      previousExpenses: sumExpenses(range.previousStart, range.previousEnd),
    );
  }

  DashboardStockCutMetrics _buildStockCutMetrics({
    required DashboardFinancePeriod period,
    required DateTime now,
    DateTime? earliestDate,
  }) {
    final range = DashboardFinancePeriodRange.forPeriod(
      period,
      now,
      earliestDate: earliestDate,
    );
    final current = DashboardJobWorkMetrics.factoryStockCutInRange(
      orders: _orders,
      loads: _jobWorkLoads,
      start: range.currentStart,
      end: range.currentEnd,
    );
    final previous = DashboardJobWorkMetrics.factoryStockCutInRange(
      orders: _orders,
      loads: _jobWorkLoads,
      start: range.previousStart,
      end: range.previousEnd,
    );
    return DashboardStockCutMetrics(
      period: period,
      smallSqFt: current.smallSqFt,
      largeSqFt: current.largeSqFt,
      previousSmallSqFt: previous.smallSqFt,
      previousLargeSqFt: previous.largeSqFt,
      smallAmount: current.smallAmount,
      largeAmount: current.largeAmount,
      previousSmallAmount: previous.smallAmount,
      previousLargeAmount: previous.largeAmount,
    );
  }

  DashboardSalesSqFtMetrics _buildSalesSqFtMetrics({
    required DashboardFinancePeriod period,
    required DateTime now,
    DateTime? earliestDate,
  }) {
    final range = DashboardFinancePeriodRange.forPeriod(
      period,
      now,
      earliestDate: earliestDate,
    );
    final current = DashboardSalesSqFtHelper.factorySalesSqFtInRange(
      orders: _salesOrders,
      start: range.currentStart,
      end: range.currentEnd,
    );
    final previous = DashboardSalesSqFtHelper.factorySalesSqFtInRange(
      orders: _salesOrders,
      start: range.previousStart,
      end: range.previousEnd,
    );
    return DashboardSalesSqFtMetrics(
      period: period,
      smallSqFt: current.smallSqFt,
      largeSqFt: current.largeSqFt,
      previousSmallSqFt: previous.smallSqFt,
      previousLargeSqFt: previous.largeSqFt,
      smallAmount: current.smallAmount,
      largeAmount: current.largeAmount,
      previousSmallAmount: previous.smallAmount,
      previousLargeAmount: previous.largeAmount,
    );
  }

  Future<void> _cancelSubscriptions() async {
    _snapshotGeneration++;
    await _paymentsSub?.cancel();
    await _jobWorkSub?.cancel();
    await _salesSub?.cancel();
    await _customersSub?.cancel();
    await _jobWorkInvoicesSub?.cancel();
    await _salesInvoicesSub?.cancel();
    _paymentsSub = null;
    _jobWorkSub = null;
    _salesSub = null;
    _customersSub = null;
    _jobWorkInvoicesSub = null;
    _salesInvoicesSub = null;
    _watchingFactoryId = null;
    _activeWindow = null;
  }

  @override
  Future<void> close() async {
    _recomputeDebounce?.cancel();
    await _cancelSubscriptions();
    return super.close();
  }
}

final class _DashboardDataUpdated extends DashboardEvent {
  const _DashboardDataUpdated();
}

final class _DashboardRecomputeRequested extends DashboardEvent {
  const _DashboardRecomputeRequested();
}
