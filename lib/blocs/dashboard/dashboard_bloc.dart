import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/date_keys.dart';
import '../../core/utils/dashboard_job_work_metrics.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../data/repositories/employee_repository.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/job_work_invoice_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/production_repository.dart';
import '../../data/repositories/quality_check_repository.dart';
import '../../data/repositories/raw_material_repository.dart';
import '../../data/repositories/sales_invoice_repository.dart';
import '../../data/repositories/sales_order_repository.dart';
import '../../data/services/dashboard_analytics_service.dart';
import '../../data/services/payment_due_scanner_service.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/labour_enums.dart';
import '../../domain/enums/quality_enums.dart';
import '../../domain/enums/delivery_enums.dart';
import '../../domain/enums/sales_enums.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/entities/dashboard_kpis.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/production_batch.dart';
import '../../domain/entities/quality_check.dart';
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
    required EmployeeRepository employeeRepository,
    required AttendanceRepository attendanceRepository,
    required DeliveryRepository deliveryRepository,
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
        _equipmentRepository = equipmentRepository,
        _qualityCheckRepository = qualityCheckRepository,
        _productionRepository = productionRepository,
        _scannerService = scannerService,
        _analyticsService = analyticsService,
        super(const DashboardState()) {
    on<DashboardWatchStarted>(_onWatchStarted);
    on<DashboardWatchStopped>(_onWatchStopped);
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
  StreamSubscription<List<Expense>>? _expensesSub;
  StreamSubscription<List<RawMaterial>>? _rawMaterialsSub;
  StreamSubscription<List<Employee>>? _employeesSub;
  StreamSubscription<List<AttendanceRecord>>? _attendanceSub;
  StreamSubscription<List<Delivery>>? _deliveriesSub;
  StreamSubscription<List<Equipment>>? _equipmentSub;
  StreamSubscription<List<QualityCheck>>? _qualityChecksSub;
  StreamSubscription<List<ProductionBatch>>? _productionBatchesSub;

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
  List<Equipment> _equipment = const [];
  List<QualityCheck> _qualityChecks = const [];
  List<ProductionBatch> _productionBatches = const [];

  Timer? _recomputeDebounce;

  void _handleStreamError(String streamName, void Function() reset) {
    if (kDebugMode) {
      debugPrint('Dashboard stream failed ($streamName); continuing with empty data.');
    }
    reset();
    add(const _DashboardDataUpdated());
  }

  Future<void> _onWatchStarted(
    DashboardWatchStarted event,
    Emitter<DashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        status: DashboardStatus.loading,
        factoryId: event.factoryId,
        errorMessage: null,
      ),
    );
    await _cancelSubscriptions();

    _paymentsSub = _paymentRepository
        .watchPaymentsForFactory(event.factoryId)
        .listen(
          (payments) {
            _payments = payments;
            add(const _DashboardDataUpdated());
          },
          onError: (_) => _handleStreamError('payments', () => _payments = const []),
        );

    _jobWorkSub = _jobWorkRepository
        .watchJobWorkOrders(event.factoryId)
        .listen(
          (orders) {
            _orders = orders;
            add(const _DashboardDataUpdated());
          },
          onError: (_) => _handleStreamError('jobWork', () => _orders = const []),
        );

    _salesSub = _salesOrderRepository
        .watchSalesOrders(event.factoryId)
        .listen(
          (orders) {
            _salesOrders = orders;
            add(const _DashboardDataUpdated());
          },
          onError: (_) => _handleStreamError('salesOrders', () => _salesOrders = const []),
        );

    _customersSub = _customerRepository
        .watchCustomers(event.factoryId)
        .listen(
          (customers) {
            _customers = customers;
            add(const _DashboardDataUpdated());
          },
          onError: (_) => _handleStreamError('customers', () => _customers = const []),
        );

    _jobWorkInvoicesSub = _jobWorkInvoiceRepository
        .watchOpenInvoicesForFactory(event.factoryId)
        .listen(
          (invoices) {
            _jobWorkInvoices = invoices;
            add(const _DashboardDataUpdated());
          },
          onError: (_) =>
              _handleStreamError('jobWorkInvoices', () => _jobWorkInvoices = const []),
        );

    _salesInvoicesSub = _salesInvoiceRepository
        .watchOpenInvoicesForFactory(event.factoryId)
        .listen(
          (invoices) {
            _salesInvoices = invoices;
            add(const _DashboardDataUpdated());
          },
          onError: (_) =>
              _handleStreamError('salesInvoices', () => _salesInvoices = const []),
        );

    _expensesSub = _expenseRepository
        .watchExpenses(event.factoryId)
        .listen(
          (expenses) {
            _expenses = expenses;
            add(const _DashboardDataUpdated());
          },
          onError: (_) => _handleStreamError('expenses', () => _expenses = const []),
        );

    _rawMaterialsSub = _rawMaterialRepository
        .watchMaterials(event.factoryId)
        .listen(
          (materials) {
            _rawMaterials = materials;
            add(const _DashboardDataUpdated());
          },
          onError: (_) =>
              _handleStreamError('rawMaterials', () => _rawMaterials = const []),
        );

    _employeesSub = _employeeRepository.watchEmployees(event.factoryId).listen(
          (employees) {
            _employees = employees;
            add(const _DashboardDataUpdated());
          },
          onError: (_) => _handleStreamError('employees', () => _employees = const []),
        );

    final today = DateKeys.dateOnly(DateTime.now());
    _attendanceSub = _attendanceRepository
        .watchForDate(factoryId: event.factoryId, date: today)
        .listen(
          (records) {
            _attendanceToday = records;
            add(const _DashboardDataUpdated());
          },
          onError: (_) =>
              _handleStreamError('attendance', () => _attendanceToday = const []),
        );

    _deliveriesSub = _deliveryRepository
        .watchDeliveries(event.factoryId)
        .listen(
          (deliveries) {
            _deliveries = deliveries;
            add(const _DashboardDataUpdated());
          },
          onError: (_) => _handleStreamError('deliveries', () => _deliveries = const []),
        );

    _equipmentSub = _equipmentRepository.watchEquipment(event.factoryId).listen(
          (equipment) {
            _equipment = equipment;
            add(const _DashboardDataUpdated());
          },
          onError: (_) => _handleStreamError('equipment', () => _equipment = const []),
        );

    _qualityChecksSub =
        _qualityCheckRepository.watchQualityChecks(event.factoryId).listen(
              (checks) {
                _qualityChecks = checks;
                add(const _DashboardDataUpdated());
              },
              onError: (_) =>
                  _handleStreamError('qualityChecks', () => _qualityChecks = const []),
            );

    _productionBatchesSub =
        _productionRepository.watchBatches(event.factoryId).listen(
              (batches) {
                _productionBatches = batches;
                add(const _DashboardDataUpdated());
              },
              onError: (_) => _handleStreamError(
                'productionBatches',
                () => _productionBatches = const [],
              ),
            );
  }

  Future<void> _onWatchStopped(
    DashboardWatchStopped event,
    Emitter<DashboardState> emit,
  ) async {
    _recomputeDebounce?.cancel();
    await _cancelSubscriptions();
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

    final revenueToday = _payments
        .where((payment) => _isSameDay(payment.paymentDate, today))
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
      (sum, order) => sum + DashboardJobWorkMetrics.sqFtOnDay(order, today),
    );

    final productionThisMonthSqFt = _productionBatches
        .where((batch) {
          final date = batch.productionDate;
          return date.year == now.year && date.month == now.month;
        })
        .fold<double>(0, (sum, batch) => sum + batch.totalUsableSqFt);

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

    final partiallyDispatchedOrdersCount = _salesOrders
        .where((order) => order.status == SalesOrderStatus.partiallyDispatched)
        .length;
    final readyForDispatchCount = _salesOrders
        .where((order) => order.status == SalesOrderStatus.ready)
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
    final jobWorkPendingQcCount = _orders
        .where(
          (order) =>
              order.status == JobWorkStatus.qc &&
              !jobWorkIdsWithQc.contains(order.id),
        )
        .length;

    final analytics = _analyticsService.build(
      payments: _payments,
      productionBatches: _productionBatches,
      jobWorkOrders: _orders,
      now: now,
    );

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
          revenueThisMonth: revenueThisMonth,
          dueThisWeekCount: overdueSummary.dueThisWeekCount,
          dueThisWeekAmount: overdueSummary.dueThisWeekAmount,
          ownProductionTodaySqFt: ownProductionTodaySqFt,
          jobWorkOutputTodaySqFt: jobWorkOutputTodaySqFt,
          productionThisMonthSqFt: productionThisMonthSqFt,
        ),
        analytics: analytics,
        pendingPickups: pendingPickups.take(5).toList(),
        errorMessage: null,
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
    await _employeesSub?.cancel();
    await _attendanceSub?.cancel();
    await _deliveriesSub?.cancel();
    await _equipmentSub?.cancel();
    await _qualityChecksSub?.cancel();
    await _productionBatchesSub?.cancel();
    _paymentsSub = null;
    _jobWorkSub = null;
    _salesSub = null;
    _customersSub = null;
    _jobWorkInvoicesSub = null;
    _salesInvoicesSub = null;
    _expensesSub = null;
    _rawMaterialsSub = null;
    _employeesSub = null;
    _attendanceSub = null;
    _deliveriesSub = null;
    _equipmentSub = null;
    _qualityChecksSub = null;
    _productionBatchesSub = null;
  }

  @override
  Future<void> close() {
    _recomputeDebounce?.cancel();
    _cancelSubscriptions();
    return super.close();
  }
}

final class _DashboardDataUpdated extends DashboardEvent {
  const _DashboardDataUpdated();
}

final class _DashboardRecomputeRequested extends DashboardEvent {
  const _DashboardRecomputeRequested();
}
