import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:factory_management/blocs/dashboard/dashboard_bloc.dart';
import 'package:factory_management/core/utils/dashboard_query_window.dart';
import 'package:factory_management/data/repositories/attendance_repository.dart';
import 'package:factory_management/data/repositories/customer_repository.dart';
import 'package:factory_management/data/repositories/delivery_repository.dart';
import 'package:factory_management/data/repositories/employee_repository.dart';
import 'package:factory_management/data/repositories/equipment_repository.dart';
import 'package:factory_management/data/repositories/expense_repository.dart';
import 'package:factory_management/data/repositories/job_work_collection_repository.dart';
import 'package:factory_management/data/repositories/job_work_invoice_repository.dart';
import 'package:factory_management/data/repositories/job_work_load_repository.dart';
import 'package:factory_management/data/repositories/job_work_repository.dart';
import 'package:factory_management/data/repositories/notification_repository.dart';
import 'package:factory_management/data/repositories/payment_repository.dart';
import 'package:factory_management/data/repositories/production_repository.dart';
import 'package:factory_management/data/repositories/quality_check_repository.dart';
import 'package:factory_management/data/repositories/raw_material_repository.dart';
import 'package:factory_management/data/repositories/sales_invoice_repository.dart';
import 'package:factory_management/data/repositories/sales_order_repository.dart';
import 'package:factory_management/data/services/dashboard_analytics_service.dart';
import 'package:factory_management/data/services/payment_due_scanner_service.dart';
import 'package:factory_management/domain/entities/expense.dart';
import 'package:factory_management/domain/entities/payment.dart';
import 'package:factory_management/domain/enums/dashboard_finance_period.dart';
import 'package:flutter_test/flutter_test.dart';

const _factoryId = 'factory-s39';

class RecordingPaymentRepository extends PaymentRepository {
  RecordingPaymentRepository({
    required super.firestore,
    required super.jobWorkInvoiceRepository,
    required super.salesInvoiceRepository,
    required super.jobWorkRepository,
    required super.jobWorkLoadRepository,
    required super.salesOrderRepository,
  });

  int watchCalls = 0;
  final froms = <DateTime?>[];
  int? lastLimit;
  bool failWindowed = false;

  @override
  Stream<List<Payment>> watchPaymentsForFactory(
    String factoryId, {
    DateTime? from,
    int? limit,
  }) {
    watchCalls++;
    froms.add(from);
    lastLimit = limit;
    if (failWindowed && from != null) {
      return Stream.error(
        Exception('failed-precondition: requires an index'),
      );
    }
    return super.watchPaymentsForFactory(
      factoryId,
      from: from,
      limit: limit,
    );
  }
}

class RecordingExpenseRepository extends ExpenseRepository {
  RecordingExpenseRepository({required super.firestore});

  int getCalls = 0;
  DateTime? lastFrom;
  bool throwOnWindow = false;

  @override
  Future<List<Expense>> getExpenses(
    String factoryId, {
    DateTime? from,
    int? limit,
  }) {
    getCalls++;
    lastFrom = from;
    if (throwOnWindow && from != null) {
      throw Exception('failed-precondition: requires an index');
    }
    return super.getExpenses(factoryId, from: from, limit: limit);
  }
}

Future<void> _waitUntilLoaded(DashboardBloc bloc) {
  if (bloc.state.status == DashboardStatus.loaded) {
    return Future<void>.value();
  }
  return bloc.stream
      .firstWhere((state) => state.status == DashboardStatus.loaded)
      .timeout(const Duration(seconds: 5));
}

void main() {
  group('windowed repository queries', () {
    test('payments filter on the stored `date` field, not in memory', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('payments').doc('old').set({
        'factoryId': _factoryId,
        'customerId': 'c1',
        'customerName': 'Old',
        'invoiceId': 'inv-old',
        'invoiceType': 'sales',
        'invoiceNumber': 'INV-OLD',
        'amount': 100,
        'method': 'cash',
        'date': Timestamp.fromDate(DateTime(2024, 1, 15)),
        'status': 'completed',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 15)),
      });
      await firestore.collection('payments').doc('recent').set({
        'factoryId': _factoryId,
        'customerId': 'c1',
        'customerName': 'Recent',
        'invoiceId': 'inv-new',
        'invoiceType': 'sales',
        'invoiceNumber': 'INV-NEW',
        'amount': 250,
        'method': 'cash',
        'date': Timestamp.fromDate(DateTime(2026, 8, 10)),
        'status': 'completed',
        'createdAt': Timestamp.fromDate(DateTime(2026, 8, 10)),
      });

      final env = _DashboardTestEnv(firestore);
      final payments = await env.payments
          .watchPaymentsForFactory(
            _factoryId,
            from: DateTime(2026, 7, 1),
            limit: DashboardQueryWindow.windowedLimit,
          )
          .first;

      expect(payments.map((payment) => payment.id), ['recent']);
    });

    test('expenses get() applies the date window in Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('expenses').doc('old').set({
        'factoryId': _factoryId,
        'expenseNumber': 'EXP-OLD',
        'expenseDate': Timestamp.fromDate(DateTime(2024, 2, 1)),
        'category': 'electricity',
        'description': 'old bill',
        'amount': 10,
        'paymentMethod': 'cash',
        'createdAt': Timestamp.fromDate(DateTime(2024, 2, 1)),
      });
      await firestore.collection('expenses').doc('recent').set({
        'factoryId': _factoryId,
        'expenseNumber': 'EXP-NEW',
        'expenseDate': Timestamp.fromDate(DateTime(2026, 8, 5)),
        'category': 'electricity',
        'description': 'new bill',
        'amount': 20,
        'paymentMethod': 'cash',
        'createdAt': Timestamp.fromDate(DateTime(2026, 8, 5)),
      });

      final expenses = await ExpenseRepository(firestore: firestore).getExpenses(
        _factoryId,
        from: DateTime(2026, 7, 1),
        limit: DashboardQueryWindow.windowedLimit,
      );

      expect(expenses.map((expense) => expense.id), ['recent']);
    });
  });

  group('DashboardBloc windowing', () {
    late _DashboardTestEnv env;
    late DashboardBloc bloc;

    setUp(() {
      env = _DashboardTestEnv(FakeFirebaseFirestore());
      bloc = env.buildBloc();
    });

    tearDown(() async {
      await bloc.close();
    });

    test('second WatchStarted reuses live payment listeners', () async {
      bloc.add(const DashboardWatchStarted(_factoryId));
      await _waitUntilLoaded(bloc);

      expect(env.payments.watchCalls, 1);
      expect(env.payments.froms.single, isNotNull);
      expect(env.payments.lastLimit, DashboardQueryWindow.windowedLimit);
      final snapshotGetsAfterFirst = env.expenses.getCalls;

      bloc.add(const DashboardWatchStarted(_factoryId));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(env.payments.watchCalls, 1);
      expect(
        env.expenses.getCalls,
        greaterThan(snapshotGetsAfterFirst),
        reason: 'pull-to-refresh reloads snapshots without tearing down live streams',
      );
    });

    test('switching Daily to Yearly resubscribes payments with an earlier from',
        () async {
      bloc.add(const DashboardWatchStarted(_factoryId));
      await _waitUntilLoaded(bloc);

      final dailyFrom = env.payments.froms.single!;
      expect(env.payments.watchCalls, 1);

      bloc.add(
        const DashboardFinancePeriodChanged(DashboardFinancePeriod.yearly),
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(env.payments.watchCalls, 2);
      expect(env.payments.froms.last, isNotNull);
      expect(env.payments.froms.last!.isBefore(dailyFrom), isTrue);
    });

    test('switching Daily to Monthly changes the payment query window',
        () async {
      bloc.add(const DashboardWatchStarted(_factoryId));
      await _waitUntilLoaded(bloc);

      final dailyFrom = env.payments.froms.single!;

      bloc.add(
        const DashboardFinancePeriodChanged(DashboardFinancePeriod.monthly),
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(env.payments.watchCalls, 2);
      expect(env.payments.froms.last, isNotNull);
      expect(env.payments.froms.last, isNot(dailyFrom));
    });

    test('missing payment date index falls back instead of emptying the dashboard',
        () async {
      final today = DateTime.now();
      await env.firestore.collection('payments').doc('today').set({
        'factoryId': _factoryId,
        'customerId': 'c1',
        'customerName': 'Today',
        'invoiceId': 'inv-today',
        'invoiceType': 'sales',
        'invoiceNumber': 'INV-TODAY',
        'amount': 500,
        'method': 'cash',
        'date': Timestamp.fromDate(today),
        'status': 'completed',
        'createdAt': Timestamp.fromDate(today),
      });
      env.payments.failWindowed = true;

      bloc.add(const DashboardWatchStarted(_factoryId));
      await _waitUntilLoaded(bloc);
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(env.payments.froms, contains(null));
      expect(env.payments.watchCalls, greaterThanOrEqualTo(2));
      expect(bloc.state.kpis.revenueToday, 500);
    });

    test('missing expense date index still loads expenses via fallback',
        () async {
      final today = DateTime.now();
      await env.firestore.collection('expenses').doc('today').set({
        'factoryId': _factoryId,
        'expenseNumber': 'EXP-TODAY',
        'expenseDate': Timestamp.fromDate(today),
        'category': 'electricity',
        'description': 'today bill',
        'amount': 80,
        'paymentMethod': 'cash',
        'createdAt': Timestamp.fromDate(today),
      });
      env.expenses.throwOnWindow = true;

      bloc.add(const DashboardWatchStarted(_factoryId));
      await _waitUntilLoaded(bloc);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(env.expenses.getCalls, greaterThanOrEqualTo(2));
      expect(env.expenses.lastFrom, isNull);
      expect(bloc.state.kpis.expensesToday, 80);
    });
  });
}

class _DashboardTestEnv {
  _DashboardTestEnv(this.firestore)
      : jobWork = JobWorkRepository(firestore: firestore),
        salesOrders = SalesOrderRepository(firestore: firestore) {
    loads = JobWorkLoadRepository(
      firestore: firestore,
      jobWorkRepository: jobWork,
    );
    jobWorkInvoices = JobWorkInvoiceRepository(
      firestore: firestore,
      jobWorkRepository: jobWork,
      loadRepository: loads,
    );
    salesInvoices = SalesInvoiceRepository(
      firestore: firestore,
      salesOrderRepository: salesOrders,
    );
    payments = RecordingPaymentRepository(
      firestore: firestore,
      jobWorkInvoiceRepository: jobWorkInvoices,
      salesInvoiceRepository: salesInvoices,
      jobWorkRepository: jobWork,
      jobWorkLoadRepository: loads,
      salesOrderRepository: salesOrders,
    );
    expenses = RecordingExpenseRepository(firestore: firestore);
    production = ProductionRepository(firestore: firestore);
  }

  final FakeFirebaseFirestore firestore;
  final JobWorkRepository jobWork;
  final SalesOrderRepository salesOrders;
  late final JobWorkLoadRepository loads;
  late final JobWorkInvoiceRepository jobWorkInvoices;
  late final SalesInvoiceRepository salesInvoices;
  late final RecordingPaymentRepository payments;
  late final RecordingExpenseRepository expenses;
  late final ProductionRepository production;

  DashboardBloc buildBloc() {
    return DashboardBloc(
      paymentRepository: payments,
      jobWorkRepository: jobWork,
      salesOrderRepository: salesOrders,
      customerRepository: CustomerRepository(firestore: firestore),
      jobWorkInvoiceRepository: jobWorkInvoices,
      salesInvoiceRepository: salesInvoices,
      expenseRepository: expenses,
      rawMaterialRepository: RawMaterialRepository(firestore: firestore),
      employeeRepository: EmployeeRepository(firestore: firestore),
      attendanceRepository: AttendanceRepository(firestore: firestore),
      deliveryRepository: DeliveryRepository(
        firestore: firestore,
        salesOrderRepository: salesOrders,
      ),
      jobWorkCollectionRepository: JobWorkCollectionRepository(
        firestore: firestore,
        jobWorkRepository: jobWork,
        loadRepository: loads,
      ),
      jobWorkLoadRepository: loads,
      qualityCheckRepository: QualityCheckRepository(
        firestore: firestore,
        productionRepository: production,
        jobWorkRepository: jobWork,
      ),
      productionRepository: production,
      equipmentRepository: EquipmentRepository(firestore: firestore),
      scannerService: PaymentDueScannerService(
        jobWorkInvoiceRepository: jobWorkInvoices,
        salesInvoiceRepository: salesInvoices,
        notificationRepository: NotificationRepository(firestore: firestore),
      ),
      analyticsService: DashboardAnalyticsService(),
    );
  }
}
